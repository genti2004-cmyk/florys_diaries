# FlorysDiaries v1.0 – Backup-Einstellungen und Provider

## Automatische Google-Drive-Einstellungen

Die Konfiguration wird in einer eigenen JSON-Datei im privaten
App-Support-Bereich gespeichert.

Gespeichert werden:

- aktiviert oder deaktiviert
- Sicherungsintervall
- maximale Zahl automatischer Cloud-Backups
- Zeitpunkt der letzten erfolgreichen Sicherung
- Zeitpunkt der letzten Prüfung
- Fingerabdruck des zuletzt gesicherten Inhalts

## Schutz vor unterbrochenen Schreibvorgängen

Der Speichervorgang verwendet:

1. eine temporäre, vollständig validierte Datei
2. eine Rollback-Datei des bisherigen Stands
3. eine validierte Wiederherstellungsdatei
4. atomaren Austausch der Hauptdatei

Eine beschädigte Hauptdatei wird automatisch aus Rollback oder
Wiederherstellungsdatei repariert.

Sind alle vorhandenen Dateien ungültig, fällt die App nicht still auf
„Automatische Sicherung deaktiviert“ zurück. Der Zustand wird als Fehler
gemeldet und die vorhandenen Dateien werden nicht überschrieben.

## Backup-Ziele in v1.0

In der stabilen App sichtbar und funktionsfähig:

- Dieses Gerät
- Google Drive

Nicht funktionierende Zukunfts-Platzhalter werden in v1.0 nicht angezeigt.
OneDrive und Dropbox können später als vollständig getestete Funktionen
ergänzt werden, gehören aber nicht zur ersten stabilen Veröffentlichung.

## Provider-Routing

Eine unbekannte oder nicht freigegebene Provider-ID wird ausdrücklich
abgelehnt. Die App fällt nicht mehr still auf „Dieses Gerät“ zurück. Dadurch
kann ein falsches Ziel nicht unbemerkt als lokales Backup ausgeführt werden.
