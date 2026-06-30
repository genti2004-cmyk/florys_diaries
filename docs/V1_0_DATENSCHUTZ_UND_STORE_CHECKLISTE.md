# FlorysDiaries v1.0 – Datenschutz- und Store-Checkliste

## Technischer Datenfluss der aktuellen App

### Lokal gespeicherte Inhalte

- Reisen und Reisedaten
- Dokumentmetadaten und importierte Dokumentdateien
- Album-Einträge
- Checklisten und deren Status
- lokale Backup-Dateien
- Einstellungen für automatische Backups

Diese Inhalte liegen im privaten App-Bereich.

### Optionale Google-Dienste

Google Drive wird nur nach einer bewussten Anmeldung verwendet.

Technisch verwendet die App:

- Google Sign-In
- den OAuth-Bereich `drive.appdata`
- einen versteckten, app-eigenen Ordner im Google-Drive-Konto
- die Google-Konto-E-Mail zur sichtbaren Zuordnung in der App

Die App betreibt keinen eigenen Server, an den Reisedaten oder
Dokumentinhalte gesendet werden.

### Karten

Weltkarte und Travel Replay laden Kartenkacheln über HTTPS von
OpenStreetMap-Kartendiensten. Beim Abruf entstehen beim jeweiligen Anbieter
technisch notwendige Verbindungsdaten, insbesondere IP-Adresse, Zeitpunkt
und angeforderter Kartenausschnitt.

### Nicht enthalten

- keine Werbung
- kein Werbeprofil
- keine Nutzungsanalyse
- kein externes Crash-Reporting
- kein Entwicklerkonto innerhalb der App
- keine Standortberechtigung
- keine allgemeine Foto-, Medien- oder Speicherberechtigung

Dateien werden über den System-Dateiauswahldialog ausgewählt.

## Android-Plattformschutz

- `android:allowBackup="false"`
- Backup-Regeln für Android 11 und älter
- Datenextraktionsregeln für Android 12 und neuer
- Ausschluss von Cloud-Backup und Geräteübertragung
- `android:usesCleartextTraffic="false"`

Damit werden app-interne Reisedaten nicht zusätzlich und unkontrolliert durch
das Android-Systembackup übertragen. Die geprüften FlorysDiaries-Backups
bleiben davon unberührt.

## Vor der Veröffentlichung noch zwingend auszufüllen

Die folgenden Angaben dürfen nicht erfunden werden und fehlen deshalb
bewusst in diesem Projektpaket:

1. vollständiger Name des App-Anbieters
2. erreichbare Kontakt-E-Mail-Adresse
3. gegebenenfalls ladungsfähige Anschrift beziehungsweise erforderliche
   Anbieterkennzeichnung
4. öffentliche HTTPS-Webseite
5. öffentliche HTTPS-Adresse der Datenschutzerklärung
6. endgültiger Support-Kontakt

## Öffentliche Datenschutzerklärung

Die veröffentlichte Erklärung muss den tatsächlichen App-Stand beschreiben,
insbesondere:

- lokale Speicherung
- optionale Google-Anmeldung
- Google-Drive-Backups
- Anzeige der Konto-E-Mail
- OpenStreetMap-Kartenabrufe
- Löschung lokaler und externer Backups
- keine Werbung und keine Analyse
- Kontakt zum Verantwortlichen
- Datum und Versionsstand der Erklärung

Die URL muss anschließend mindestens an diesen Stellen hinterlegt werden:

- Google Play Store-Eintrag
- Google Play Data-Safety-Bereich
- Google-OAuth-Zustimmungsbildschirm
- öffentliche App-Webseite

## Play-Console-Prüfung

Die endgültigen Antworten im Data-Safety-Formular müssen anhand des
veröffentlichten Builds und der verwendeten Bibliotheken geprüft werden.

Technisch relevante Fakten:

- Nutzer kann Google Drive vollständig ungenutzt lassen.
- Bei Google-Anmeldung wird die Konto-E-Mail verarbeitet und in der App
  angezeigt.
- Backup-Inhalte werden nur auf Wunsch oder nach aktivierter automatischer
  Sicherung in den app-eigenen Google-Drive-Bereich hochgeladen.
- Kartenabrufe gehen an OpenStreetMap-Kartendienste.
- Es existiert kein eigener Backend-Server des App-Anbieters.
- Es existieren keine Werbe- oder Analyse-SDKs.

## OAuth-Produktionsprüfung

Vor Freigabe für beliebige Google-Konten prüfen:

- separates produktives OAuth-Projekt beziehungsweise produktive
  OAuth-Konfiguration
- Android-OAuth-Client für `com.florysdiaries.app`
- korrekte Release-SHA-1
- korrekter Web-Client für den Server-Client-ID-Eintrag
- veröffentlichter OAuth-Zustimmungsbildschirm
- verknüpfte App-Webseite und Datenschutzerklärung
- gegebenenfalls erforderliche Google-Verifizierung

Keine OAuth-Clients löschen, solange die geprüfte Debug- und
Release-Anmeldung funktioniert.
