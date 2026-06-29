# FlorysDiaries v0.19.4 – Prüfprotokoll

## Versionsstand

- App-Version: `0.19.4`
- Build-Nummer: `6`
- Flutter-Versionseintrag: `0.19.4+6`
- Git-Tag: `v0.19.4`
- Status: Release Candidate

## Enthaltene Sicherheitsbereiche

1. atomare lokale Speicherung und automatische Wiederherstellung
2. Sperre von Änderungen bei unsicherem lokalen Datenzustand
3. geschützte und reisegebundene Dokumentpfade
4. vollständige Selbstprüfung neu erzeugter Backups
5. validierte lokale Backup-Historie
6. Sperre beschädigter Sicherungen für die Wiederherstellung

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

## Abschließender Gerätetest in FlorysDiaries DEV

1. App starten und vorhandene Reisen kontrollieren.
2. Eine Reise bearbeiten, speichern und erneut öffnen.
3. Dokumente, Album und Checkliste der Reise prüfen.
4. Ein bestehendes Dokument öffnen.
5. Bei einem Testdokument die Datei ersetzen und erneut öffnen.
6. Ein manuelles lokales Backup erstellen.
7. Lokale Backup-Historie öffnen und Vorschau kontrollieren.
8. Ein manuelles Google-Drive-Backup erstellen.
9. Google-Drive-Vorschau öffnen und App-Version `0.19.4` kontrollieren.
10. Einstellungen vollständig öffnen und Version `v0.19.4` kontrollieren.
11. App vollständig schließen und erneut starten.
12. Reisen, Dokumente und beide Backup-Historien abschließend kontrollieren.

Beschädigte Dateien müssen auf dem Smartphone nicht künstlich erzeugt werden.
Diese Fehlerwege werden durch die automatischen Regressionstests geprüft.

## Git-Sicherheitsprüfung

```powershell
git status --short
git check-ignore -v android/key.properties

git add .

git diff --cached --name-only |
Select-String -Pattern "key\.properties|\.jks$|\.keystore$"

git diff --cached --stat
```

Die Schlüsselprüfung darf keine Ausgabe liefern. Falls `git diff --cached
--stat` in einer Seitenansicht mit `:` endet, diese mit `q` schließen.

## Commit und Tag

Erst nach vollständig bestandener Prüfung:

```powershell
git commit -m "FlorysDiaries v0.19.4 - Release Candidate und Datensicherheit"
git tag v0.19.4

$branch = git branch --show-current
git push origin $branch
git push origin v0.19.4
```

Falls `v0.19.4` bereits existiert, nicht löschen oder überschreiben. Zuerst
prüfen:

```powershell
git show v0.19.4 --no-patch --decorate
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

## Backup vor dem Update der normalen App

In der normalen FlorysDiaries-App:

1. manuelles lokales Backup erstellen
2. manuelles Google-Drive-Backup erstellen
3. beide Backup-Historien und Vorschauen kontrollieren

## Sicheres Update der normalen App

Nur das signierte Release-APK installieren:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r `
  "build\app\outputs\flutter-apk\app-release.apk"
```

Die normale App niemals deinstallieren und nicht mit `flutter run --release`
aktualisieren.

Bei `UPDATE_INCOMPATIBLE`, Signaturfehlern oder einer anderen
Installationswarnung sofort stoppen.

## Abschlusskontrolle der normalen App

1. Version `v0.19.4` kontrollieren.
2. Echte Reisen, Dokumente, Album und Checkliste kontrollieren.
3. Lokale Backup-Historie öffnen.
4. Google-Drive-Backup-Historie öffnen.
5. Neues Backup erstellen und Vorschau kontrollieren.
6. App schließen, erneut öffnen und Daten nochmals prüfen.
