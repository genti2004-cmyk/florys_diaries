param(
    [string]$ApkPath = 'build/app/outputs/flutter-apk/app-release.apk',
    [string]$PackageId = 'com.florysdiaries.app'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

function Resolve-Adb {
    $command = Get-Command adb -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    $candidate = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
    if (Test-Path -LiteralPath $candidate) { return $candidate }
    throw 'adb wurde nicht gefunden.'
}

function Resolve-ApkSigner {
    $sdkRoot = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
    $buildTools = Join-Path $sdkRoot 'build-tools'
    if (-not (Test-Path -LiteralPath $buildTools)) { throw 'Android build-tools wurden nicht gefunden.' }
    $candidate = Get-ChildItem -LiteralPath $buildTools -Directory |
        Sort-Object { [version]($_.Name -replace '[^0-9\.]', '') } -Descending |
        ForEach-Object { Join-Path $_.FullName 'apksigner.bat' } |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
    if (-not $candidate) { throw 'apksigner.bat wurde nicht gefunden.' }
    return $candidate
}

function Get-CertDigest {
    param([string]$ApkSigner, [string]$Path)
    $output = & $ApkSigner verify --print-certs $Path 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Signaturprüfung fehlgeschlagen: $Path`n$output" }
    $line = $output | Where-Object { $_ -match 'certificate SHA-256 digest:' } | Select-Object -First 1
    if (-not $line) { throw "SHA-256-Zertifikatsdigest konnte nicht gelesen werden: $Path" }
    return (($line -split ':', 2)[1]).Trim().ToLowerInvariant()
}

$apkFullPath = if ([System.IO.Path]::IsPathRooted($ApkPath)) { $ApkPath } else { Join-Path $projectRoot $ApkPath }
if (-not (Test-Path -LiteralPath $apkFullPath)) { throw "Release-APK fehlt: $apkFullPath" }

$adb = Resolve-Adb
$apkSigner = Resolve-ApkSigner
$newDigest = Get-CertDigest -ApkSigner $apkSigner -Path $apkFullPath
Write-Host "Release-Zertifikat: $newDigest" -ForegroundColor Cyan

$deviceState = (& $adb get-state 2>$null).Trim()
if ($deviceState -ne 'device') { throw 'Kein freigegebenes Android-Gerät gefunden.' }

$packagePaths = @(& $adb shell pm path $PackageId 2>$null)
$basePathLine = $packagePaths | Where-Object { $_ -match 'base\.apk' } | Select-Object -First 1
if (-not $basePathLine) {
    Write-Host 'Die normale FlorysDiaries-App ist auf dem Gerät nicht installiert. Kein Signaturvergleich erforderlich.' -ForegroundColor Yellow
    exit 0
}

$remoteBaseApk = ($basePathLine -replace '^package:', '').Trim()
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) 'florysdiaries_release_check'
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
$installedApk = Join-Path $tempDir 'installed-base.apk'
& $adb pull $remoteBaseApk $installedApk | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Installierte APK konnte nicht zur Signaturprüfung gelesen werden.' }

$installedDigest = Get-CertDigest -ApkSigner $apkSigner -Path $installedApk
Write-Host "Installiertes Zertifikat: $installedDigest" -ForegroundColor Cyan
if ($newDigest -ne $installedDigest) {
    throw 'STOPP: Die Release-APK ist anders signiert als die installierte normale App. Nicht installieren.'
}

Write-Host 'Signaturen stimmen überein. Ein Update erhält die vorhandenen App-Daten.' -ForegroundColor Green
