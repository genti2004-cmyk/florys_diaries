FlorysDiaries DEV v2.0 – Complete Travel Suite
===============================================

WICHTIG
- Dieses Paket ist ausschließlich für FlorysDiaries DEV bestimmt.
- Die normale installierte Release-App bleibt unverändert.
- Das ZIP im Projektstamm entpacken und vorhandene Dateien ersetzen.
- android/key.properties und Keystore-Dateien sind nicht enthalten und dürfen nicht überschrieben werden.

NEUE FUNKTIONEN

1. Reisebericht & PDF
- Reise → Drei-Punkte-Menü → Reisebericht & PDF
- Kompakte oder ausführliche Version
- Tagesplan, Budget, Checkliste, Dokumentenliste, Momente und Teilnehmer
- Optional bis zu vier JPG/JPEG/PNG-Reisefotos
- Originaldokumente werden nicht in den Bericht eingebettet
- PDF lokal speichern, öffnen und teilen

2. App-Schutz
- Home → Einstellungen → App-Schutz
- PIN mit 4 bis 8 Ziffern
- Optional Fingerabdruck oder Gesichtserkennung
- Gesamte App oder nur Dokumente schützen
- Automatische Sperre: sofort, 1, 5 oder 15 Minuten
- Bei Dokumentenschutz sind Öffnen, Vorschau, Teilen, Bearbeiten und Löschen geschützt
- PIN-Einstellungen werden bewusst nicht in Reise-Backups übernommen

3. Reisekasse aufteilen
- Reise → Planung → Reisekosten & Budget → Reisekasse aufteilen
- Teilnehmer hinzufügen, umbenennen und entfernen
- In einer Ausgabe festlegen: Bezahlt von / Für wen gilt die Ausgabe
- Automatische Zwischenstände und möglichst einfacher Ausgleich
- Nur bezahlte und vollständig zugeordnete Ausgaben werden berücksichtigt

4. Reise duplizieren & Vorlagen
- Reise → Drei-Punkte-Menü → Reise duplizieren
- Reise → Drei-Punkte-Menü → Als Vorlage speichern
- Home → Vorlagen
- Tagesplan, Checkliste, Budgetstruktur und Teilnehmer optional übernehmen
- Termine werden relativ zum neuen Startdatum verschoben
- Dokumente, Fotos, Momente und bezahlte Ausgaben werden nicht kopiert
- Vorlagen werden vom normalen FlorysDiaries-Backup mitgesichert

TECHNISCHE ÄNDERUNGEN
- Neue direkte Abhängigkeiten: pdf 3.12.0, local_auth 3.0.1, crypto 3.0.7
- Android-Mindestversion: SDK 24
- Android MainActivity verwendet FlutterFragmentActivity
- USE_BIOMETRIC-Berechtigung und AppCompat-Startthema ergänzt
- Teilnehmer und Kostenaufteilungen sind in lokaler Speicherung und Backups enthalten
- Zusätzliche Tests für PDF, PIN, Vorlagen, Duplizieren und Kostenaufteilung

INSTALLATION / TEST
1. ZIP vollständig in C:\Users\aliu\StudioProjects\florys_diaries entpacken.
2. Danach ausführen:

   cd C:\Users\aliu\StudioProjects\florys_diaries
   flutter pub get
   flutter analyze
   flutter test
   flutter run

MANUELLER KURZTEST
- PDF einer Reise erstellen, öffnen und teilen.
- App-Schutz mit PIN aktivieren, App in Hintergrund legen und erneut öffnen.
- Dokumentenschutz aktivieren und Dokument öffnen/bearbeiten/löschen testen.
- Zwei Teilnehmer anlegen, bezahlte Ausgabe zuordnen und Ausgleich prüfen.
- Reise duplizieren und kontrollieren, dass Dokumente/Fotos nicht kopiert werden.
- Reise als Vorlage speichern und über Home → Vorlagen neu erstellen.
- Backup erstellen und prüfen, dass Teilnehmer, Aufteilungen und Vorlagen erhalten bleiben.

PRÜFSTATUS
- Alle enthaltenen Dart-Dateien wurden syntaktisch geparst: keine Syntaxfehler.
- Alle internen package:florys_diaries-Importe wurden geprüft: keine fehlenden Dateien.
- Android-XML-Dateien wurden erfolgreich geparst.
- Flutter SDK war in der Erstellungsumgebung nicht verfügbar. Deshalb müssen flutter analyze,
  flutter test und der Gerätetest auf dem Entwicklungsrechner ausgeführt werden.
