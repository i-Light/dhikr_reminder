#Requires -Version 5.1
<#
.SYNOPSIS
    Makes the upload key Google Play asks for, and the android\key.properties
    file the Android build reads it through.

.DESCRIPTION
    Run this once, before the first store build. It creates
    android\upload-keystore.jks and android\key.properties. Both are
    git-ignored and must never be committed.

    Back both files up somewhere safe (a password manager, an encrypted drive)
    together with the password. With Play App Signing, which is on by default,
    Google holds the key that signs what users get, so a lost upload key can be
    replaced through Play support; but it is a delay you can avoid.

    scripts\build_android.ps1 uses the key.properties this writes to sign the
    App Bundle. Without it that script refuses to make a bundle, because a
    bundle signed with the debug key is rejected by the store.

.PARAMETER Alias
    The key's name inside the keystore. Defaults to "upload".

.PARAMETER Name
    The name written into the certificate. It is not shown to users.

.PARAMETER Password
    The password for the keystore and the key. Asked for (twice, hidden) when
    left out.

.PARAMETER StorePath
    Where the keystore goes. Defaults to android\upload-keystore.jks.

.PARAMETER PropsPath
    Where key.properties goes. Defaults to android\key.properties.

.EXAMPLE
    .\scripts\create_upload_key.ps1
#>
[CmdletBinding()]
param(
    [string] $Alias = 'upload',
    [string] $Name = 'CN=Gratovo, O=Gratovo, C=EG',
    [securestring] $Password,
    [string] $StorePath,
    [string] $PropsPath
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $StorePath) { $StorePath = Join-Path $RepoRoot 'android\upload-keystore.jks' }
if (-not $PropsPath) { $PropsPath = Join-Path $RepoRoot 'android\key.properties' }

foreach ($path in $StorePath, $PropsPath) {
    if (Test-Path -LiteralPath $path) {
        throw "$path already exists. Not overwriting it: replacing a key that was already uploaded to Play would lock you out of updates. Move it away yourself if you really mean to start over."
    }
}

function Find-Keytool {
    $onPath = Get-Command keytool.exe -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    if ($env:JAVA_HOME) {
        $fromHome = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
        if (Test-Path -LiteralPath $fromHome) { return $fromHome }
    }
    throw 'keytool.exe not found. It comes with the JDK that Flutter uses: set JAVA_HOME to it (flutter doctor -v shows which).'
}
$keytool = Find-Keytool

if (-not $Password) {
    $first = Read-Host 'Choose a password for the upload key (at least 6 characters)' -AsSecureString
    $second = Read-Host 'Type it again' -AsSecureString
    $Password = $first
    $a = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($first))
    $b = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($second))
    if ($a -ne $b) { throw 'The two passwords differ.' }
}
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
if ($plain.Length -lt 6) { throw 'The password must be at least 6 characters.' }
# key.properties is a Java properties file, where a backslash starts an escape
# and some other characters mean something.
if ($plain -match '[\\\r\n#!=:]') {
    throw 'Use a password without these characters: \ # ! = : or a line break (they break key.properties).'
}

New-Item -ItemType Directory -Path (Split-Path -Parent $StorePath) -Force | Out-Null
# keytool reports its progress on stderr, which Windows PowerShell 5.1 turns
# into a terminating error under 'Stop'. Its exit code is the real answer.
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & $keytool -genkeypair `
        -keystore $StorePath -alias $Alias `
        -keyalg RSA -keysize 2048 -validity 10000 `
        -storepass $plain -keypass $plain `
        -dname $Name 2>&1 | ForEach-Object { Write-Host "$_" }
    $exit = $LASTEXITCODE
}
finally { $ErrorActionPreference = $previous }
if ($exit -ne 0) { throw "keytool failed (exit $exit)." }

# storeFile is read relative to the android\ folder, with forward slashes.
$androidDir = Join-Path $RepoRoot 'android'
$relative = [IO.Path]::GetFullPath($StorePath)
if ($relative.StartsWith($androidDir, [StringComparison]::OrdinalIgnoreCase)) {
    $relative = $relative.Substring($androidDir.Length).TrimStart('\', '/')
}
$relative = $relative -replace '\\', '/'

$lines = @(
    "storeFile=$relative",
    "storePassword=$plain",
    "keyAlias=$Alias",
    "keyPassword=$plain"
)
[IO.File]::WriteAllText($PropsPath, ($lines -join "`n") + "`n", (New-Object Text.UTF8Encoding($false)))

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host "  keystore:       $StorePath"
Write-Host "  key.properties: $PropsPath"
Write-Host ''
Write-Host 'Back both up now, with the password. Neither is in git, on purpose.' -ForegroundColor Yellow
Write-Host 'Next: .\scripts\build_android.ps1   (makes the .aab to upload to Play)'
