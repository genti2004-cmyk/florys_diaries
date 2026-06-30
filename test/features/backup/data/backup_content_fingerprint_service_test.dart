import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/data/backup_content_fingerprint_service.dart';
import 'package:florys_diaries/features/backup/data/backup_file_manager.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  late Directory testRoot;
  late BackupContentFingerprintService service;

  setUp(() async {
    testRoot = await Directory.systemTemp.createTemp(
      'florys_fingerprint_test_',
    );
    final managedRoot = Directory(
      '${testRoot.path}${Platform.pathSeparator}managed',
    );
    await managedRoot.create(recursive: true);

    service = BackupContentFingerprintService(
      fileManager: BackupFileManager(
        fileService: TravelFileService(
          rootDirectoryProvider: () async => managedRoot,
        ),
      ),
    );

    addTearDown(() async {
      if (await testRoot.exists()) {
        await testRoot.delete(recursive: true);
      }
    });
  });

  test('always returns a positive canonical hexadecimal fingerprint', () async {
    final fingerprint = await service.calculate([
      Trip(
        id: 'trip-1',
        title: 'Test 2',
        destination: 'Berlin',
        country: 'Deutschland',
        startDate: DateTime.utc(2026, 7, 1),
        endDate: DateTime.utc(2026, 7, 5),
      ),
    ]);

    expect(fingerprint, matches(RegExp(r'^[0-9a-f]{16}$')));
    expect(fingerprint, isNot(startsWith('-')));
  });

  test('returns the same fingerprint for unchanged content', () async {
    final first = await service.calculate(const <Trip>[]);
    final second = await service.calculate(const <Trip>[]);

    expect(second, first);
  });

  test('migrates the signed Android fingerprint to unsigned hex', () {
    expect(
      BackupContentFingerprintService.normalize('-3bf6eec27d3a7dc8'),
      'c409113d82c58238',
    );
  });

  test('rejects malformed fingerprints', () {
    expect(
      () => BackupContentFingerprintService.normalize('kein-hash'),
      throwsA(isA<FormatException>()),
    );
  });
}
