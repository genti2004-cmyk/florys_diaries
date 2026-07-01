$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

& "$PSScriptRoot/release_check.ps1"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Erstelle signierte Release-APK ...' -ForegroundColor Cyan
& flutter build apk --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Erstelle signiertes Android App Bundle ...' -ForegroundColor Cyan
& flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apk = Join-Path $projectRoot 'build/app/outputs/flutter-apk/app-release.apk'
$aab = Join-Path $projectRoot 'build/app/outputs/bundle/release/app-release.aab'
if (-not (Test-Path -LiteralPath $apk)) { throw "Release-APK fehlt: $apk" }
if (-not (Test-Path -LiteralPath $aab)) { throw "Release-AAB fehlt: $aab" }

Write-Host "APK: $apk" -ForegroundColor Green
Write-Host "AAB: $aab" -ForegroundColor Green
