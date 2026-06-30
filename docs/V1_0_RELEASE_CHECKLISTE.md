# FlorysDiaries 1.0.0+7 – Release-Checkliste

## Festgelegte Identität

- App-Name: `FlorysDiaries`
- DEV-App-Name: `FlorysDiaries DEV`
- Android Release: `com.florysdiaries.app`
- Android Debug: `com.florysdiaries.app.debug`
- iOS Release: `com.florysdiaries.app`
- iOS Debug: `com.florysdiaries.app.debug`
- Version: `1.0.0+7`
- Git-Tag: `v1.0.0`

## Schutzregeln

- Die normale Release-App mit echten Daten niemals deinstallieren.
- `flutter run` wird ausschließlich für die DEV-App verwendet.
- Die normale App wird nur mit einem korrekt signierten APK und
  `adb install -r` aktualisiert.
- Bei Signatur- oder Updatefehler sofort stoppen.
- `android/key.properties`, JKS- und Keystore-Dateien niemals committen,
  hochladen oder weitergeben.
- Vor dem Release ein aktuelles lokales und ein Google-Drive-Backup prüfen.

## Technische Prüfung

```powershell
cd C:\Users\aliu\StudioProjects\florys_diaries

flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Erwartet:

```text
No issues found!
All tests passed!
```

## DEV-Gerätetest

```powershell
flutter run
```

Prüfen:

1. App-Name ist `FlorysDiaries DEV`.
2. bestehende DEV-Reisen werden geladen.
3. Reise anlegen, ändern und löschen
4. Dokument importieren und öffnen
5. Bild- und PDF-Anzeige
6. Album und Checkliste
7. Weltkarte und Travel Replay
8. lokales manuelles Backup
9. automatisches lokales Backup
10. manuelles Google-Drive-Backup
11. automatische Google-Drive-Sicherung
12. Backup-Historien und Wiederherstellungsvorschau
13. App vollständig schließen und neu öffnen
14. Backup-Einstellungen bleiben erhalten
15. ohne Datenänderung entsteht kein unnötiges automatisches Backup

## Signierte Artefakte erstellen

```powershell
flutter build apk --release
flutter build appbundle --release
```

Erwartete Dateien:

```text
build\app\outputs\flutter-apk\app-release.apk
build\app\outputs\bundle\release\app-release.aab
```

## Signatur prüfen

```powershell
$apksigner = Get-ChildItem `
  "$env:LOCALAPPDATA\Android\Sdk\build-tools" `
  -Recurse -Filter apksigner.bat |
  Sort-Object FullName -Descending |
  Select-Object -First 1

& $apksigner.FullName verify --print-certs `
  build\app\outputs\flutter-apk\app-release.apk
```

Erwartete Release-SHA-1:

```text
64:58:2B:C2:E8:41:16:DF:FE:EE:C2:54:BA:AF:94:7C:CA:F6:8B:7B
```

## Normale App sicher aktualisieren

Vorher ein geprüftes Backup erstellen.

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

& $adb install -r `
  build\app\outputs\flutter-apk\app-release.apk
```

Erwartet:

```text
Success
```

Bei `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, Signaturfehlern oder einer
anderen Update-Ablehnung die normale App nicht deinstallieren.

## Release-Gerätetest

Nach erfolgreichem `adb install -r`:

1. App-Name ist `FlorysDiaries`.
2. vorhandene echte Reisen und Dokumente sind weiterhin vorhanden.
3. lokale Backups sind sichtbar.
4. Google-Drive-Anmeldung funktioniert.
5. manuelles und automatisches Backup funktionieren.
6. Wiederherstellungsvorschau funktioniert.
7. Weltkarte und Travel Replay funktionieren.
8. Datenschutz- und Datenansicht ist erreichbar.
9. angezeigte Version ist `v1.0.0`.

## Externe Store-Voraussetzungen

Vor öffentlicher Store-Freigabe noch mit echten Angaben vervollständigen:

- Anbietername
- Support-E-Mail
- öffentliche HTTPS-Webseite
- öffentliche HTTPS-Datenschutzerklärung
- Google-Play-Data-Safety-Angaben
- veröffentlichter Google-OAuth-Zustimmungsbildschirm
- gegebenenfalls Google-OAuth-Verifizierung

Diese Angaben sind nicht Bestandteil des Quellcodepakets und dürfen nicht
erfunden werden.

## Git-Abschluss

Erst nach vollständig bestandenem Release-Gerätetest:

```powershell
git status
git add .
git commit -m "release: FlorysDiaries 1.0.0"
git tag -a v1.0.0 -m "FlorysDiaries 1.0.0"
git push origin main
git push origin v1.0.0
```
