import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/trips/data/trip_storage_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  late Directory temporaryDirectory;
  late TripStorageService storageService;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'florys_trip_storage_test_',
    );
    storageService = TripStorageService(
      documentsDirectoryProvider: () async => temporaryDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('saves validated data atomically and keeps a recovery copy', () async {
    final trips = [_trip(id: 'trip-1', title: 'Berlin')];

    await storageService.saveTrips(trips);

    final primary = _file(temporaryDirectory, 'florys_trips.json');
    final recovery = _file(temporaryDirectory, 'florys_trips.json.bak');
    final temporary = _file(temporaryDirectory, 'florys_trips.json.tmp');
    final rollback = _file(temporaryDirectory, 'florys_trips.json.rollback');

    expect(await primary.exists(), isTrue);
    expect(await recovery.exists(), isTrue);
    expect(await temporary.exists(), isFalse);
    expect(await rollback.exists(), isFalse);

    final loaded = await storageService.loadTrips();
    expect(loaded.map((trip) => trip.id), ['trip-1']);
    expect(loaded.single.title, 'Berlin');
  });

  test('recovers a corrupted primary file from the validated copy', () async {
    await storageService.saveTrips([_trip(id: 'trip-1', title: 'Prizren')]);
    final primary = _file(temporaryDirectory, 'florys_trips.json');

    await primary.writeAsString('{beschädigt', flush: true);

    final loaded = await storageService.loadTrips();

    expect(loaded.single.id, 'trip-1');
    expect(loaded.single.title, 'Prizren');

    final repairedJson = jsonDecode(await primary.readAsString());
    expect(repairedJson, isA<List<dynamic>>());
    expect((repairedJson as List<dynamic>).single['id'], 'trip-1');
  });

  test(
    'rejects invalid primary and fallback files without replacing them',
    () async {
      final primary = _file(temporaryDirectory, 'florys_trips.json');
      final recovery = _file(temporaryDirectory, 'florys_trips.json.bak');
      final rollback = _file(temporaryDirectory, 'florys_trips.json.rollback');

      await primary.writeAsString('{primary', flush: true);
      await recovery.writeAsString('{recovery', flush: true);
      await rollback.writeAsString('{rollback', flush: true);

      await expectLater(
        storageService.loadTrips(),
        throwsA(
          isA<TripStorageException>().having(
            (error) => error.message,
            'message',
            contains('nicht sicher gelesen'),
          ),
        ),
      );

      expect(await primary.readAsString(), '{primary');
      expect(await recovery.readAsString(), '{recovery');
      expect(await rollback.readAsString(), '{rollback');
    },
  );

  test(
    'rejects malformed nested data instead of silently dropping it',
    () async {
      final primary = _file(temporaryDirectory, 'florys_trips.json');
      final malformed = _trip(id: 'trip-1').toJson();
      malformed['documents'] = [
        {'id': '', 'createdAt': DateTime(2026, 6, 29).toIso8601String()},
      ];
      await primary.writeAsString(jsonEncode([malformed]), flush: true);

      await expectLater(
        storageService.loadTrips(),
        throwsA(isA<TripStorageException>()),
      );
    },
  );
  test('rejects a document path that belongs to another trip', () async {
    final valid = _trip(id: 'trip-1', title: 'Sicher');
    await storageService.saveTrips([valid]);

    final invalid = _trip(
      id: 'trip-1',
      title: 'Unsicher',
      documents: [
        _document(
          id: 'document-1',
          relativePath: 'Reisen/trip-2/documents/ticket.pdf',
        ),
      ],
    );

    await expectLater(
      storageService.saveTrips([invalid]),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('gehört nicht'),
        ),
      ),
    );

    final loaded = await storageService.loadTrips();
    expect(loaded.single.title, 'Sicher');
  });

  test('rejects duplicate document file references', () async {
    final trip = _trip(
      id: 'trip-1',
      documents: [
        _document(
          id: 'document-1',
          relativePath: 'Reisen/trip-1/documents/shared.pdf',
        ),
        _document(
          id: 'document-2',
          relativePath: 'Reisen/trip-1/documents/shared.pdf',
        ),
      ],
    );

    await expectLater(
      storageService.saveTrips([trip]),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('mehrfach referenziert'),
        ),
      ),
    );
  });

  test('rejects trip ids that map to the same file folder', () async {
    await expectLater(
      storageService.saveTrips([_trip(id: 'trip/1'), _trip(id: 'trip_1')]),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('denselben Dateiordner'),
        ),
      ),
    );
  });
}

File _file(Directory directory, String name) {
  return File('${directory.path}${Platform.pathSeparator}$name');
}

Trip _trip({
  required String id,
  String title = 'Testreise',
  List<TravelDocument> documents = const [],
}) {
  return Trip(
    id: id,
    title: title,
    destination: 'Berlin',
    country: 'Deutschland',
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 5),
    documents: documents,
  );
}

TravelDocument _document({required String id, required String relativePath}) {
  return TravelDocument(
    id: id,
    title: 'Dokument $id',
    categoryId: 'other',
    createdAt: DateTime(2026, 6, 29),
    fileName: 'ticket.pdf',
    relativePath: relativePath,
    fileSizeBytes: 4,
    fileExtension: 'pdf',
  );
}
