import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/data/app_backup_service.dart';
import 'package:florys_diaries/features/backup/data/backup_file_manager.dart';
import 'package:florys_diaries/features/backup/domain/backup_integrity_level.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  late Directory testRoot;
  late Directory managedRoot;
  late AppBackupService service;

  setUp(() async {
    testRoot = await Directory.systemTemp.createTemp('florys_app_backup_test_');
    managedRoot = Directory('${testRoot.path}${Platform.pathSeparator}managed');
    await managedRoot.create(recursive: true);

    final fileService = TravelFileService(
      rootDirectoryProvider: () async => managedRoot,
    );
    service = AppBackupService(
      fileManager: BackupFileManager(fileService: fileService),
      temporaryDirectoryProvider: () async => testRoot,
    );

    addTearDown(() async {
      if (await testRoot.exists()) {
        await testRoot.delete(recursive: true);
      }
    });
  });

  test('returns only a backup that passes its own inspection', () async {
    const relativePath = 'Reisen/trip-1/documents/ticket.pdf';
    final documentFile = File(
      [
        managedRoot.path,
        ...relativePath.split('/'),
      ].join(Platform.pathSeparator),
    );
    await documentFile.parent.create(recursive: true);
    await documentFile.writeAsBytes([1, 2, 3, 4], flush: true);

    final created = await service.createBackup([
      _tripWithDocument(relativePath: relativePath, fileSizeBytes: 4),
    ]);
    final inspected = await service.inspectBackup(created.file);

    expect(await created.file.exists(), isTrue);
    expect(inspected.tripCount, 1);
    expect(inspected.fileCount, 1);
    expect(inspected.integrityLevel, BackupIntegrityLevel.sha256);
  });

  test(
    'deletes a newly created backup when a document file is missing',
    () async {
      await expectLater(
        service.createBackup([
          _tripWithDocument(
            relativePath: 'Reisen/trip-1/documents/missing.pdf',
            fileSizeBytes: 4,
          ),
        ]),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Dokumentdatei fehlt'),
          ),
        ),
      );

      final backupDirectory = Directory(
        '${testRoot.path}${Platform.pathSeparator}florys_diaries_backups',
      );
      final remainingBackups = await backupDirectory.exists()
          ? await backupDirectory
                .list()
                .where((entity) => entity is File)
                .toList()
          : const <FileSystemEntity>[];

      expect(remainingBackups, isEmpty);
    },
  );
}

Trip _tripWithDocument({
  required String relativePath,
  required int fileSizeBytes,
}) {
  return Trip(
    id: 'trip-1',
    title: 'Testreise',
    destination: 'Berlin',
    country: 'Deutschland',
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 5),
    documents: [
      TravelDocument(
        id: 'document-1',
        title: 'Ticket',
        categoryId: 'other',
        createdAt: DateTime(2026, 6, 29),
        fileName: 'ticket.pdf',
        relativePath: relativePath,
        fileSizeBytes: fileSizeBytes,
        fileExtension: 'pdf',
      ),
    ],
  );
}
