# FlorysDiaries

FlorysDiaries ist eine lokal zuerst arbeitende Flutter-App für Reisen,
Reisedokumente, Erinnerungen, Checklisten, Album, Statistiken, Weltkarte,
Travel Replay und geprüfte Backups.

## Aktueller Stand

- vorbereiteter Release-Stand: `v1.0.0+7`
- vorgesehener Git-Tag: `v1.0.0`
- Android-Release-Paket: `com.florysdiaries.app`
- Android-Entwicklungspaket: `com.florysdiaries.app.debug`
- iOS-Release-Bundle: `com.florysdiaries.app`
- iOS-Entwicklungs-Bundle: `com.florysdiaries.app.debug`

Die Entwicklungs-App trägt den Namen **FlorysDiaries DEV**. Ihre Daten sind
vollständig von der normalen Release-App getrennt.

## Backup-Ziele

Die stabile v1.0-Oberfläche bietet ausschließlich tatsächlich nutzbare
Sicherungsziele:

- ZIP-Datei auf diesem Gerät
- privater FlorysDiaries-App-Datenordner in Google Drive

Automatische Google-Drive-Einstellungen werden atomar gespeichert und aus
einer validierten Sicherheitskopie wiederhergestellt. Inhaltsfingerabdrücke
werden plattformstabil als positive 64-Bit-Hexwerte gespeichert, damit
identische Inhalte nicht unnötig erneut gesichert werden.

## Datenspeicherung

Reisen, Dokumentmetadaten, Album, Checklisten und zugeordnete Dateien werden
im privaten App-Bereich gespeichert. FlorysDiaries besitzt eine eigene
geprüfte Backup- und Wiederherstellungslogik.

Das Android-Systembackup sowie die direkte systemseitige Geräteübertragung
app-interner Daten sind deaktiviert. Für einen Gerätewechsel werden die
lokalen oder optionalen Google-Drive-Backups von FlorysDiaries verwendet.

## Netzwerkdienste

- Google Drive ist optional und verwendet ausschließlich den app-eigenen
  Drive-Datenbereich.
- Weltkarte und Travel Replay laden Kartenkacheln über HTTPS von
  OpenStreetMap-Kartendiensten.
- Die App enthält keine Werbung, keine Nutzungsanalyse und kein externes
  Absturz-Tracking.

## Entwicklungsprüfung

```powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

Ein normales `flutter run` installiert ausschließlich die DEV-App. Die
Release-App mit echten Nutzerdaten darf dadurch weder ersetzt noch
deinstalliert werden.

## Release-Build

Die Release-Signierung wird aus `android/key.properties` geladen. Diese Datei
und der Keystore sind lokal und dürfen niemals veröffentlicht werden.

```powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

Erwartete Ausgaben:

```text
build\app\outputs\flutter-apk\app-release.apk
build\app\outputs\bundle\release\app-release.aab
```

Der externe Upload-Keystore bleibt außerhalb des Projektordners. Für das
Release müssen Paketkennung, Versionscode und Signatur zur bestehenden
offiziellen App passen. Die normale Release-App darf bei einer
Signaturabweichung niemals deinstalliert werden.

## Öffentliche Datenschutzerklärung

Vor einer Veröffentlichung im Store muss zusätzlich eine öffentliche
Datenschutzerklärung mit echten Anbieter- und Kontaktangaben bereitgestellt
und in Play Console sowie im Google-OAuth-Projekt verknüpft werden. Technische
Grundlage dafür ist `docs/V1_0_DATENSCHUTZ_UND_STORE_CHECKLISTE.md`.
