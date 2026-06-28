# Changelog

## 0.19.0+2

### Stabilität und Architektur

- Reise-Speicher und Aktualisierungsabläufe stabilisiert.
- Statistik-Auswertung in klar getrennte Analyse-, Modell- und UI-Module
  aufgeteilt.
- Weltkarten-Auswertung und Kartenoberfläche modularisiert.
- Reise-Detailansicht und Dokumentzuordnung robuster gegen fehlende Dateien
  gemacht.
- Einstellungen in kleinere, separat testbare Widgets und Formatierer
  aufgeteilt.

### Backup und Wiederherstellung

- Lokale manuelle und automatische Backups getrennt verwaltet.
- Inhaltsfingerabdruck verhindert unnötige identische automatische Backups.
- Backup-Archive werden vor einer Wiederherstellung vollständig geprüft.
- Referenzierte Dateien müssen im Archiv vorhanden und lesbar sein.
- Restore-Dateioperationen verwenden einen sichereren Rollback-Ablauf.
- Google-Drive-Backup-Historie und automatische Sicherung bleiben erhalten.

### Android und Datensicherheit

- Release-App und Entwicklungs-App besitzen getrennte Paketkennungen.
- `flutter run` installiert `com.florysdiaries.app.debug` als
  **FlorysDiaries DEV**.
- Die offizielle Release-App bleibt unter `com.florysdiaries.app`.
- Release-Signierung bleibt an den externen Upload-Keystore gebunden.
- Git-Schutz für `key.properties`, Keystores und persönliche Backup-Archive
  verstärkt.

### Tests

- Tests für Reise-Speicher, Statistiken, Weltkarte, Dokumentabfragen,
  Backup-Archive, Restore-Dateiverwaltung, lokale Backups und
  Einstellungsoberfläche ergänzt beziehungsweise erweitert.
