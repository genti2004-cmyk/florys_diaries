$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$apk = Join-Path $projectRoot 'build/app/outputs/flutter-apk/app-release.apk'
if (-not (Test-Path -LiteralPath $apk)) {
    throw 'Release-APK fehlt. Führe zuerst tools/build_release.ps1 aus.'
}

& "$PSScriptRoot/verify_release_signature.ps1" -ApkPath $apk
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
$adb = if ($adbCommand) {
    $adbCommand.Source
} else {
    Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
}
if (-not (Test-Path -LiteralPath $adb)) { throw 'adb wurde nicht gefunden.' }

Write-Host 'Installiere die normale FlorysDiaries-App als Update. Die DEV-App bleibt getrennt.' -ForegroundColor Cyan
& $adb install -r $apk
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host 'Release-App erfolgreich installiert.' -ForegroundColor Green
