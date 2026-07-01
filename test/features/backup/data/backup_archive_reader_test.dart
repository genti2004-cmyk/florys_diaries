import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/data/backup_archive_reader.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  const reader = BackupArchiveReader();
  late Directory testRoot;

  setUp(() async {
    testRoot = await Directory.systemTemp.createTemp(
      'florys_backup_reader_test_',
    );
    addTearDown(() async {
      if (await testRoot.exists()) {
        await testRoot.delete(recursive: true);
      }
    });
  });

  test('reads a valid backup with a referenced document file', () async {
    final trip = _tripWithDocument();
    final backup = await _createBackup(
      testRoot,
      trips: [trip],
      files: {
        'Reisen/trip-1/documents/ticket.pdf': [1, 2, 3, 4],
      },
    );

    final package = await reader.read(backup);

    expect(package.trips, hasLength(1));
    expect(package.trips.single.id, 'trip-1');
    expect(package.fileEntries, hasLength(1));
  });

  test('rejects a damaged zip file with a format error', () async {
    final backup = File('${testRoot.path}${Platform.pathSeparator}bad.zip');
    await backup.writeAsBytes([1, 2, 3, 4, 5], flush: true);

    await expectLater(reader.read(backup), throwsA(isA<FormatException>()));
  });

  test('rejects a referenced document whose file is missing', () async {
    final backup = await _createBackup(
      testRoot,
      trips: [_tripWithDocument()],
      files: const {},
    );

    await expectLater(
      reader.read(backup),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Dokumentdatei fehlt'),
        ),
      ),
    );
  });

  test('rejects contradictory manifest counts', () async {
    final backup = await _createBackup(
      testRoot,
      trips: [_tripWithoutDocument()],
      files: const {},
      declaredTripCount: 2,
    );

    await expectLater(
      reader.read(backup),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Reiseanzahl'),
        ),
      ),
    );
  });

  test('rejects malformed nested entries instead of dropping them', () async {
    final tripJson = _tripWithoutDocument().toJson();
    tripJson['documents'] = ['kein gültiger Dokumenteintrag'];

    final backup = await _createBackup(
      testRoot,
      trips: const [],
      rawTripEntries: [tripJson],
      files: const {},
      declaredTripCount: 1,
    );

    await expectLater(
      reader.read(backup),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Dokument'),
        ),
      ),
    );
  });

  test('rejects duplicate nested ids before restore', () async {
    final tripJson = _tripWithoutDocument().toJson();
    tripJson['albumEntries'] = [
      {
        'id': 'album-1',
        'typeId': 'note',
        'date': '2026-07-01T00:00:00.000',
        'title': 'Erster Eintrag',
      },
      {
        'id': 'album-1',
        'typeId': 'highlight',
        'date': '2026-07-02T00:00:00.000',
        'title': 'Doppelter Eintrag',
      },
    ];

    final backup = await _createBackup(
      testRoot,
      trips: const [],
      rawTripEntries: [tripJson],
      files: const {},
      declaredTripCount: 1,
    );

    await expectLater(
      reader.read(backup),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Album-Eintrag-ID'),
        ),
      ),
    );
  });

  test('preserves nested trip content during backup inspection', () async {
    final tripJson = _tripWithoutDocument().toJson();
    tripJson['albumEntries'] = [
      {
        'id': 'album-1',
        'typeId': 'highlight',
        'date': '2026-07-01T00:00:00.000',
        'title': 'Lieblingsmoment',
        'description': 'Beschreibung',
        'location': 'Prizren',
        'isFavorite': true,
      },
    ];
    tripJson['checklistItems'] = [
      {
        'id': 'checklist-1',
        'title': 'Reisepass',
        'category': 'documents',
        'priority': 'high',
        'createdAt': '2026-06-01T00:00:00.000',
        'notes': 'Nicht vergessen',
        'dueDate': '2026-06-28T00:00:00.000',
        'isCompleted': true,
        'sourceKey': 'passport',
      },
    ];
    tripJson['planItems'] = [
      {
        'id': 'plan-1',
        'title': 'Altstadt-Rundgang',
        'date': '2026-07-01T00:00:00.000',
        'startMinutes': 600,
        'endMinutes': 720,
        'type': 'sight',
        'location': 'Prizren',
        'notes': 'Kamera mitnehmen',
        'isCompleted': false,
      },
    ];
    tripJson['photoCount'] = 9;

    final backup = await _createBackup(
      testRoot,
      trips: const [],
      rawTripEntries: [tripJson],
      files: const {},
      declaredTripCount: 1,
    );

    final package = await reader.read(backup);
    final restored = package.trips.single;

    expect(restored.albumEntries.single.id, 'album-1');
    expect(restored.albumEntries.single.isFavorite, isTrue);
    expect(restored.checklistItems.single.id, 'checklist-1');
    expect(restored.checklistItems.single.sourceKey, 'passport');
    expect(restored.checklistItems.single.isCompleted, isTrue);
    expect(restored.planItems.single.id, 'plan-1');
    expect(restored.planItems.single.title, 'Altstadt-Rundgang');
    expect(restored.planItems.single.startMinutes, 600);
    expect(restored.photoCount, 9);
  });
  test('rejects a document path assigned to the wrong trip', () async {
    final original = _tripWithDocument();
    final wrongDocument = original.documents.single.copyWith(
      relativePath: 'Reisen/trip-2/documents/ticket.pdf',
    );
    final trip = original.copyWith(documents: [wrongDocument]);
    final backup = await _createBackup(
      testRoot,
      trips: [trip],
      files: {
        'Reisen/trip-2/documents/ticket.pdf': [1, 2, 3, 4],
      },
    );

    await expectLater(
      reader.read(backup),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('gehört nicht'),
        ),
      ),
    );
  });

  test('rejects a document file referenced more than once', () async {
    final original = _tripWithDocument();
    final duplicate = original.documents.single.copyWith(
      id: 'document-2',
      title: 'Zweites Ticket',
    );
    final trip = original.copyWith(
      documents: [original.documents.single, duplicate],
    );
    final backup = await _createBackup(
      testRoot,
      trips: [trip],
      files: {
        'Reisen/trip-1/documents/ticket.pdf': [1, 2, 3, 4],
      },
    );

    await expectLater(
      reader.read(backup),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('mehrfach referenziert'),
        ),
      ),
    );
  });

  test('rejects contradictory document file sizes', () async {
    final original = _tripWithDocument();
    final wrongSize = original.documents.single.copyWith(fileSizeBytes: 99);
    final trip = original.copyWith(documents: [wrongSize]);
    final backup = await _createBackup(
      testRoot,
      trips: [trip],
      files: {
        'Reisen/trip-1/documents/ticket.pdf': [1, 2, 3, 4],
      },
    );

    await expectLater(
      reader.read(backup),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Dateigröße'),
        ),
      ),
    );
  });
}

