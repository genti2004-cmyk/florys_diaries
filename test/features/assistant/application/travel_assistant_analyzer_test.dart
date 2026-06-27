import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/assistant/application/travel_assistant_analyzer.dart';
import 'package:florys_diaries/features/assistant/domain/travel_assistant_models.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  const analyzer = TravelAssistantAnalyzer();
  final today = DateTime(2026, 6, 27);

  group('TravelAssistantAnalyzer', () {
    test('returns a stable empty snapshot', () {
      final snapshot = analyzer.analyze(const [], now: today);

      expect(snapshot.tripCount, 0);
      expect(snapshot.upcomingCount, 0);
      expect(snapshot.pastCount, 0);
      expect(snapshot.nextTrip, isNull);
      expect(snapshot.nextTripReadiness, 0);
      expect(snapshot.insights, hasLength(1));
      expect(snapshot.insights.single.id, 'empty');
      expect(snapshot.insights.single.priority, TravelAssistantPriority.high);
    });

    test(
      'separates past, running and future trips using the supplied date',
      () {
        final past = _trip(
          id: 'past',
          startDate: DateTime(2026, 6, 20),
          endDate: DateTime(2026, 6, 26),
        );
        final running = _trip(
          id: 'running',
          startDate: DateTime(2026, 6, 25),
          endDate: DateTime(2026, 6, 28),
        );
        final future = _trip(
          id: 'future',
          startDate: DateTime(2026, 7, 3),
          endDate: DateTime(2026, 7, 8),
        );

        final snapshot = analyzer.analyze([future, past, running], now: today);

        expect(snapshot.tripCount, 3);
        expect(snapshot.pastCount, 1);
        expect(snapshot.upcomingCount, 2);
        expect(snapshot.nextTrip?.id, 'running');
      },
    );

    test('counts normalized countries, files, memories and favorites', () {
      final trips = [
        _trip(
          id: 'one',
          country: ' Deutschland ',
          documents: [
            _document(id: 'file', hasFile: true),
            _document(id: 'missing', hasFile: false),
          ],
          entries: [
            _entry(id: 'highlight', highlight: true),
            _entry(id: 'favorite', favorite: true),
          ],
          photoCount: 8,
        ),
        _trip(
          id: 'two',
          country: 'deutschland',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 3),
          photoCount: 2,
        ),
      ];

      final snapshot = analyzer.analyze(trips, now: today);

      expect(snapshot.countryCount, 1);
      expect(snapshot.documentCount, 2);
      expect(snapshot.fileCount, 1);
      expect(snapshot.memoryCount, 2);
      expect(snapshot.highlightCount, 2);
      expect(snapshot.photoCount, 10);
    });

    test('uses the trip title when destination is empty', () {
      final trip = _trip(
        id: 'fallback',
        title: 'Familienreise',
        destination: '   ',
        notes: '',
        startDate: DateTime(2026, 7, 2),
        endDate: DateTime(2026, 7, 5),
      );

      final snapshot = analyzer.analyze([trip], now: today);
      final titles = snapshot.insights.map((insight) => insight.title).toList();

      expect(titles, contains('Unterlagen für Familienreise fehlen'));
      expect(titles, contains('Plan für Familienreise ergänzen'));
    });

    test('does not request a highlight when a favorite already exists', () {
      final trip = _trip(
        id: 'favorite-trip',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 4),
        entries: [_entry(id: 'favorite', favorite: true)],
      );

      final snapshot = analyzer.analyze([trip], now: today);

      expect(
        snapshot.insights.any(
          (insight) => insight.id == 'highlight-favorite-trip',
        ),
        isFalse,
      );
      expect(snapshot.highlightCount, 1);
    });

    test('calculates full readiness for a completely prepared next trip', () {
      final trip = _trip(
        id: 'ready',
        notes: 'Alles vorbereitet',
        documents: [_document(id: 'ticket', hasFile: true)],
        entries: [_entry(id: 'note')],
      );

      final snapshot = analyzer.analyze([trip], now: today);

      expect(snapshot.nextTripReadiness, 100);
      expect(snapshot.readinessLabel, 'Sehr gut vorbereitet');
    });

    test('keeps recommendations bounded for a large trip collection', () {
      final trips = List.generate(
        100,
        (index) => _trip(
          id: 'trip-$index',
          title: 'Reise $index',
          destination: 'Ziel $index',
          startDate: DateTime(2026, 7, 1 + index),
          endDate: DateTime(2026, 7, 2 + index),
        ),
      );

      final snapshot = analyzer.analyze(trips, now: today);

      expect(snapshot.tripCount, 100);
      expect(snapshot.insights.length, lessThanOrEqualTo(8));
    });
  });
}

Trip _trip({
  required String id,
  String title = 'Testreise',
  String destination = 'Berlin',
  String country = 'Deutschland',
  DateTime? startDate,
  DateTime? endDate,
  String notes = '',
  List<TravelDocument> documents = const [],
  List<TripAlbumEntry> entries = const [],
  int photoCount = 0,
}) {
  return Trip.fromJson({
    'id': id,
    'title': title,
    'destination': destination,
    'country': country,
    'startDate': (startDate ?? DateTime(2026, 7, 10)).toIso8601String(),
    'endDate': (endDate ?? DateTime(2026, 7, 14)).toIso8601String(),
    'notes': notes,
    'documents': documents.map((document) => document.toJson()).toList(),
    'albumEntries': entries.map((entry) => entry.toJson()).toList(),
    'photoCount': photoCount,
    'checklistItemCount': 0,
    'checklistCompletedCount': 0,
  });
}

TravelDocument _document({required String id, required bool hasFile}) {
  return TravelDocument(
    id: id,
    title: 'Dokument $id',
    categoryId: 'other',
    createdAt: DateTime(2026, 6, 1),
    relativePath: hasFile ? 'documents/$id.pdf' : '',
  );
}

TripAlbumEntry _entry({
  required String id,
  bool highlight = false,
  bool favorite = false,
}) {
  return TripAlbumEntry(
    id: id,
    typeId: highlight
        ? TripAlbumEntryTypes.highlight.id
        : TripAlbumEntryTypes.note.id,
    date: DateTime(2026, 6, 1),
    title: 'Eintrag $id',
    isFavorite: favorite,
  );
}
