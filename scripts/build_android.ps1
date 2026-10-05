#Requires -Version 5.1
<#
.SYNOPSIS
    Builds the Android release: redraws the app icons from logo.svg, then
    builds a Play Store App Bundle (and optionally an installable APK).

.DESCRIPTION
    The launcher icon (legacy + adaptive) and the notification icon are drawn
    from assets/images/logo.svg by tool/generate_app_icon.dart -- the same
    step, and the same SVG, as the Windows build's .exe icon.

    Signing: put android/key.properties next to the project (it is git-ignored):

        storeFile=../upload-keystore.jks
        storePassword=...
        keyAlias=upload
        keyPassword=...

    Without it the build is signed with the debug key and cannot be uploaded to
    a store.

.PARAMETER Apk
    Also build an installable APK (build\app\outputs\flutter-apk\app-release.apk).

.PARAMETER SkipChecks
    Do not run flutter analyze / flutter test first.

.EXAMPLE
    .\scripts\build_android.ps1
    .\scripts\build_android.ps1 -Apk
#>
[CmdletBinding()]
param(
    [switch]$Apk,
    [switch]$SkipChecks
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Invoke-Native([string]$What, [scriptblock]$Command) {
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$What failed (exit code $LASTEXITCODE)." }
}

Write-Host 'Generating the app icons from assets/images/logo.svg' -ForegroundColor Cyan
Invoke-Native 'generate app icon' { flutter test --no-pub tool/generate_app_icon.dart }

if (-not $SkipChecks) {
    Invoke-Native 'analyze' { flutter analyze --fatal-infos }
    Invoke-Native 'tests' { flutter test --no-pub }
}

if (-not (Test-Path (Join-Path $RepoRoot 'android\key.properties'))) {
    Write-Warning 'android\key.properties not found: signing with the debug key (not uploadable to a store).'
}

Write-Host 'Building the App Bundle (Release)' -ForegroundColor Cyan
Invoke-Native 'build appbundle' { flutter build appbundle --release }

if ($Apk) {
    Write-Host 'Building the APK (Release)' -ForegroundColor Cyan
    Invoke-Native 'build apk' { flutter build apk --release }
}

Write-Host 'Done: build\app\outputs\bundle\release\app-release.aab' -ForegroundColor Green
