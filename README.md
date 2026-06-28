# FlorysDiaries

FlorysDiaries ist eine lokal zuerst arbeitende Flutter-App für Reisen,
Reisedokumente, Erinnerungen, Statistiken, Weltkarte, Travel Replay und
Google-Drive-Backups.

## Android-Paketkennungen

- Release-App: `com.florysdiaries.app`
- Entwicklungs-App: `com.florysdiaries.app.debug`

Die Entwicklungs-App trägt auf Android den Namen **FlorysDiaries DEV**.
Ihre Daten sind vollständig von der Release-App getrennt.

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
flutter build apk --release
flutter build appbundle --release
```

Der externe Upload-Keystore bleibt außerhalb des Projektordners. Für ein
Release müssen Paketkennung, Versionscode und Signatur unverändert zur
bestehenden offiziellen App passen.

## Datensicherheit

Vor einem Restore zeigt die App die Sicherungsinformationen an. Lokale und
Google-Drive-Backups enthalten Reisedaten sowie die zugeordneten App-Dateien.
Ein neues Backup einer leeren Installation darf nicht über vorhandene
Sicherungen hinweg als Ersatz verwendet werden.

## Aktueller Meilenstein

`v0.19.0+2` – Stabilisierung, Performance, Modularisierung und
Backup-Sicherheit.
