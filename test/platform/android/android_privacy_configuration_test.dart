import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest disables unmanaged backups and cleartext traffic', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });

  test('legacy backup rules exclude every supported app-data domain', () {
    final rules = File(
      'android/app/src/main/res/xml/backup_rules.xml',
    ).readAsStringSync();

    expect(rules, contains('<full-backup-content>'));
    _expectAllDomainsExcluded(rules);
  });

  test('Android 12 rules exclude cloud and device-transfer data', () {
    final rules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();

    expect(rules, contains('<cloud-backup>'));
    expect(rules, contains('<device-transfer>'));

    final sections = <String>[
      _section(rules, 'cloud-backup'),
      _section(rules, 'device-transfer'),
    ];
    for (final section in sections) {
      _expectAllDomainsExcluded(section);
    }
  });
}

void _expectAllDomainsExcluded(String xml) {
  for (final domain in <String>[
    'root',
    'file',
    'database',
    'sharedpref',
    'external',
    'device_root',
    'device_file',
    'device_database',
    'device_sharedpref',
  ]) {
    expect(
      xml,
      contains('<exclude domain="$domain" path="." />'),
      reason: 'Backup-Domain $domain ist nicht vollständig ausgeschlossen.',
    );
  }
}

String _section(String xml, String name) {
  final match = RegExp('<$name>([\\s\\S]*?)</$name>').firstMatch(xml);
  expect(match, isNotNull, reason: 'XML-Abschnitt <$name> fehlt.');
  return match!.group(1)!;
}
