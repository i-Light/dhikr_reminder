#Requires -Version 5.1
<#
.SYNOPSIS
    Builds the Dhikr Reminder installer, and optionally publishes it.

.DESCRIPTION
    Always: `flutter build windows --release`, then scripts\installer.iss is
    compiled with Inno Setup 7 into  dist\dhikr_reminder-<version>-setup.exe.
    That one file is the whole deliverable -- there is no portable .zip.

    -Mode Local (the default)
        Only builds. The version in pubspec.yaml is used as it is, nothing is
        committed, tagged or pushed.

    -Mode Publish
        Cuts a release: analyze + test, bump the version in pubspec.yaml,
        build, commit "Release vX.Y.Z", tag it, push the branch and the tag,
        then create a GitHub Release with the installer attached. The apps
        already installed find it on their own (lib\core\update\).
        Needs a clean working tree, and a GitHub token: $env:GH_TOKEN /
        $env:GITHUB_TOKEN, or else the one Git Credential Manager already holds
        for github.com.

    -InstallHere
        Also installs the freshly built version on this PC, silently, over the
        copy that is there, and starts it again. Works with either mode.

    Inno Setup 7 is required (https://jrsoftware.org/isdl.php).

.PARAMETER Mode
    Local or Publish, as above.

.PARAMETER InstallHere
    Install the built installer on this PC afterwards.

.PARAMETER Bump
    Publish only: which part of major.minor.patch to raise. The build number
    after the + is always raised by one.

.PARAMETER SkipChecks
    Publish only: do not run flutter analyze / flutter test first.

.PARAMETER DryRun
    Publish only: run the preflight checks and say what would be done, without
    changing anything.

.PARAMETER ConfirmTag
    Publish only: the tag to be released (for example v0.1.4), typed ahead of
    time so the script does not ask. Without it the script shows the release
    plan and waits for the tag to be typed. A release goes to every installed
    copy, so it is never one key press away.

.PARAMETER SkipAndroid
    Do not build the Android APKs. By default both modes also build them (one per
    CPU, next to the installer in the output folder) with scripts\build_android.ps1.

.PARAMETER OutDir
    Where the setup .exe lands. Defaults to .\dist.

.PARAMETER SkipPubGet
    Reuse the current .dart_tool package config instead of resolving again.

.EXAMPLE
    .\scripts\build_windows.ps1
    .\scripts\build_windows.ps1 -InstallHere
    .\scripts\build_windows.ps1 -Mode Publish
    .\scripts\build_windows.ps1 -Mode Publish -Bump minor -InstallHere
#>
[CmdletBinding()]
param(
    [ValidateSet('Local', 'Publish')]
    [string] $Mode = 'Local',

    [switch] $InstallHere,

    [switch] $SkipAndroid,

    [ValidateSet('patch', 'minor', 'major')]
    [string] $Bump = 'patch',

    [switch] $SkipChecks,

    [switch] $DryRun,

    [string] $ConfirmTag,

    [string] $OutDir,

    [switch] $SkipPubGet
)

$ErrorActionPreference = 'Stop'
# Progress bars are write-heavy and make CI logs unreadable.
$ProgressPreference = 'SilentlyContinue'
# Windows PowerShell 5.1 does not offer TLS 1.2 by default; api.github.com
# requires it.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$RepoRoot = Split-Path -Parent $PSScriptRoot
$PubspecPath = Join-Path $RepoRoot 'pubspec.yaml'
if (-not $OutDir) { $OutDir = Join-Path $RepoRoot 'dist' }

# The switches Inno Setup needs to run without a single window or prompt. The
# in-app updater passes the same set (setupSilentArguments in
# lib\core\update\update_installer.dart).
$SilentSetupArgs = @(
    '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART',
    '/CLOSEAPPLICATIONS', '/FORCECLOSEAPPLICATIONS', '/CURRENTUSER'
)

function Read-Pubspec {
    $text = Get-Content -LiteralPath $PubspecPath -Raw
    $name = [regex]::Match($text, '(?m)^name:\s*(\S+)\s*$').Groups[1].Value
    $line = [regex]::Match($text, '(?m)^version:\s*(\S+)').Groups[1].Value
    if (-not $name -or -not $line) { throw 'Could not read name/version from pubspec.yaml.' }
    $parts = $line -split '\+'
    [pscustomobject]@{
        Text   = $text
        Name   = $name
        Semver = $parts[0]
        Build  = if ($parts.Count -gt 1) { [int]$parts[1] } else { 0 }
    }
}

function Invoke-Native {
    # Runs an external command and throws if it fails. Windows PowerShell does
    # not do that on its own for anything that is not a cmdlet.
    param([string] $Description, [scriptblock] $Command)
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$Description failed (exit $LASTEXITCODE)" }
}

function Test-Git {
    # A git command whose failure is an answer, not an error: Windows
    # PowerShell 5.1 turns anything a native command writes to stderr into a
    # terminating error under $ErrorActionPreference = 'Stop'.
    param([string[]] $GitArgs)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = & git -C $RepoRoot @GitArgs 2>$null
        [pscustomobject]@{ Ok = ($LASTEXITCODE -eq 0); Out = $out }
    }
    finally { $ErrorActionPreference = $previous }
}

