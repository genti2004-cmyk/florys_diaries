import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/trips/application/trip_store.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/data/trip_storage_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/screens/trip_editor_screen.dart';

void main() {
  testWidgets('editing a trip preserves documents album checklist and photos', (
    tester,
  ) async {
    final original = _tripWithNestedContent();
    final storage = _FakeTripStorageService([original]);
    final store = TripStore(
      storageService: storage,
      now: () => DateTime(2026, 6, 29),
    );
    await store.load();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      TripStoreScope(
        store: store,
        child: MaterialApp(home: _EditorLauncher(trip: original)),
      ),
    );

    await tester.tap(find.text('Editor öffnen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('trip-editor-title')),
      'Aktualisierte Reise',
    );
    await tester.tap(find.byKey(const ValueKey<String>('trip-editor-save')));
    await tester.pumpAndSettle();

    final saved = store.trips.single;
    expect(saved.title, 'Aktualisierte Reise');
    expect(saved.documents.map((item) => item.id), ['document-1']);
    expect(saved.albumEntries.map((item) => item.id), ['album-1']);
    expect(saved.checklistItems.map((item) => item.id), ['checklist-1']);
    expect(saved.planItems.map((item) => item.id), ['plan-1']);
    expect(saved.photoCount, 7);
    expect(storage.saveCalls, 1);
    expect(find.text('Editor öffnen'), findsOneWidget);
  });

  testWidgets('back asks before unsaved trip changes are discarded', (
    tester,
  ) async {
    final storage = _FakeTripStorageService(const []);
    final store = TripStore(
      storageService: storage,
      now: () => DateTime(2026, 6, 29),
    );
    await store.load();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      TripStoreScope(
        store: store,
        child: const MaterialApp(home: _EditorLauncher()),
      ),
    );

    await tester.tap(find.text('Editor öffnen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('trip-editor-title')),
      'Noch nicht gespeichert',
    );
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Reiseänderungen verwerfen?'), findsOneWidget);
    expect(find.text('Weiter bearbeiten'), findsOneWidget);

    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();

    expect(find.byType(TripEditorScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Änderungen verwerfen'));
    await tester.pumpAndSettle();

    expect(find.text('Editor öffnen'), findsOneWidget);
    expect(store.trips, isEmpty);
  });
}

class _EditorLauncher extends StatelessWidget {
  const _EditorLauncher({this.trip});

  final Trip? trip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TripEditorScreen(trip: trip),
              ),
            );
          },
          child: const Text('Editor öffnen'),
        ),
      ),
    );
  }
}

class _FakeTripStorageService extends TripStorageService {
  _FakeTripStorageService(List<Trip> trips) : _trips = List<Trip>.from(trips);

  List<Trip> _trips;
  int saveCalls = 0;

  @override
  Future<List<Trip>> loadTrips() async => List<Trip>.from(_trips);

  @override
  Future<void> saveTrips(List<Trip> trips) async {
    saveCalls++;
    _trips = List<Trip>.from(trips);
  }
}

Trip _tripWithNestedContent() {
  return Trip(
    id: 'trip-1',
    title: 'Ursprüngliche Reise',
    destination: 'Berlin',
    country: 'Deutschland',
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 5),
    notes: 'Bestehende Notiz',
    documents: [
      TravelDocument(
        id: 'document-1',
        title: 'Flugticket',
        categoryId: DocumentCategories.flight.id,
        createdAt: DateTime(2026, 6, 1),
      ),
    ],
    albumEntries: [
      TripAlbumEntry(
        id: 'album-1',
        typeId: TripAlbumEntryTypes.highlight.id,
        date: DateTime(2026, 7, 2),
        title: 'Schöner Moment',
      ),
    ],
    checklistItems: [
      TripChecklistItem(
        id: 'checklist-1',
        title: 'Reisepass einpacken',
        category: TripChecklistCategory.documents,
        priority: TripChecklistPriority.high,
        createdAt: DateTime(2026, 6, 1),
      ),
    ],
    planItems: [
      TripPlanItem(
        id: 'plan-1',
        title: 'Stadtführung',
        date: DateTime(2026, 7, 2),
        startMinutes: 10 * 60,
        type: TripPlanItemType.sight,
      ),
    ],
    photoCount: 7,
  );
}
