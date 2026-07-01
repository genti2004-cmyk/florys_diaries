import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/trips/application/trip_store.dart';
import 'package:florys_diaries/features/trips/data/trip_storage_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  final today = DateTime(2026, 6, 27);

  group('TripStore', () {
    test('starts empty when no trips have been saved', () async {
      final storage = _FakeTripStorageService();
      final store = TripStore(storageService: storage, now: () => today);

      await store.load();

      expect(store.isLoading, isFalse);
      expect(store.trips, isEmpty);
      expect(store.upcomingTrips, isEmpty);
      expect(store.pastTrips, isEmpty);
      expect(storage.loadCalls, 1);
      expect(storage.saveCalls, 0);
    });

    test('sorts once and exposes stable unmodifiable views', () async {
      final storage = _FakeTripStorageService(
        initialTrips: [
          _trip(
            id: 'future',
            startDate: DateTime(2026, 7, 10),
            endDate: DateTime(2026, 7, 12),
          ),
          _trip(
            id: 'past',
            startDate: DateTime(2026, 6, 1),
            endDate: DateTime(2026, 6, 2),
          ),
          _trip(
            id: 'running',
            startDate: DateTime(2026, 6, 25),
            endDate: DateTime(2026, 6, 27),
          ),
        ],
      );
      final store = TripStore(storageService: storage, now: () => today);

      await store.load();

      expect(store.trips.map((trip) => trip.id), ['past', 'running', 'future']);
      expect(store.pastTrips.map((trip) => trip.id), ['past']);
      expect(store.upcomingTrips.map((trip) => trip.id), ['running', 'future']);
      expect(identical(store.trips, store.trips), isTrue);
      expect(identical(store.pastTrips, store.pastTrips), isTrue);
      expect(identical(store.upcomingTrips, store.upcomingTrips), isTrue);
      expect(
        () => store.trips.add(_trip(id: 'blocked')),
        throwsUnsupportedError,
      );
    });

    test('refreshes date partitions when the calendar day changes', () async {
      var now = today;
      final storage = _FakeTripStorageService(
        initialTrips: [
          _trip(
            id: 'ends-today',
            startDate: DateTime(2026, 6, 25),
            endDate: DateTime(2026, 6, 27),
          ),
        ],
      );
      final store = TripStore(storageService: storage, now: () => now);

      await store.load();
      expect(store.upcomingTrips.single.id, 'ends-today');

      now = DateTime(2026, 6, 28);

      expect(store.upcomingTrips, isEmpty);
      expect(store.pastTrips.single.id, 'ends-today');
    });

    test('persists add, update and delete in sorted order', () async {
      final storage = _FakeTripStorageService(
        initialTrips: [
          _trip(
            id: 'existing',
            title: 'Bestehend',
            startDate: DateTime(2026, 8, 10),
            endDate: DateTime(2026, 8, 12),
          ),
        ],
      );
      final store = TripStore(storageService: storage, now: () => today);
      await store.load();
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.addTrip(
        _trip(
          id: 'new',
          title: 'Neu',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 3),
        ),
      );
      expect(storage.storedTrips.map((trip) => trip.id), ['new', 'existing']);

      await store.updateTrip(
        _trip(
          id: 'existing',
          title: 'Aktualisiert',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 4),
        ),
      );
      expect(storage.storedTrips.map((trip) => trip.id), ['existing', 'new']);
      expect(storage.storedTrips.first.title, 'Aktualisiert');

      await store.deleteTrip('new');
      expect(storage.storedTrips.map((trip) => trip.id), ['existing']);
      expect(store.trips.map((trip) => trip.id), ['existing']);
      expect(storage.saveCalls, 3);
      expect(notifications, 3);
    });

    test('rolls back an in-memory mutation when saving fails', () async {
      final original = _trip(id: 'original');
      final storage = _FakeTripStorageService(initialTrips: [original]);
      final store = TripStore(storageService: storage, now: () => today);
      await store.load();
      var notifications = 0;
      store.addListener(() => notifications++);
      storage.failNextSave = true;

      await expectLater(
        store.addTrip(_trip(id: 'not-saved')),
        throwsA(isA<StateError>()),
      );

      expect(store.trips.map((trip) => trip.id), ['original']);
      expect(storage.storedTrips.map((trip) => trip.id), ['original']);
      expect(notifications, 0);
    });

    test('keeps a load failure visible and blocks unsafe mutations', () async {
      final storage = _FakeTripStorageService(
        loadError: const TripStorageException('Lokale Daten beschädigt.'),
      );
      final store = TripStore(storageService: storage, now: () => today);

      await store.load();

      expect(store.isLoading, isFalse);
      expect(store.hasLoadError, isTrue);
      expect(store.loadErrorMessage, 'Lokale Daten beschädigt.');
      expect(store.trips, isEmpty);
      expect(
        () => store.addTrip(_trip(id: 'blocked')),
        throwsA(isA<StateError>()),
      );
      expect(storage.saveCalls, 0);
    });

    test('reload keeps the mounted app tree out of startup loading state', () async {
      final storage = _FakeTripStorageService(
        initialTrips: [_trip(id: 'before')],
      );
      final store = TripStore(storageService: storage, now: () => today);
      await store.load();

      await storage.saveTrips([_trip(id: 'after')]);
      final loadingStates = <bool>[];
      store.addListener(() => loadingStates.add(store.isLoading));

      final reload = store.reloadFromStorage();

      expect(store.isLoading, isFalse);
      await reload;

      expect(store.trips.single.id, 'after');
      expect(loadingStates, [false]);
    });

    test('clears the load error after a successful retry', () async {
      final storage = _FakeTripStorageService(
        initialTrips: [_trip(id: 'recovered')],
        loadError: const TripStorageException('Vorübergehender Lesefehler.'),
      );
      final store = TripStore(storageService: storage, now: () => today);

      await store.load();
      expect(store.hasLoadError, isTrue);

      storage.loadError = null;
      await store.reloadFromStorage();

      expect(store.hasLoadError, isFalse);
      expect(store.loadErrorMessage, isNull);
      expect(store.trips.single.id, 'recovered');
      expect(storage.loadCalls, 2);
    });

    test('ignores updates and deletes for unknown IDs', () async {
      final storage = _FakeTripStorageService(
        initialTrips: [_trip(id: 'existing')],
      );
      final store = TripStore(storageService: storage, now: () => today);
      await store.load();

      await store.updateTrip(_trip(id: 'missing'));
      await store.deleteTrip('missing');

      expect(storage.saveCalls, 0);
      expect(store.trips.map((trip) => trip.id), ['existing']);
    });
  });
}

class _FakeTripStorageService extends TripStorageService {
  _FakeTripStorageService({
    List<Trip> initialTrips = const <Trip>[],
    this.loadError,
  }) : _storedTrips = List<Trip>.from(initialTrips);

  List<Trip> _storedTrips;
  Object? loadError;
  int loadCalls = 0;
  int saveCalls = 0;
  bool failNextSave = false;

  List<Trip> get storedTrips => List<Trip>.unmodifiable(_storedTrips);

  @override
  Future<List<Trip>> loadTrips() async {
    loadCalls++;
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return List<Trip>.from(_storedTrips);
  }

  @override
  Future<void> saveTrips(List<Trip> trips) async {
    saveCalls++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Simulierter Speicherfehler');
    }
    _storedTrips = List<Trip>.from(trips);
  }
}

Trip _trip({
  required String id,
  String title = 'Testreise',
  DateTime? startDate,
  DateTime? endDate,
}) {
  final start = startDate ?? DateTime(2026, 7, 10);
  return Trip(
    id: id,
    title: title,
    destination: 'Berlin',
    country: 'Deutschland',
    startDate: start,
    endDate: endDate ?? start.add(const Duration(days: 2)),
  );
}
