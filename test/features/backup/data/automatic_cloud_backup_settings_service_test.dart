import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/data/automatic_cloud_backup_settings_service.dart';
import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';

void main() {
  late Directory testDirectory;
  late AutomaticCloudBackupSettingsService service;

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'florys_cloud_settings_test_',
    );
    service = AutomaticCloudBackupSettingsService(
      supportDirectoryProvider: () async => testDirectory,
    );

    addTearDown(() async {
      if (await testDirectory.exists()) {
        await testDirectory.delete(recursive: true);
      }
    });
  });

  test('returns defaults when no settings were stored', () async {
    final loaded = await service.load();

    expect(loaded.enabled, isFalse);
    expect(
      loaded.intervalDays,
      AutomaticCloudBackupSettings.defaultIntervalDays,
    );
    expect(
      loaded.retentionLimit,
      AutomaticCloudBackupSettings.defaultRetentionLimit,
    );
  });

  test('saves and loads a validated settings file', () async {
    final settings = AutomaticCloudBackupSettings.defaults.copyWith(
      enabled: true,
      intervalDays: 7,
      retentionLimit: 10,
      lastSuccessfulBackupAt: DateTime.utc(2026, 6, 30, 10),
      lastCheckedAt: DateTime.utc(2026, 6, 30, 11),
      lastContentFingerprint: '0123456789abcdef',
    );

    await service.save(settings);
    final loaded = await service.load();

    expect(loaded.enabled, isTrue);
    expect(loaded.intervalDays, 7);
    expect(loaded.retentionLimit, 10);
    expect(loaded.lastContentFingerprint, '0123456789abcdef');
  });

  test('recovers a damaged primary file from the validated backup', () async {
    final settings = AutomaticCloudBackupSettings.defaults.copyWith(
      enabled: true,
      intervalDays: 1,
      retentionLimit: 5,
      lastContentFingerprint: '1111111111111111',
    );
    await service.save(settings);

    final primary = _settingsFile(testDirectory);
    await primary.writeAsString('{ beschädigt', flush: true);

    final loaded = await service.load();

    expect(loaded.enabled, isTrue);
    expect(loaded.intervalDays, 1);
    expect(loaded.lastContentFingerprint, '1111111111111111');

    final repairedJson = jsonDecode(await primary.readAsString());
    expect(repairedJson['enabled'], isTrue);
  });

  test(
    'does not silently disable backups when every file is invalid',
    () async {
      final primary = _settingsFile(testDirectory);
      final recovery = File('${primary.path}.bak');

      await primary.writeAsString('{ ungültig', flush: true);
      await recovery.writeAsString(
        jsonEncode(<String, Object?>{
          'enabled': 'kein bool',
          'intervalDays': 3,
          'retentionLimit': 5,
        }),
        flush: true,
      );

      await expectLater(
        service.load(),
        throwsA(
          isA<AutomaticCloudBackupSettingsException>().having(
            (error) => error.message,
            'message',
            contains('nicht sicher gelesen'),
          ),
        ),
      );

      expect(await primary.readAsString(), '{ ungültig');
    },
  );

  test('rejects unsupported interval and retention values', () async {
    final primary = _settingsFile(testDirectory);
    await primary.writeAsString(
      jsonEncode(<String, Object?>{
        'enabled': true,
        'intervalDays': 2,
        'retentionLimit': 99,
        'lastSuccessfulBackupAt': null,
        'lastCheckedAt': null,
        'lastContentFingerprint': null,
      }),
      flush: true,
    );

    await expectLater(
      service.load(),
      throwsA(isA<AutomaticCloudBackupSettingsException>()),
    );
  });

  test(
    'migrates a signed legacy fingerprint and saves it canonically',
    () async {
      final primary = _settingsFile(testDirectory);
      await primary.writeAsString(
        jsonEncode(<String, Object?>{
          'enabled': true,
          'intervalDays': 3,
          'retentionLimit': 10,
          'lastSuccessfulBackupAt': null,
          'lastCheckedAt': null,
          'lastContentFingerprint': '-3bf6eec27d3a7dc8',
        }),
        flush: true,
      );

      final loaded = await service.load();

      expect(loaded.enabled, isTrue);
      expect(loaded.lastContentFingerprint, 'c409113d82c58238');

      await service.save(loaded);
      final saved = jsonDecode(await primary.readAsString());

      expect(saved['lastContentFingerprint'], 'c409113d82c58238');
    },
  );
}

File _settingsFile(Directory directory) {
  return File(
    '${directory.path}${Platform.pathSeparator}'
    'florys_diaries_automatic_cloud_backup.json',
  );
}
