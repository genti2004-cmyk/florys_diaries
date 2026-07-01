param(
    [switch]$SkipFlutterChecks
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw $Message
    }
}

function Read-PropertyFile {
    param([string]$Path)

    $result = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#')) {
            continue
        }

        $separator = $trimmed.IndexOf('=')
        if ($separator -lt 1) {
            continue
        }

        $key = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1).Trim()
        $result[$key] = $value
    }

    return $result
}

Write-Host 'FlorysDiaries Release-Pruefung' -ForegroundColor Cyan

$requiredFiles = @(
    'pubspec.yaml',
    'lib/core/constants/app_metadata.dart',
    'android/app/build.gradle.kts',
    'android/app/src/main/AndroidManifest.xml',
    'android/app/src/main/kotlin/com/florysdiaries/app/MainActivity.kt'
)

foreach ($path in $requiredFiles) {
    Assert-True (Test-Path -LiteralPath $path) "Pflichtdatei fehlt: $path"
}

$pubspec = Get-Content -Raw -LiteralPath 'pubspec.yaml'
$metadata = Get-Content -Raw -LiteralPath 'lib/core/constants/app_metadata.dart'
$gradle = Get-Content -Raw -LiteralPath 'android/app/build.gradle.kts'
$manifest = Get-Content -Raw -LiteralPath 'android/app/src/main/AndroidManifest.xml'

Assert-True ($pubspec -match '(?m)^version:\s*1\.0\.0\+7\s*$') 'pubspec.yaml ist nicht auf 1.0.0+7.'
Assert-True ($metadata.Contains("releasePackageId = 'com.florysdiaries.app'")) 'Release-Paketkennung stimmt nicht.'
Assert-True ($metadata.Contains("debugPackageId = 'com.florysdiaries.app.debug'")) 'DEV-Paketkennung stimmt nicht.'
Assert-True ($gradle.Contains('applicationId = "com.florysdiaries.app"')) 'Android Release applicationId stimmt nicht.'
Assert-True ($gradle.Contains('applicationIdSuffix = ".debug"')) 'Android DEV applicationIdSuffix fehlt.'
Assert-True ($gradle.Contains('val releaseAppLabel = "FlorysDiaries"')) 'Release-App-Name stimmt nicht.'
Assert-True ($gradle.Contains('val debugAppLabel = "FlorysDiaries DEV"')) 'DEV-App-Name stimmt nicht.'
Assert-True ($manifest.Contains('android:label="${appLabel}"')) 'Manifest verwendet den App-Label-Platzhalter nicht.'
Assert-True ($manifest.Contains('android:allowBackup="false"')) 'Android-Systembackup muss deaktiviert bleiben.'
Assert-True ($manifest.Contains('android:usesCleartextTraffic="false"')) 'Cleartext-Traffic muss deaktiviert bleiben.'

$keyPropertiesPath = 'android/key.properties'
Assert-True (Test-Path -LiteralPath $keyPropertiesPath) 'android/key.properties fehlt. Nutze android/key.properties.example als Vorlage.'

$properties = Read-PropertyFile -Path $keyPropertiesPath
foreach ($name in @('storePassword', 'keyPassword', 'keyAlias', 'storeFile')) {
    Assert-True ($properties.ContainsKey($name)) "Eintrag fehlt in android/key.properties: $name"

    $value = [string]$properties[$name]
    Assert-True (-not [string]::IsNullOrWhiteSpace($value)) "Eintrag ist leer in android/key.properties: $name"
    Assert-True (-not $value.StartsWith('DEIN_') -and -not $value.StartsWith('YOUR_')) "Platzhalter ist noch aktiv in android/key.properties: $name"
}

$storeFile = [string]$properties['storeFile']
if (-not [System.IO.Path]::IsPathRooted($storeFile)) {
    $storeFile = Join-Path (Join-Path $projectRoot 'android') $storeFile
}
Assert-True (Test-Path -LiteralPath $storeFile) 'Der in android/key.properties angegebene Keystore wurde nicht gefunden.'

# Sicherheitspruefung ohne "git ls-files --error-unmatch".
# Ein nicht verfolgter Pfad liefert hier einfach keine Ausgabe und verursacht
# deshalb unter Windows PowerShell keinen NativeCommandError.
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitRoot = & git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($gitRoot)) {
        $trackedKeyProperties = @(& git ls-files -- 'android/key.properties')
        Assert-True ($LASTEXITCODE -eq 0) 'Git-Pruefung fuer android/key.properties ist fehlgeschlagen.'
        Assert-True ($trackedKeyProperties.Count -eq 0) 'Sicherheitsfehler: android/key.properties wird von Git verfolgt.'

        $trackedKeys = @(& git ls-files -- '*.jks' '*.keystore')
        Assert-True ($LASTEXITCODE -eq 0) 'Git-Pruefung fuer Keystore-Dateien ist fehlgeschlagen.'
        Assert-True ($trackedKeys.Count -eq 0) 'Sicherheitsfehler: Eine Keystore-Datei wird von Git verfolgt.'
    }
}

if (-not $SkipFlutterChecks) {
    & flutter analyze
    Assert-True ($LASTEXITCODE -eq 0) 'flutter analyze ist fehlgeschlagen.'

    & flutter test
    Assert-True ($LASTEXITCODE -eq 0) 'flutter test ist fehlgeschlagen.'
}

Write-Host 'Release-Pruefung erfolgreich.' -ForegroundColor Green
