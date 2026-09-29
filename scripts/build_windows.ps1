#Requires -Version 5.1
<#
.SYNOPSIS
    Builds Dhikr Reminder for Windows and stages the result under .\dist.

.DESCRIPTION
    `flutter build windows`, then:
      1. copies the build output into  dist\dhikr_reminder-<version>-windows-x64\
      2. zips that folder              dist\dhikr_reminder-<version>-windows-x64.zip
      3. with -Installer, also compiles scripts\installer.iss into
                                       dist\dhikr_reminder-<version>-setup.exe

    The .zip is the no-dependency artifact and is always produced; the setup
    .exe needs Inno Setup 6 installed and is for people who want a Start-menu
    entry and an uninstaller.

    gratovo_toolbox ships a far larger build_windows.ps1. This one deliberately
    leaves out what that script also does there -- bumping pubspec's version and
    pushing a v* tag. Tag a release by hand and .github/workflows/release.yml
    builds it; the installed app then finds it on its own (lib/core/update/),
    which is why the release must carry the *-setup.exe, not just the .zip.

.EXAMPLE
    .\scripts\build_windows.ps1
    .\scripts\build_windows.ps1 -Installer
    .\scripts\build_windows.ps1 -Configuration Profile -SkipPubGet
#>
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Profile', 'Release')]
    [string] $Configuration = 'Release',

    # Compile the Inno Setup installer as well.
    [switch] $Installer,

    # Where the staged folder / .zip / setup .exe land. Defaults to .\dist.
    [string] $OutDir,

    # Reuse the current .dart_tool package config instead of resolving again.
    [switch] $SkipPubGet
)

$ErrorActionPreference = 'Stop'
# Progress bars are write-heavy and make CI logs unreadable.
$ProgressPreference = 'SilentlyContinue'

$RepoRoot = Split-Path -Parent $PSScriptRoot

# --- Read the identity out of pubspec.yaml so nothing here can drift from it --
$pubspecText = Get-Content -LiteralPath (Join-Path $RepoRoot 'pubspec.yaml') -Raw
$name = [regex]::Match($pubspecText, '(?m)^name:\s*(\S+)\s*$').Groups[1].Value
$versionLine = [regex]::Match($pubspecText, '(?m)^version:\s*(\S+)').Groups[1].Value
if (-not $name -or -not $versionLine) {
    throw 'Could not read name/version from pubspec.yaml.'
}
$semver = ($versionLine -split '\+')[0]
if (-not $OutDir) { $OutDir = Join-Path $RepoRoot 'dist' }

Write-Host "Building $name v$semver ($Configuration) for Windows x64" -ForegroundColor Cyan

# --- Resolve + build ----------------------------------------------------------
Push-Location $RepoRoot
try {
    if (-not $SkipPubGet) {
        flutter pub get
        if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed ($LASTEXITCODE)" }
    }

    # The build regenerates localizations anyway, but a bad ARB file wants to
    # fail here -- next to the pub get that produced it -- not 40s later,
    # buried inside the Windows toolchain's own output.
    flutter gen-l10n
    if ($LASTEXITCODE -ne 0) { throw "flutter gen-l10n failed ($LASTEXITCODE)" }

    flutter build windows "--$($Configuration.ToLowerInvariant())"
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed ($LASTEXITCODE)" }

    # Flutter has moved this folder around across releases
    # (build\windows\runner\<Config> -> build\windows\x64\runner\<Config>), so
    # search for the .exe under the configuration folder instead of hardcoding
    # one layout and breaking the first time the toolchain shifts.
    $exe = Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'build\windows') -Recurse -Filter "$name.exe" |
        Where-Object { $_.FullName -match "[\\/]$Configuration[\\/]" } |
        Select-Object -First 1
    if (-not $exe) {
        throw "flutter reported success but no $name.exe was found under build\windows\$Configuration."
    }
    $builtRoot = $exe.DirectoryName

    # The .exe is nothing without data\ (flutter_assets, icudtl.dat).
    if (-not (Test-Path (Join-Path $builtRoot 'data\flutter_assets'))) {
        throw 'Built folder is missing data\flutter_assets - refusing to ship an .exe that cannot start.'
    }

    # --- Stage ----------------------------------------------------------------
    $stagedName = "$name-$semver-windows-x64"
    $staged = Join-Path $OutDir $stagedName
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    if (Test-Path -LiteralPath $staged) {
        Remove-Item -LiteralPath $staged -Recurse -Force
    }
    New-Item -ItemType Directory -Path $staged -Force | Out-Null
    Copy-Item -Path (Join-Path $builtRoot '*') -Destination $staged -Recurse -Force

    # --- Zip ------------------------------------------------------------------
    $zip = Join-Path $OutDir "$stagedName.zip"
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    # Passing the folder (not its contents) keeps the archive unzipping into a
    # single named folder rather than dropping the .exe loose in the cwd.
    Compress-Archive -LiteralPath $staged -DestinationPath $zip

    # --- Installer ------------------------------------------------------------
    $setupExe = $null
    if ($Installer) {
        $iscc = @(
            "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
            "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
        ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        if (-not $iscc) {
            throw 'Inno Setup 6 is not installed (checked both Program Files folders). Get it from https://jrsoftware.org/isdl.php, or drop -Installer and ship the .zip.'
        }
        & $iscc "/DAppVersion=$semver" "/DSourceDir=$staged" "/DOutputDir=$OutDir" (Join-Path $PSScriptRoot 'installer.iss')
        if ($LASTEXITCODE -ne 0) { throw "ISCC failed ($LASTEXITCODE)" }
        $setupExe = Join-Path $OutDir "$name-$semver-setup.exe"
        if (-not (Test-Path -LiteralPath $setupExe)) {
            throw "ISCC reported success but $setupExe is not there."
        }
    }
}
finally {
    Pop-Location
}

# --- Summary ------------------------------------------------------------------
Write-Host ''
Write-Host "Output in $OutDir" -ForegroundColor Green
foreach ($path in @($staged, $zip, $setupExe)) {
    if (-not $path -or -not (Test-Path -LiteralPath $path)) { continue }
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $mb = [math]::Round((Get-Item -LiteralPath $path).Length / 1MB, 1)
        Write-Host ('  {0,7} MB  {1}' -f $mb, $path)
    }
    else {
        $sum = (Get-ChildItem -LiteralPath $path -Recurse -File | Measure-Object Length -Sum).Sum
        Write-Host ('  {0,7} MB  {1}  (folder)' -f ([math]::Round($sum / 1MB, 1)), $path)
    }
}
Write-Host ''
Write-Host "Run it: $staged\$name.exe" -ForegroundColor Cyan