Trip _tripWithDocument() {
  return Trip(
    id: 'trip-1',
    title: 'Testreise',
    destination: 'Berlin',
    country: 'Deutschland',
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2026, 6, 3),
    documents: [
      TravelDocument(
        id: 'document-1',
        title: 'Ticket',
        categoryId: 'other',
        createdAt: DateTime(2026, 5, 1),
        fileName: 'ticket.pdf',
        relativePath: 'Reisen/trip-1/documents/ticket.pdf',
        fileSizeBytes: 4,
        fileExtension: 'pdf',
      ),
    ],
  );
}

Trip _tripWithoutDocument() {
  return Trip(
    id: 'trip-2',
    title: 'Ohne Dokument',
    destination: 'Hamburg',
    country: 'Deutschland',
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 2),
  );
}

Future<File> _createBackup(
  Directory testRoot, {
  required List<Trip> trips,
  required Map<String, List<int>> files,
  List<Object?>? rawTripEntries,
  int? declaredTripCount,
}) async {
  final workspace = Directory(
    '${testRoot.path}${Platform.pathSeparator}'
    'workspace_${DateTime.now().microsecondsSinceEpoch}',
  );
  await workspace.create(recursive: true);

  final contentBytes = files.values.fold<int>(
    0,
    (sum, bytes) => sum + bytes.length,
  );
  final manifest = {
    'format': BackupArchiveReader.formatId,
    'schemaVersion': BackupArchiveReader.schemaVersion,
    'appVersion': '0.18.2',
    'createdAt': DateTime.utc(2026, 6, 28).toIso8601String(),
    'tripCount': declaredTripCount ?? rawTripEntries?.length ?? trips.length,
    'fileCount': files.length,
    'contentBytes': contentBytes,
  };

  await File(
    '${workspace.path}${Platform.pathSeparator}manifest.json',
  ).writeAsString(jsonEncode(manifest), flush: true);
  await File(
    '${workspace.path}${Platform.pathSeparator}trips.json',
  ).writeAsString(
    jsonEncode(rawTripEntries ?? trips.map((trip) => trip.toJson()).toList()),
    flush: true,
  );

  for (final entry in files.entries) {
    final pathParts = entry.key.split('/');
    final file = File(
      [workspace.path, 'files', ...pathParts].join(Platform.pathSeparator),
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value, flush: true);
  }

  final backup = File(
    '${testRoot.path}${Platform.pathSeparator}'
    'backup_${DateTime.now().microsecondsSinceEpoch}.zip',
  );
  final encoder = ZipFileEncoder();
  encoder.create(backup.path);
  await encoder.addDirectory(workspace, includeDirName: false);
  encoder.closeSync();
  await workspace.delete(recursive: true);
  return backup;
}
