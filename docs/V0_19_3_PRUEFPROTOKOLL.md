# FlorysDiaries v0.19.3 – Prüfprotokoll

## Versionsstand

- App-Version: `0.19.3`
- Build-Nummer: `5`
- Flutter-Versionseintrag: `0.19.3+5`
- Git-Tag: `v0.19.3`

## Automatische Prüfung

Im Projektordner ausführen:

```powershell
dart format lib test
flutter analyze
flutter test
```

Erwartet:

- `No issues found!`
- `All tests passed!`

## Gerätetest in FlorysDiaries DEV

1. Bestehende Reise bearbeiten und nur den Titel ändern.
2. Dokumente, Album, Checkliste und Fotoanzahl kontrollieren.
3. Ungespeicherte Reiseänderungen mit Android-Zurück testen.
4. Favorisiertes Dokument bearbeiten und Favoritenstatus prüfen.
5. Dokumentdatei weiterhin öffnen.
6. Album-Eintrag bearbeiten und Metadaten kontrollieren.
7. Checklistenaufgabe bearbeiten und Fälligkeitsdatum entfernen.
8. Lokales Backup erstellen und Vorschau öffnen.
9. Google-Drive-Backup erstellen und Vorschau öffnen.
10. In beiden Vorschauen App-Version `0.19.3` kontrollieren.
11. Reisen, Dokumente, Album und Checkliste abschließend kontrollieren.

## Git-Sicherheitsprüfung

```powershell
git status --short
git check-ignore -v android/key.properties

git diff --cached --name-only |
Select-String -Pattern "key\.properties|\.jks$|\.keystore$"
```

Die letzte Abfrage darf keine Ausgabe liefern.

## Commit und Tag

Erst nach bestandener Gesamtprüfung:

```powershell
git add .

git diff --cached --name-only |
Select-String -Pattern "key\.properties|\.jks$|\.keystore$"

git commit -m "FlorysDiaries v0.19.3 - Datenintegritaet und QA"
git tag v0.19.3

$branch = git branch --show-current
git push origin $branch
git push origin v0.19.3
```

## Release-Build

```powershell
flutter build apk --release
flutter build appbundle --release
```

Erwartete Dateien:

```text
build\app\outputs\flutter-apk\app-release.apk
build\app\outputs\bundle\release\app-release.aab
```

## Backup vor Release-Update

In der normalen FlorysDiaries-App:

1. manuelles lokales Backup erstellen
2. manuelles Google-Drive-Backup erstellen
3. beide Backup-Historien kontrollieren

## Sicheres Update der normalen App

Ausschließlich mit dem signierten Release-APK aktualisieren:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r `
  "build\app\outputs\flutter-apk\app-release.apk"
```

Nicht deinstallieren und nicht `flutter run --release` verwenden.

Bei `UPDATE_INCOMPATIBLE`, Signaturfehlern oder einer anderen
Installationswarnung sofort stoppen.
