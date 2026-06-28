# Changelog

## 0.19.1+3

### Automatische Backup-Synchronisierung

- Lokale und Google-Drive-Backup-Prüfungen zentral gebündelt.
- Änderungen werden nach kurzer Verzögerung automatisch geprüft.
- Beim Wechsel in den Hintergrund wird eine sofortige Prüfung ausgelöst.
- Beim Fortsetzen der App wird der Sicherungsstatus erneut geprüft.
- Fehler eines Backup-Kanals blockieren den jeweils anderen Kanal nicht.
- Weiterhin entstehen keine unnötigen identischen automatischen Backups.

### Sichtbarer Backup-Status

- Neue Statuskarte für lokale und Google-Drive-Sicherungen.
- Anzeige für „Vorgemerkt“, „Prüfung läuft“, „Aktuell“,
  „Anmeldung erforderlich“ und „Fehlgeschlagen“.
- Zeitpunkt der letzten abgeschlossenen automatischen Prüfung sichtbar.
- Statusänderungen werden während der App-Nutzung live angezeigt.

### Sichere Wiederherstellung

- Backup-Inhalte werden vor jeder Wiederherstellung vollständig geprüft.
- Vorschau zeigt Backup-Datum, App-Version und Archivgröße.
- Reiseanzahl, Länder, Reiseziele und gesamter Reisezeitraum werden angezeigt.
- Dokumente, Albumeinträge, Checklistenpunkte und Archivdateien werden gezählt.
- Deutlicher Hinweis, dass der aktuelle App-Inhalt ersetzt wird.
- Lokale und Google-Drive-Sicherungen verwenden einheitlich
  „Prüfen & wiederherstellen“.
- Herkunft der Sicherung wird angezeigt.
- Bei Google Drive wird das verwendete Konto angezeigt.
- Bei lokalen Sicherungen ist „Manuell“ oder „Automatisch“ sichtbar.

### Tests

- Tests für Backup-Koordination, Statusverwaltung, schmale Displays,
  Wiederherstellungsdetails und einheitliche Restore-Aktionen ergänzt.
- Analyse ohne Fehler.
- Alle automatischen Tests bestanden.
- Gerätetest in FlorysDiaries DEV bestanden.

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
