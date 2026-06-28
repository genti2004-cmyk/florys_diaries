import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/data/app_backup_service.dart';
import 'package:florys_diaries/features/backup/data/backup_content_fingerprint_service.dart';
import 'package:florys_diaries/features/backup/data/local_backup_service.dart';
import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  late Directory testRoot;
  late Directory backupDirectory;
  late Directory temporaryDirectory;
  late DateTime currentTime;
  late _FakeAppBackupService backupService;
  late _FakeFingerprintService fingerprintService;
  late LocalBackupService service;

  setUp(() async {
    testRoot = await Directory.systemTemp.createTemp(
      'florys_local_backup_test_',
    );
    backupDirectory = Directory(
      '${testRoot.path}${Platform.pathSeparator}backups',
    );
    temporaryDirectory = Directory(
      '${testRoot.path}${Platform.pathSeparator}temporary',
    );
    await backupDirectory.create(recursive: true);
    await temporaryDirectory.create(recursive: true);

    currentTime = DateTime(2026, 6, 28, 8);
    backupService = _FakeAppBackupService(
      temporaryDirectory: temporaryDirectory,
      clock: () => currentTime,
    );
    fingerprintService = _FakeFingerprintService(value: '1111111111111111');
    service = LocalBackupService(
      backupService: backupService,
      fingerprintService: fingerprintService,
      backupDirectoryProvider: () async => backupDirectory,
      clock: () => currentTime,
    );

    addTearDown(() async {
      if (await testRoot.exists()) {
        await testRoot.delete(recursive: true);
      }
    });
  });

  test('automatic pruning never deletes manual backups', () async {
    final manualEntries = <String>[];

    for (var index = 0; index < 2; index++) {
      currentTime = currentTime.add(const Duration(minutes: 1));
      final entry = await service.createLocalBackup(
        const <Trip>[],
        automatic: false,
      );
      manualEntries.add(entry.file.path);
    }

    for (
      var index = 0;
      index < LocalBackupService.maximumAutomaticBackups + 2;
      index++
    ) {
      currentTime = currentTime.add(const Duration(minutes: 1));
      fingerprintService.value = (index + 1).toRadixString(16).padLeft(16, '0');
      await service.createLocalBackup(const <Trip>[], automatic: true);
    }

    final entries = await service.listBackups();
    final automaticEntries = entries
        .where((entry) => entry.isAutomatic)
        .toList(growable: false);
    final remainingManualPaths = entries
        .where((entry) => !entry.isAutomatic)
        .map((entry) => entry.file.path)
        .toSet();

    expect(
      automaticEntries,
      hasLength(LocalBackupService.maximumAutomaticBackups),
    );
    expect(remainingManualPaths, containsAll(manualEntries));
    for (final path in manualEntries) {
      expect(await File(path).exists(), isTrue);
    }
  });

  test('skips an automatic backup when content has not changed', () async {
    final first = await service.createAutomaticBackupIfDue(const <Trip>[]);

    expect(first, isNotNull);
    expect(backupService.createCalls, 1);
    expect(fingerprintService.calculateCalls, 1);

    currentTime = currentTime.add(const Duration(hours: 25));
    final unchanged = await service.createAutomaticBackupIfDue(const <Trip>[]);

    expect(unchanged, isNull);
    expect(backupService.createCalls, 1);
    expect(fingerprintService.calculateCalls, 2);
  });

  test('creates a new automatic backup after content changes', () async {
    await service.createAutomaticBackupIfDue(const <Trip>[]);

    currentTime = currentTime.add(const Duration(hours: 25));
    fingerprintService.value = '2222222222222222';
    final changed = await service.createAutomaticBackupIfDue(const <Trip>[]);

    expect(changed, isNotNull);
    expect(backupService.createCalls, 2);
    expect(changed!.fileName, contains('_F2222222222222222'));
  });

  test('does not calculate a fingerprint before the interval is due', () async {
    await service.createAutomaticBackupIfDue(const <Trip>[]);

    currentTime = currentTime.add(const Duration(hours: 2));
    fingerprintService.value = '3333333333333333';
    final result = await service.createAutomaticBackupIfDue(const <Trip>[]);

    expect(result, isNull);
    expect(backupService.createCalls, 1);
    expect(fingerprintService.calculateCalls, 1);
  });

  test(
    'manual backups do not receive an automatic fingerprint suffix',
    () async {
      final entry = await service.createLocalBackup(
        const <Trip>[],
        automatic: false,
      );

      expect(entry.isAutomatic, isFalse);
      expect(entry.fileName, contains('_Lokal_'));
      expect(entry.fileName, isNot(contains('_F')));
      expect(fingerprintService.calculateCalls, 0);
    },
  );
}

class _FakeAppBackupService extends AppBackupService {
  _FakeAppBackupService({
    required this.temporaryDirectory,
    required this.clock,
  });

  final Directory temporaryDirectory;
  final DateTime Function() clock;
  int createCalls = 0;

  @override
  Future<AppBackupCreateResult> createBackup(
    List<Trip> trips, {
    String fileNamePrefix = 'FlorysDiaries_Backup',
  }) async {
    createCalls++;
    final createdAt = clock();
    final file = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}'
      'working_$createCalls.zip',
    );
    await file.writeAsBytes(<int>[createCalls, trips.length], flush: true);

    return AppBackupCreateResult(
      file: file,
      createdAt: createdAt,
      tripCount: trips.length,
      fileCount: 0,
      sizeBytes: await file.length(),
    );
  }
}

class _FakeFingerprintService extends BackupContentFingerprintService {
  _FakeFingerprintService({required this.value});

  String value;
  int calculateCalls = 0;

  @override
  Future<String> calculate(List<Trip> trips) async {
    calculateCalls++;
    return value;
  }
}
