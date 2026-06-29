# FlorysDiaries v0.19.2 – Prüfprotokoll

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

1. Startseite öffnen und nächste Reise prüfen.
2. Lange Reisetitel und Zielnamen kontrollieren.
3. Archiv öffnen und Jahresgruppen prüfen.
4. Eine geplante und eine vergangene Reise öffnen.
5. Hero-Karte, Replay, Bearbeiten und Export testen.
6. Weltkarte öffnen, zoomen und verschieben.
7. Ebenen, Jahresfilter sowie Hell/Dunkel testen.
8. Statistik öffnen und Werte kontrollieren.
9. Einstellungen öffnen und vollständig scrollen.
10. Zwischen Gerät und Google Drive wechseln.
11. Löschdialog öffnen und abbrechen.
12. Wiederherstellungsvorschau öffnen, scrollen und abbrechen.
13. Automatische Backup-Einstellungen prüfen.
14. Normale FlorysDiaries-App öffnen und echte Daten kontrollieren.

## Sicherheitsprüfung vor Git

```powershell
git status --short
git check-ignore -v android/key.properties

git diff --cached --name-only |
Select-String -Pattern "key\.properties|\.jks$|\.keystore$"
```

Die letzte Abfrage darf keine Ausgabe liefern.

## Commit und Tag

Erst nach bestandener Prüfung:

```powershell
git add .
git status --short
git commit -m "FlorysDiaries v0.19.2 - UI und responsive Ansichten"
git tag v0.19.2

$branch = git branch --show-current
git push origin $branch
git push origin v0.19.2
```

## Release-Build

Nach erfolgreichem Push:

```powershell
flutter build apk --release
flutter build appbundle --release
```

Erwartete Dateien:

```text
build\app\outputs\flutter-apk\app-release.apk
build\app\outputs\bundle\release\app-release.aab
```

## Sicheres Update der normalen App

Vor dem Update in der normalen FlorysDiaries-App ein manuelles lokales und
ein manuelles Google-Drive-Backup erstellen.

Danach ausschließlich:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r `
  "build\app\outputs\flutter-apk\app-release.apk"
```

Nicht deinstallieren und nicht `flutter run --release` verwenden. Bei
`UPDATE_INCOMPATIBLE` oder einer Signaturmeldung sofort stoppen.
