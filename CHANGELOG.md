# Changelog

## 1.0.0+7

### Erster stabiler Produktionsstand

- Versionsstand auf `1.0.0+7` angehoben.
- Release- und DEV-Anwendung bleiben durch eigene Paketkennungen und
  getrennte App-Daten vollständig voneinander isoliert.
- Android- und iOS-Release-Identitäten sind zentral dokumentiert und geprüft.
- Android-Systembackup, Geräteübertragung und Klartext-Netzwerkverkehr bleiben
  für app-interne Daten deaktiviert.
- Datenschutz- und Datenansicht beschreibt lokale Speicherung, Google Drive,
  Kartenabrufe und Löschmöglichkeiten.
- Lokale Reise-, Dokument- und Backup-Daten werden validiert, atomar
  gespeichert und bei beschädigten Dateien nicht still überschrieben.
- Lokale und Google-Drive-Backups werden vor Verwendung geprüft.
- Automatische Google-Drive-Einstellungen werden mit Rollback- und
  Wiederherstellungsdateien geschützt.
- Die stabile Oberfläche zeigt nur die funktionierenden Backup-Ziele
  „Dieses Gerät“ und „Google Drive“.
- 64-Bit-Inhaltsfingerabdrücke werden plattformstabil als positive
  Hexzeichenfolge erzeugt.
- Bereits erzeugte negative Android-Fingerabdrücke werden automatisch in die
  kanonische Darstellung migriert.
- Versions-, Plattform-, Datenschutz-, Backup- und Release-Regressionstests
  ergänzt.
- Öffentliche Anbieter-, Support- und Datenschutz-URLs bleiben externe
  Voraussetzungen und werden nicht erfunden.

## v1.0 – Vorbereitung, Teil 3

### Backup-Einstellungen und stabile Release-Oberfläche

- Automatische Google-Drive-Einstellungen werden über eine validierte
  temporäre Datei atomar gespeichert.
- Rollback- und Wiederherstellungsdateien schützen vor unterbrochenen
  Schreibvorgängen.
- Beschädigte Einstellungsdateien werden automatisch repariert, sofern ein
  gültiger Sicherheitsstand vorhanden ist.
- Sind alle Stände ungültig, wird der Fehler sichtbar gemeldet; die App fällt
  nicht still auf deaktivierte automatische Backups zurück.
- In der stabilen Oberfläche werden nur noch die funktionierenden Ziele
  „Dieses Gerät“ und „Google Drive“ angezeigt.
- Unbekannte Provider-IDs werden ausdrücklich abgelehnt und nicht still auf
  das Geräte-Backup umgeleitet.
- 64-Bit-Inhaltsfingerabdrücke plattformstabil auf eine positive,
  16-stellige Hexdarstellung umgestellt.
- Bereits gespeicherte negative Android-Fingerabdrücke werden automatisch in
  die kanonische Darstellung migriert.
- Regressionstests für Speicherung, Wiederherstellung, Provider-Liste,
  Fingerabdrücke und Release-Oberfläche ergänzt.

## v1.0 – Vorbereitung, Teil 2

### Release-Identität und mobile Plattformkonsistenz

- App-Name, Release-Paketkennung und DEV-Paketkennung zentral dokumentiert.
- Android-Buildkonfiguration verwendet eine eindeutige Release-Identität und
  weiterhin eine getrennte DEV-Anwendung.
- iOS-Platzhalter `com.example.florysDiaries` vollständig entfernt.
- iOS Release/Profile auf `com.florysdiaries.app` gesetzt.
- iOS Debug auf `com.florysdiaries.app.debug` gesetzt.
- iOS-App-Namen für Release und DEV getrennt.
- Weltkarte und Travel Replay verwenden denselben zentralen Karten-User-Agent.
- Abweichende Replay-Kennung `com.florysdiaries.travel` entfernt.
- Regressionstests für Android-, iOS- und Kartenidentität ergänzt.
- Fehlende externe Voraussetzungen für Apple-Signierung und iOS-Google-OAuth
  ausdrücklich dokumentiert.

## v1.0 – Vorbereitung, Teil 1

### Datenschutz und Android-Plattformschutz

- Android-Systembackup für app-interne Daten ausdrücklich deaktiviert.
- Separate Ausschlussregeln für Android 11 und älter ergänzt.
- Cloud-Backup und direkte Geräteübertragung für Android 12 und neuer
  ausdrücklich ausgeschlossen.
- Klartext-Netzwerkverkehr im Android-Manifest deaktiviert.
- Neue Ansicht „Datenschutz & Daten“ mit transparenter Beschreibung von
  lokaler Speicherung, Google Drive, Kartenabrufen und Löschmöglichkeiten.
- Unfertigen Hinweis auf zukünftige PIN-/Biometrie-Funktionen aus der
  stabilen Oberfläche entfernt.
- Regressionstests für Manifest, Backup-Regeln, Datenschutzansicht und
  Settings-Navigation ergänzt.
- README und Changelog auf den tatsächlich veröffentlichten Stand
  `v0.19.4+6` gebracht.

## 0.19.4+6

### Lokale Datensicherheit

- Lokale Reisedaten werden über eine geprüfte temporäre Datei atomar
  gespeichert.
- Validierte Wiederherstellungs- und Rollback-Dateien schützen vor
  unterbrochenen Schreibvorgängen.
- Beschädigte lokale Daten werden nicht mehr still als leere Reiseliste
  behandelt.
- Bei einem unsicheren Ladezustand bleiben Änderungen und automatische
  Backups gesperrt.

### Dokument- und Dateipfadsicherheit

- Dokumentdateien sind auf den geschützten FlorysDiaries-Bereich begrenzt.
- Absolute Pfade, `..`-Segmente und fremde Reiseordner werden abgelehnt.
- Dokumentdateien müssen eindeutig der zugehörigen Reise zugeordnet sein.
- Neu erzeugte Backups werden vor der Erfolgsmeldung vollständig geprüft.

### Lokale Backup-Historie

- Jede lokale Sicherung wird beim Laden vollständig geprüft.
- Beschädigte Backups werden sichtbar markiert und für die
  Wiederherstellung gesperrt.
- Gesperrte Sicherungen können weiterhin sicher gelöscht werden.
- Beschädigte automatische Backups blockieren keine neue Sicherung.

### Qualitätssicherung

- Analyse, vollständige Tests und Gerätetest in FlorysDiaries DEV bestanden.
- Signiertes APK und AAB erstellt.
- Git-Tag `v0.19.4` veröffentlicht.

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
