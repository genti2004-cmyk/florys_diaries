# FlorysDiaries v0.19.0 – Prüfprotokoll

## Automatische Prüfung

Im Projektordner ausführen:

```powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

Erwartet:

- `flutter analyze`: keine Fehler
- `flutter test`: alle Tests bestanden
- `flutter run`: **FlorysDiaries DEV** startet
- Die normale **FlorysDiaries**-App bleibt installiert

## Kurzer Gerätetest

1. FlorysDiaries DEV öffnen.
2. Eine Testreise anlegen, bearbeiten und erneut öffnen.
3. Ein Testdokument hinzufügen und anzeigen.
4. Statistik und Weltkarte öffnen.
5. Einstellungen vollständig nach unten scrollen.
6. App schließen, erneut öffnen und Testreise kontrollieren.
7. Normale FlorysDiaries-App öffnen.
8. Prüfen, dass echte Reisen, Dokumente und wiederhergestellte Backups
   weiterhin vorhanden sind.

## Sicherheitskontrolle vor Git

```powershell
git status --short
git check-ignore android/key.properties
git check-ignore "C:\Users\aliu\Documents\FlorysDiaries-Keys\florysdiaries-upload.jks"
```

`android/key.properties`, `*.jks`, `*.keystore` und persönliche Backup-ZIPs
dürfen nicht als neue oder geänderte Git-Dateien erscheinen.

## Freigabe

Erst nach bestandener Analyse, vollständigen Tests und Gerätetest:

```powershell
git add .
git status --short
git commit -m "FlorysDiaries v0.19.0 – Stabilisierung und Performance"
git tag v0.19.0
git push origin main
git push origin v0.19.0
```
