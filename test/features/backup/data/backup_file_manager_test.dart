import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/data/backup_file_manager.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/trips/data/trip_storage_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  late Directory testRoot;
  late Directory localRoot;
  late Directory stagedFiles;
  late Trip originalTrip;
  late Trip restoredTrip;

  setUp(() async {
    testRoot = await Directory.systemTemp.createTemp(
      'florys_backup_manager_test_',
    );
    localRoot = Directory('${testRoot.path}${Platform.pathSeparator}local');
    stagedFiles = Directory('${testRoot.path}${Platform.pathSeparator}staged');
    await localRoot.create(recursive: true);
    await stagedFiles.create(recursive: true);

    await File(
      '${localRoot.path}${Platform.pathSeparator}original.txt',
    ).writeAsString('original', flush: true);
    await File(
      '${stagedFiles.path}${Platform.pathSeparator}restored.txt',
    ).writeAsString('restored', flush: true);

    originalTrip = _trip('original');
    restoredTrip = _trip('restored');

    addTearDown(() async {
      if (await testRoot.exists()) {
        await testRoot.delete(recursive: true);
      }
    });
  });

  test('a failed initial rename leaves original data untouched', () async {
    final storage = _FakeTripStorageService([originalTrip]);
    final manager = BackupFileManager(
      fileService: _TestTravelFileService(localRoot),
      storageService: storage,
      directoryRenamer: (source, targetPath) async {
        throw const FileSystemException('Umbenennen fehlgeschlagen.');
      },
    );

    await expectLater(
      manager.replaceLocalData(
        restoredTrips: [restoredTrip],
        stagedFiles: stagedFiles,
        stamp: 101,
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(
      await File(
        '${localRoot.path}${Platform.pathSeparator}original.txt',
      ).readAsString(),
      'original',
    );
    expect(
      File(
        '${localRoot.path}${Platform.pathSeparator}restored.txt',
      ).existsSync(),
      isFalse,
    );
    expect(storage.savedTrips.single.id, 'original');
    expect(storage.saveCalls, 0);
  });

  test('a copy failure restores the original file directory', () async {
    final storage = _FakeTripStorageService([originalTrip]);
    final manager = _FailingCopyBackupFileManager(
      fileService: _TestTravelFileService(localRoot),
      storageService: storage,
    );

    await expectLater(
      manager.replaceLocalData(
        restoredTrips: [restoredTrip],
        stagedFiles: stagedFiles,
        stamp: 102,
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(
      await File(
        '${localRoot.path}${Platform.pathSeparator}original.txt',
      ).readAsString(),
      'original',
    );
    expect(
      File(
        '${localRoot.path}${Platform.pathSeparator}restored.txt',
      ).existsSync(),
      isFalse,
    );
    expect(storage.savedTrips.single.id, 'original');
    expect(storage.saveCalls, 0);
  });

  test('a metadata save failure rolls files and trips back', () async {
    final storage = _FakeTripStorageService(
      [originalTrip],
      failingSaveCalls: {1},
    );
    final manager = BackupFileManager(
      fileService: _TestTravelFileService(localRoot),
      storageService: storage,
    );

    await expectLater(
      manager.replaceLocalData(
        restoredTrips: [restoredTrip],
        stagedFiles: stagedFiles,
        stamp: 103,
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(
      await File(
        '${localRoot.path}${Platform.pathSeparator}original.txt',
      ).readAsString(),
      'original',
    );
    expect(
      File(
        '${localRoot.path}${Platform.pathSeparator}restored.txt',
      ).existsSync(),
      isFalse,
    );
    expect(storage.savedTrips.single.id, 'original');
    expect(storage.saveCalls, 2);
  });

  test('a failed rollback reports that manual checking is required', () async {
    final storage = _FakeTripStorageService(
      [originalTrip],
      failingSaveCalls: {1, 2},
    );
    final manager = BackupFileManager(
      fileService: _TestTravelFileService(localRoot),
      storageService: storage,
    );

    await expectLater(
      manager.replaceLocalData(
        restoredTrips: [restoredTrip],
        stagedFiles: stagedFiles,
        stamp: 104,
      ),
      throwsA(
        isA<FileSystemException>().having(
          (error) => error.message,
          'message',
          contains('nicht vollständig zurückgesetzt'),
        ),
      ),
    );

    expect(
      await File(
        '${localRoot.path}${Platform.pathSeparator}original.txt',
      ).readAsString(),
      'original',
    );
    expect(storage.saveCalls, 2);
  });

  test('missing staged files abort before local data is changed', () async {
    final storage = _FakeTripStorageService([originalTrip]);
    final manager = BackupFileManager(
      fileService: _TestTravelFileService(localRoot),
      storageService: storage,
    );
    final missingStaging = Directory(
      '${testRoot.path}${Platform.pathSeparator}missing',
    );

    await expectLater(
      manager.replaceLocalData(
        restoredTrips: [restoredTrip],
        stagedFiles: missingStaging,
        stamp: 105,
      ),
      throwsA(isA<FileSystemException>()),
    );

    expect(
      await File(
        '${localRoot.path}${Platform.pathSeparator}original.txt',
      ).readAsString(),
      'original',
    );
    expect(storage.saveCalls, 0);
  });
}

Trip _trip(String id) {
  return Trip(
    id: id,
    title: id,
    destination: 'Berlin',
    country: 'Deutschland',
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2026, 6, 2),
  );
}

class _TestTravelFileService extends TravelFileService {
  _TestTravelFileService(this.directory);

  final Directory directory;

  @override
  Future<Directory> rootDirectory() async => directory;
}

class _FakeTripStorageService extends TripStorageService {
  _FakeTripStorageService(
    List<Trip> initialTrips, {
    this.failingSaveCalls = const {},
  }) : savedTrips = List<Trip>.from(initialTrips);

  final Set<int> failingSaveCalls;
  List<Trip> savedTrips;
  int saveCalls = 0;

  @override
  Future<List<Trip>> loadTrips() async {
    return List<Trip>.from(savedTrips);
  }

  @override
  Future<void> saveTrips(List<Trip> trips) async {
    saveCalls++;
    if (failingSaveCalls.contains(saveCalls)) {
      throw FileSystemException('Speichern fehlgeschlagen: $saveCalls');
    }
    savedTrips = List<Trip>.from(trips);
  }
}

class _FailingCopyBackupFileManager extends BackupFileManager {
  _FailingCopyBackupFileManager({
    required super.fileService,
    required super.storageService,
  });

  @override
  Future<BackupCopySummary> copyDirectoryContents(
    Directory source,
    Directory target,
  ) async {
    throw const FileSystemException('Kopieren fehlgeschlagen.');
  }
}
