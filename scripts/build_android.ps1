#Requires -Version 5.1
<#
.SYNOPSIS
    Builds the Android release: redraws the app icons from logo.svg, then
    builds a Play Store App Bundle (and optionally an installable APK).

.DESCRIPTION
    The launcher icon (legacy + adaptive) and the notification icon are drawn
    from assets/images/logo.svg by tool/generate_app_icon.dart -- the same
    step, and the same SVG, as the Windows build's .exe icon.

    Signing: android/key.properties (git-ignored) says which key signs the build.
    Run scripts\create_upload_key.ps1 once to make the key and that file; it looks
    like this:

        storeFile=upload-keystore.jks
        storePassword=...
        keyAlias=upload
        keyPassword=...

    Without it nothing is built: the Gradle build refuses a release without the
    key, so a file that no store would take is never made by accident. (For a
    debug-signed APK on purpose, set $env:ALLOW_UNSIGNED = 'true' and run
    `flutter build apk --release` by hand; this script never does.)

.PARAMETER Apk
    Also build installable APKs, one per CPU (build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
    is the one for current phones), and print their sizes.

.PARAMETER SkipChecks
    Do not run flutter analyze / flutter test first.

.PARAMETER ApkOnly
    Build only the APKs (implies -Apk), not the App Bundle. This is what
    build_windows.ps1 runs next to the installer.

.PARAMETER SkipIcons
    Do not redraw the app icons first (the caller already did).

.PARAMETER OutDir
    Also copy each APK here as dhikr_reminder-<Version>-android-<cpu>.apk, next
    to the Windows installer.

.PARAMETER Version
    The app version used in those file names.

.EXAMPLE
    .\scripts\build_android.ps1
    .\scripts\build_android.ps1 -Apk
#>
[CmdletBinding()]
param(
    [switch]$Apk,
    [switch]$SkipChecks,
    [switch]$ApkOnly,
    [switch]$SkipIcons,
    [string]$OutDir,
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Invoke-Native([string]$What, [scriptblock]$Command) {
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$What failed (exit code $LASTEXITCODE)." }
}

if (-not $SkipIcons) {
    Write-Host 'Generating the app icons from assets/images/logo.svg' -ForegroundColor Cyan
    Invoke-Native 'generate app icon' { flutter test --no-pub tool/generate_app_icon.dart }
}

if (-not $SkipChecks) {
    Invoke-Native 'analyze' { flutter analyze --fatal-infos }
    Invoke-Native 'tests' { flutter test --no-pub }
}

if (-not (Test-Path (Join-Path $RepoRoot 'android\key.properties'))) {
    # The App Bundle exists to be uploaded to Google Play, which rejects one
    # signed with the debug key. The Gradle build refuses any release without
    # the key, so say so here and do not start a build that must fail.
    if (-not $ApkOnly) {
        throw 'android\key.properties not found, so the bundle would be signed with the debug key and Google Play would refuse it. Run .\scripts\create_upload_key.ps1 once to make the upload key (see docs\publishing-guide.md, Phase 2.1).'
    }
    Write-Warning 'android\key.properties not found: the Android APKs were not built (a release is never signed with the debug key).'
    return
}

# Size flags: --obfuscate shortens the Dart symbol names baked into the
# binary, and --split-debug-info moves the symbol tables out of it (keep
# build\symbols to de-obfuscate crash traces). Tree-shaken icons and R8 resource
# shrinking are already on in release builds.
$tiny = @('--obfuscate', '--split-debug-info=build/symbols')

# The dhikr request service (server/README.md) is found at the address committed
# in lib/features/requests/data/requests_config.dart. Setting DHIKR_REQUESTS_URL
# overrides it for this build.
if ($env:DHIKR_REQUESTS_URL) {
    $tiny += "--dart-define=DHIKR_REQUESTS_URL=$($env:DHIKR_REQUESTS_URL)"
    Write-Host "Request service (override): $($env:DHIKR_REQUESTS_URL)" -ForegroundColor Cyan
} else {
    Write-Host 'Request service: the address in requests_config.dart' -ForegroundColor Cyan
}

if (-not $ApkOnly) {
    Write-Host 'Building the App Bundle (Release)' -ForegroundColor Cyan
    Invoke-Native 'build appbundle' { flutter build appbundle --release @tiny }
}

if ($Apk -or $ApkOnly) {
    # One APK per CPU: a phone only ever needs its own, so each is a fraction
    # of the universal one. Phones from the last several years are arm64-v8a.
    Write-Host 'Building the APKs (Release, one per CPU)' -ForegroundColor Cyan
    # Old outputs (a universal app-release.apk from an earlier run, say) must
    # not be mistaken for this build's.
    Remove-Item build\app\outputs\flutter-apk\*.apk -ErrorAction SilentlyContinue
    Invoke-Native 'build apk' { flutter build apk --release --split-per-abi @tiny }
    if ($OutDir) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
    Get-ChildItem build\app\outputs\flutter-apk\app-*-release.apk | ForEach-Object {
        '{0,8:N1} MB  {1}' -f ($_.Length / 1MB), $_.Name | Write-Host
        if ($OutDir) {
            $cpu = $_.Name -replace '^app-(.*)-release\.apk$', '$1'
            $label = if ($Version) { "dhikr_reminder-$Version-android-$cpu.apk" } else { "dhikr_reminder-android-$cpu.apk" }
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $OutDir $label) -Force
        }
    }
}

if ($ApkOnly) {
    Write-Host 'Done: the Android APKs.' -ForegroundColor Green
} else {
    Write-Host 'Done: build\app\outputs\bundle\release\app-release.aab' -ForegroundColor Green
}