function Find-Iscc {
    # Inno Setup 7 only. Its ISCC.exe carries no version resource, so the
    # banner it prints is what says which Inno Setup a path belongs to.
    $candidates = @(
        "$env:ProgramFiles\Inno Setup 7\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 7\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 7\ISCC.exe"
    )
    $onPath = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if ($onPath) { $candidates += $onPath.Source }
    foreach ($candidate in $candidates) {
        if (-not (Test-Path -LiteralPath $candidate)) { continue }
        $banner = (& $candidate '/?' 2>&1 | Select-Object -First 1) -join ''
        if ($banner -match 'Inno Setup 7') { return $candidate }
    }
    throw 'Inno Setup 7 is not installed. Get it from https://jrsoftware.org/isdl.php'
}

function Get-GitHubRepo {
    $remote = (git -C $RepoRoot remote get-url origin).Trim()
    $m = [regex]::Match($remote, 'github\.com[:/]([^/]+)/([^/]+?)(\.git)?$')
    if (-not $m.Success) { throw "origin ($remote) is not a GitHub repository." }
    [pscustomobject]@{ Owner = $m.Groups[1].Value; Name = $m.Groups[2].Value }
}

function Get-GitHubToken {
    foreach ($name in 'GH_TOKEN', 'GITHUB_TOKEN') {
        $value = [Environment]::GetEnvironmentVariable($name)
        if ($value) { return $value }
    }
    # Whatever Git itself pushes with (Git Credential Manager, GitHub Desktop's
    # sign-in): no separate token to create for the common case.
    #
    # The request goes in through a file and cmd.exe's `<`, not a PowerShell
    # pipe: from a VS Code task (no console) Windows PowerShell 5.1 does not
    # hand the piped text to git intact, and `git credential fill` answers
    # "credential missing protocol field" with nothing on stdout.
    $requestFile = [IO.Path]::GetTempFileName()
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        [IO.File]::WriteAllBytes($requestFile, [Text.Encoding]::ASCII.GetBytes("protocol=https`nhost=github.com`n`n"))
        $reply = cmd.exe /c "git credential fill < `"$requestFile`" 2>nul"
    }
    finally {
        $ErrorActionPreference = $previous
        Remove-Item -LiteralPath $requestFile -Force -ErrorAction SilentlyContinue
    }
    foreach ($line in $reply) {
        if ($line -like 'password=*') { return $line.Substring('password='.Length) }
    }
    throw @'
No GitHub token found. Either sign in to GitHub in Git (Git Credential Manager),
or set GH_TOKEN to a token that may write releases -- a fine-grained personal
access token with "Contents: Read and write" on this repository is enough.
'@
}

function Invoke-GitHub {
    param([string] $Method, [string] $Uri, [string] $Token, $Body, [string] $InFile)
    $headers = @{
        Authorization          = "Bearer $Token"
        Accept                 = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
        'User-Agent'           = 'dhikr_reminder-release-script'
    }
    $request = @{ Method = $Method; Uri = $Uri; Headers = $headers; TimeoutSec = 900 }
    if ($InFile) {
        $request.InFile = $InFile
        $request.ContentType = 'application/octet-stream'
    }
    elseif ($null -ne $Body) {
        $request.Body = ($Body | ConvertTo-Json -Depth 5)
        $request.ContentType = 'application/json'
    }
    try { Invoke-RestMethod @request }
    catch {
        $detail = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $_.Exception.Message }
        throw "GitHub $Method $Uri failed: $detail"
    }
}

function Install-Here {
    param([string] $Setup)
    Write-Host 'Installing on this PC...' -ForegroundColor Cyan

    # Update the copy that is running, in the folder it runs from, if it was
    # installed by Setup; a flutter-run build has no unins000.exe and is left
    # alone.
    $appExe = $null
    $setupArgs = @($SilentSetupArgs)
    $running = Get-Process -Name 'dhikr_reminder' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path } | Select-Object -First 1
    if ($running) {
        $dir = Split-Path -Parent $running.Path
        if (Test-Path -LiteralPath (Join-Path $dir 'unins000.exe')) {
            $appExe = $running.Path
            $setupArgs += "/DIR=`"$dir`""
        }
    }
    if (-not $appExe) {
        $appExe = Join-Path $env:LOCALAPPDATA 'Programs\Dhikr Reminder\dhikr_reminder.exe'
    }

    $proc = Start-Process -FilePath $Setup -ArgumentList $setupArgs -Wait -PassThru
    if ($proc.ExitCode -ne 0) { throw "The installer exited with $($proc.ExitCode)." }

    if (Test-Path -LiteralPath $appExe) {
        Start-Process -FilePath $appExe
        Write-Host "Installed and started: $appExe" -ForegroundColor Green
    }
    else {
        Write-Host "Installed, but $appExe was not found to start." -ForegroundColor Yellow
    }
}

