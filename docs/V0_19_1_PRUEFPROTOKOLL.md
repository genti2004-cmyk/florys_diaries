# FlorysDiaries v0.19.1 – Prüfprotokoll

## Automatische Prüfung

```powershell
dart format lib test
flutter analyze
flutter test
```

Erwartet:

- `No issues found!`
- `All tests passed!`

## Gerätetest in FlorysDiaries DEV

1. App starten.
2. Eine Testreise ändern.
3. Einstellungen öffnen.
4. Backup-Status muss kurz „Vorgemerkt“ oder „Prüfung läuft“ anzeigen.
5. Danach muss „Aktuell“ erscheinen.
6. Lokale Backup-Historie öffnen.
7. „Prüfen & wiederherstellen“ wählen.
8. Quelle, Backup-Datum, App-Version, Reiseinhalt und Dateianzahl prüfen.
9. Mit „Abbrechen“ schließen.
10. Google-Drive-Historie öffnen.
11. „Prüfen & wiederherstellen“ wählen.
12. „Google Drive“ und das richtige Konto prüfen.
13. Mit „Abbrechen“ schließen.
14. Normale FlorysDiaries-App öffnen und echte Daten kontrollieren.

## Git-Sicherheitsprüfung

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
git commit -m "FlorysDiaries v0.19.1 - Backup-Synchronisierung und Restore"
git tag v0.19.1

$branch = git branch --show-current
git push origin $branch
git push origin v0.19.1
```

## Release-Build

Nach erfolgreichem Push:

```powershell
flutter build apk --release
flutter build appbundle --release
```

Das Release-Update muss weiterhin mit `com.florysdiaries.app` und dem
bestehenden Upload-Keystore signiert werden. Die DEV-App bleibt separat.
