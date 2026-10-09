#Requires -Version 5.1
<#
.SYNOPSIS
    One command from the working tree to a Google Play track: raises the build
    number, builds the signed App Bundle and uploads it.

.DESCRIPTION
    What it does, in order:
      1. Checks the upload key (android\key.properties) and the Play service
         account key (android\play-service-account.json) exist.
      2. Raises only the build number in pubspec.yaml (0.1.3+4 -> 0.1.3+5).
         Play refuses a version code it has already seen, and every test
         iteration needs a new one. The version name is left alone.
      3. Runs analyze + tests and builds the .aab (scripts\build_android.ps1).
      4. Uploads it with scripts\play_upload.mjs and commits the bump.
    If the build or upload fails, pubspec.yaml is put back as it was.

    The first bundle of a brand new app must be uploaded by hand in Play
    Console; this script is for every upload after that.
    See docs\publishing-guide.md, Phase 5, for the one-time setup.

.PARAMETER Track
    internal (default, instant, up to 100 testers), alpha (closed testing),
    beta (open testing) or production.

.PARAMETER Notes
    Release notes in English. Shown to testers and, later, to everyone.

.PARAMETER NotesAr
    Release notes in Arabic.

.PARAMETER Status
    completed (default), draft (review it in Play Console first) or inProgress
    (staged rollout, see -Rollout).

.PARAMETER Rollout
    Share of users for -Status inProgress. Default 0.2.

.PARAMETER Check
    Only test the connection to Play (key, package, permissions). Builds and
    uploads nothing, changes no file.

.PARAMETER SkipChecks
    Do not run flutter analyze / flutter test first.

.PARAMETER NoBump
    Keep the build number as it is (use after a failed upload that never
    reached Play).

.EXAMPLE
    .\scripts\publish_android.ps1 -Check
    .\scripts\publish_android.ps1 -Notes "Fixed the lock screen card"
    .\scripts\publish_android.ps1 -Track production -Status inProgress -Rollout 0.1
#>
[CmdletBinding()]
param(
    [ValidateSet('internal', 'alpha', 'beta', 'production')]
    [string]$Track = 'internal',
    [string]$Notes = '',
    [string]$NotesAr = '',
    [ValidateSet('completed', 'draft', 'inProgress')]
    [string]$Status = 'completed',
    [double]$Rollout = 0.2,
    [switch]$Check,
    [switch]$SkipChecks,
    [switch]$NoBump
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Invoke-Native([string]$What, [scriptblock]$Command) {
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$What failed (exit code $LASTEXITCODE)." }
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw 'node not found. Install Node.js (the server\ folder already needs it).'
}

$serviceKey = if ($env:PLAY_SERVICE_ACCOUNT) { $env:PLAY_SERVICE_ACCOUNT } else { Join-Path $RepoRoot 'android\play-service-account.json' }
if (-not (Test-Path -LiteralPath $serviceKey)) {
    throw "Play service account key not found: $serviceKey`nSet it up once (docs\publishing-guide.md, Phase 5)."
}

if ($Check) {
    Invoke-Native 'Play check' { node scripts/play_upload.mjs --check }
    return
}

if (-not (Test-Path (Join-Path $RepoRoot 'android\key.properties'))) {
    throw 'android\key.properties not found. Run .\scripts\create_upload_key.ps1 once (docs\publishing-guide.md, Phase 2.1).'
}

$pubspecPath = Join-Path $RepoRoot 'pubspec.yaml'
$original = Get-Content -LiteralPath $pubspecPath -Raw
$m = [regex]::Match($original, '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)')
if (-not $m.Success) { throw 'Could not read version: x.y.z+n from pubspec.yaml.' }
$semver = $m.Groups[1].Value
$build = [int]$m.Groups[2].Value
if (-not $NoBump) { $build++ }

$bumped = $false
try {
    if (-not $NoBump) {
        $rewritten = [regex]::Replace($original, '(?m)^version:\s*\S+', "version: $semver+$build", 1)
        [IO.File]::WriteAllText($pubspecPath, $rewritten, (New-Object Text.UTF8Encoding($false)))
        $bumped = $true
    }
    Write-Host "Publishing $semver+$build to the $Track track" -ForegroundColor Cyan

    if ($SkipChecks) { & (Join-Path $PSScriptRoot 'build_android.ps1') -SkipChecks }
    else { & (Join-Path $PSScriptRoot 'build_android.ps1') }

    $uploadArgs = @('scripts/play_upload.mjs', '--track', $Track, '--status', $Status, '--name', "$semver ($build)")
    if ($Status -eq 'inProgress') { $uploadArgs += @('--fraction', "$Rollout") }
    if ($Notes) { $uploadArgs += @('--notes-en', $Notes) }
    if ($NotesAr) { $uploadArgs += @('--notes-ar', $NotesAr) }
    Invoke-Native 'Play upload' { node @uploadArgs }
}
catch {
    if ($bumped) {
        [IO.File]::WriteAllText($pubspecPath, $original, (New-Object Text.UTF8Encoding($false)))
        Write-Host 'pubspec.yaml restored to its previous version.' -ForegroundColor Yellow
    }
    throw
}

if ($bumped) {
    git add pubspec.yaml
    git commit -m "Upload $semver+$build to Play ($Track)" -- pubspec.yaml | Out-Null
    Write-Host "Committed the build number bump ($semver+$build). Push when you like." -ForegroundColor Green
}
Write-Host "Done. Next: Play Console > Testing > $Track to see it, or open the tester link on a phone." -ForegroundColor Green