# =============================================================================
$pub = Read-Pubspec
$name = $pub.Name
$version = $pub.Semver
$publish = $Mode -eq 'Publish'

$iscc = Find-Iscc

# --- Publish preflight: everything that can be checked before touching files --
if ($publish) {
    $status = git -C $RepoRoot status --porcelain
    if ($status) {
        throw "The working tree has uncommitted changes. Commit or stash them first: a release commit must hold only the version bump.`n$($status -join "`n")"
    }
    $branch = (git -C $RepoRoot rev-parse --abbrev-ref HEAD).Trim()
    if ($branch -eq 'HEAD') { throw 'HEAD is detached; check out a branch to release from.' }

    Invoke-Native 'git fetch' { git -C $RepoRoot fetch origin --tags --quiet }
    $upstream = Test-Git @('rev-parse', '--abbrev-ref', '@{u}')
    if ($upstream.Ok) {
        $behind = [int](git -C $RepoRoot rev-list --count 'HEAD..@{u}')
        if ($behind -gt 0) { throw "$branch is $behind commit(s) behind $($upstream.Out). Pull first." }
    }

    $repo = Get-GitHubRepo
    $token = Get-GitHubToken
    $apiRepo = "https://api.github.com/repos/$($repo.Owner)/$($repo.Name)"
    $info = Invoke-GitHub 'GET' $apiRepo $token
    if ($info.permissions -and -not $info.permissions.push) {
        throw "The GitHub token cannot write to $($repo.Owner)/$($repo.Name)."
    }

    $parts = $version -split '\.'
    $major = [int]$parts[0]; $minor = [int]$parts[1]; $patch = [int]$parts[2]
    switch ($Bump) {
        'major' { $major++; $minor = 0; $patch = 0 }
        'minor' { $minor++; $patch = 0 }
        'patch' { $patch++ }
    }
    $newVersion = "$major.$minor.$patch"
    $newBuild = $pub.Build + 1
    $tag = "v$newVersion"

    if ((Test-Git @('rev-parse', '-q', '--verify', "refs/tags/$tag")).Ok) {
        throw "Tag $tag already exists."
    }

    Write-Host "Release plan: $version+$($pub.Build)  ->  $newVersion+$newBuild  ($tag on $branch)" -ForegroundColor Cyan
    Write-Host "  repository: $($repo.Owner)/$($repo.Name)   inno: $iscc"
    if ($DryRun) {
        Write-Host 'Dry run: nothing was changed.' -ForegroundColor Yellow
        return
    }

    # Everyone with the app installed gets this release. Typing the tag back is
    # the pause that stops a stray key press from doing that.
    $typed = $ConfirmTag
    if (-not $typed) {
        $typed = Read-Host "This publishes $tag to every installed copy. Type $tag to continue"
    }
    if ($typed.Trim() -ne $tag) {
        throw "Not published: expected '$tag' but got '$typed'."
    }
}
elseif ($DryRun) {
    Write-Host '-DryRun only applies to -Mode Publish.' -ForegroundColor Yellow
}

Push-Location $RepoRoot
$pubspecRewritten = $false
try {
    if (-not $SkipPubGet) {
        Invoke-Native 'flutter pub get' { flutter pub get }
    }

    if ($publish -and -not $SkipChecks) {
        Write-Host 'Running analyze + tests before releasing...' -ForegroundColor Cyan
        Invoke-Native 'flutter analyze' { flutter analyze --fatal-infos }
        Invoke-Native 'flutter test' { flutter test --no-pub }
    }

    if ($publish) {
        $rewritten = [regex]::Replace(
            $pub.Text, '(?m)^version:\s*\S+',
            "version: $newVersion+$newBuild", 1)
        [IO.File]::WriteAllText($PubspecPath, $rewritten, (New-Object Text.UTF8Encoding($false)))
        $pubspecRewritten = $true
        $version = $newVersion
    }

    # The .exe's icon is drawn from assets/images/logo.svg, the app's one
    # icon; the generated .ico is git-ignored, so it is made fresh every build.
    Write-Host 'Generating the app icon from assets/images/logo.svg' -ForegroundColor Cyan
    Invoke-Native 'generate app icon' { flutter test --no-pub tool/generate_app_icon.dart }

    Write-Host "Building $name v$version (Release) for Windows x64" -ForegroundColor Cyan

    # `flutter run` (debug) leaves a ~70 MB kernel_blob.bin in build\flutter_assets,
    # and the release build copies that whole folder into the bundle -- so the
    # "release" installer silently ships the debug-mode Dart code next to the
    # real AOT app.so. Clear it out so only release assets get bundled.
    $staleAssets = Join-Path $RepoRoot 'build\flutter_assets'
    if (Test-Path -LiteralPath $staleAssets) { Remove-Item -LiteralPath $staleAssets -Recurse -Force }

    # The dhikr request service (server/README.md) is found at the address
    # committed in lib/features/requests/data/requests_config.dart. Setting
    # DHIKR_REQUESTS_URL overrides it.
    $defines = @()
    if ($env:DHIKR_REQUESTS_URL) { $defines += "--dart-define=DHIKR_REQUESTS_URL=$($env:DHIKR_REQUESTS_URL)" }

    # --split-debug-info moves the symbol tables out of app.so (it is not
    # obfuscated, only smaller); the symbols are kept in build\symbols.
    Invoke-Native 'flutter build windows' { flutter build windows --release --split-debug-info=build/symbols @defines }

    # Flutter has moved this folder around across releases, so search for the
    # .exe under the Release folder instead of hardcoding one layout.
    $exe = Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'build\windows') -Recurse -Filter "$name.exe" |
        Where-Object { $_.FullName -match '[\\/]Release[\\/]' } |
        Select-Object -First 1
    if (-not $exe) {
        throw "flutter reported success but no $name.exe was found under build\windows\Release."
    }
    $builtRoot = $exe.DirectoryName
    # The .exe is nothing without data\ (flutter_assets, icudtl.dat).
    if (-not (Test-Path (Join-Path $builtRoot 'data\flutter_assets'))) {
        throw 'Built folder is missing data\flutter_assets - refusing to ship an .exe that cannot start.'
    }
    # A release bundle runs from data\app.so; a kernel_blob.bin next to it is
    # debug-mode leftovers (~70 MB of dead weight).
    if (Test-Path (Join-Path $builtRoot 'data\flutter_assets\kernel_blob.bin')) {
        throw 'Built folder contains kernel_blob.bin (debug leftovers) - refusing to package a bloated installer.'
    }

    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    $setupExe = Join-Path $OutDir "$name-$version-setup.exe"
    if (Test-Path -LiteralPath $setupExe) { Remove-Item -LiteralPath $setupExe -Force }
    Invoke-Native 'ISCC' {
        & $iscc "/DAppVersion=$version" "/DSourceDir=$builtRoot" "/DOutputDir=$OutDir" (Join-Path $PSScriptRoot 'installer.iss')
    }
    if (-not (Test-Path -LiteralPath $setupExe)) {
        throw "ISCC reported success but $setupExe is not there."
    }

    $mb = [math]::Round((Get-Item -LiteralPath $setupExe).Length / 1MB, 1)
    Write-Host ''
    Write-Host ('Installer: {0}  ({1} MB)' -f $setupExe, $mb) -ForegroundColor Green

    # The Android APKs, rebuilt every time next to the installer. Done before
    # anything is committed or published, and a machine without the Android SDK
    # only gets a warning: the Windows installer above is already complete.
    if (-not $SkipAndroid) {
        Write-Host ''
        Write-Host "Building the Android APKs v$version" -ForegroundColor Cyan
        try {
            & (Join-Path $PSScriptRoot 'build_android.ps1') -ApkOnly -SkipChecks -SkipIcons -OutDir $OutDir -Version $version
        }
        catch {
            Write-Warning "The Android APKs were not built: $($_.Exception.Message)"
        }
    }

    if ($InstallHere) { Install-Here -Setup $setupExe }

    if ($publish) {
        $tag = "v$version"
        Invoke-Native 'git add' { git add pubspec.yaml }
        Invoke-Native 'git commit' { git commit -m "Release $tag" --quiet }
        $pubspecRewritten = $false # It is committed now; do not undo it below.
        Invoke-Native 'git tag' { git tag -a $tag -m "Release $tag" }
        Invoke-Native 'git push (branch)' { git push origin $branch }
        Invoke-Native 'git push (tag)' { git push origin $tag }

        Write-Host "Publishing GitHub Release $tag..." -ForegroundColor Cyan
        try {
            # A draft until the installer is attached, so nobody's updater can
            # find a release with nothing to download.
            $release = Invoke-GitHub 'POST' "$apiRepo/releases" $token @{
                tag_name = $tag; name = $tag; draft = $true; generate_release_notes = $true
            }
            $assetName = Split-Path -Leaf $setupExe
            $uploadUri = "https://uploads.github.com/repos/$($repo.Owner)/$($repo.Name)/releases/$($release.id)/assets?name=$assetName"
            Invoke-GitHub 'POST' $uploadUri $token -InFile $setupExe | Out-Null
            $release = Invoke-GitHub 'PATCH' "$apiRepo/releases/$($release.id)" $token @{ draft = $false }
        }
        catch {
            Write-Host ''
            Write-Host "The commit and tag $tag are pushed, but the GitHub Release is not finished:" -ForegroundColor Yellow
            Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "Finish it by hand at https://github.com/$($repo.Owner)/$($repo.Name)/releases (attach $setupExe to $tag), or delete the tag and try again." -ForegroundColor Yellow
            throw
        }
        Write-Host "Published: $($release.html_url)" -ForegroundColor Green
    }
}
catch {
    if ($pubspecRewritten) {
        # Nothing was committed, so put the version back rather than leave a
        # bump behind for a release that did not happen.
        git -C $RepoRoot checkout -- pubspec.yaml
        Write-Host 'pubspec.yaml restored to its previous version.' -ForegroundColor Yellow
    }
    throw
}
finally {
    Pop-Location
}
