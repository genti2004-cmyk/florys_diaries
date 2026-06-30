# FlorysDiaries v1.0 – Mobile Release-Identität

## Verbindliche mobile Identität

### Release

- App-Name: `FlorysDiaries`
- Android Application ID: `com.florysdiaries.app`
- iOS Bundle Identifier: `com.florysdiaries.app`
- Karten-User-Agent: `com.florysdiaries.app`

### Entwicklung

- App-Name: `FlorysDiaries DEV`
- Android Application ID: `com.florysdiaries.app.debug`
- iOS Bundle Identifier: `com.florysdiaries.app.debug`

Die Entwicklungs-App bleibt damit getrennt von der normalen App und kann
deren Daten nicht überschreiben.

## Android

Die bestehende produktive Paketkennung bleibt unverändert. Die
Release-Signierung wird weiterhin ausschließlich über die lokale Datei
`android/key.properties` und den externen Upload-Keystore geladen.

Keine Schlüsseldatei gehört in Git oder in ein Übergabe-ZIP.

## iOS

Die alten Flutter-Platzhalter `com.example.florysDiaries` wurden entfernt.
Debug und Release besitzen getrennte Bundle Identifiers und sichtbare Namen.

Damit ist die Quellkonfiguration konsistent. Für einen echten iOS-Release
fehlen weiterhin externe Apple- und Google-Konfigurationen, insbesondere:

1. Apple Developer Team
2. Signing Certificate und Provisioning Profile
3. App-ID beziehungsweise Bundle-ID im Apple Developer Portal
4. App-Eintrag in App Store Connect
5. eigener iOS-OAuth-Client für Google Sign-In
6. erforderliches URL-Scheme beziehungsweise die von Google bereitgestellte
   iOS-Konfiguration

Diese Werte dürfen nicht geschätzt oder aus der Android-Konfiguration
abgeleitet werden.

## Karten

Weltkarte und Travel Replay verwenden jetzt dieselbe zentrale App-Kennung.
Die frühere abweichende Replay-Kennung `com.florysdiaries.travel` wurde
entfernt.

## Desktop und Web

Windows, Linux, macOS und Web sind nicht Teil des ersten mobilen v1.0-Release.
Die vorhandenen Flutter-Scaffolds bleiben deshalb in diesem Schritt
unverändert und werden nicht als Store-fertig bezeichnet.
