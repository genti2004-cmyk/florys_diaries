import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/assistant/application/travel_assistant_analyzer.dart';
import 'package:florys_diaries/features/assistant/application/travel_assistant_answer_service.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  const analyzer = TravelAssistantAnalyzer();
  const service = TravelAssistantAnswerService();
  final today = DateTime(2026, 6, 27);

  group('TravelAssistantAnswerService', () {
    test('answers the next-trip question with a deterministic date', () {
      final trip = _trip(
        id: 'next',
        destination: 'Prag',
        country: 'Tschechien',
        startDate: DateTime(2026, 6, 28),
        endDate: DateTime(2026, 6, 30),
      );
      final snapshot = analyzer.analyze([trip], now: today);

      final answer = service.answer(
        question: 'Was steht als Nächstes an?',
        trips: [trip],
        snapshot: snapshot,
        now: today,
      );

      expect(answer.title, 'Prag, Tschechien');
      expect(answer.body, contains('Die Reise beginnt morgen.'));
      expect(answer.body, contains('3 Reisetage'));
      expect(answer.tripId, 'next');
    });

    test('does not claim that zero documents look good', () {
      final trip = _trip(id: 'empty-documents');
      final snapshot = analyzer.analyze([trip], now: today);

      final answer = service.answer(
        question: 'Wo fehlen Dokumente?',
        trips: [trip],
        snapshot: snapshot,
        now: today,
      );

      expect(answer.title, 'Noch keine Dokumente gespeichert');
      expect(answer.body, contains('kommende Reise'));
      expect(answer.tripId, 'empty-documents');
    });

    test('document intent takes precedence over the generic word wann', () {
      final trip = _trip(id: 'documents-first');
      final snapshot = analyzer.analyze([trip], now: today);

      final answer = service.answer(
        question: 'Wann fehlen Dokumente?',
        trips: [trip],
        snapshot: snapshot,
        now: today,
      );

      expect(answer.title, 'Noch keine Dokumente gespeichert');
    });

    test('next-trip intent takes precedence in the word Reiseziel', () {
      final trip = _trip(
        id: 'next-destination',
        destination: 'Lissabon',
        country: 'Portugal',
      );
      final snapshot = analyzer.analyze([trip], now: today);

      final answer = service.answer(
        question: 'Was ist mein nächstes Reiseziel?',
        trips: [trip],
        snapshot: snapshot,
        now: today,
      );

      expect(answer.title, 'Lissabon, Portugal');
      expect(answer.tripId, 'next-destination');
    });

    test('reports document entries without files and links the first trip', () {
      final trip = _trip(
        id: 'missing-file',
        destination: 'Wien',
        documents: [_document(id: 'booking', hasFile: false)],
      );
      final snapshot = analyzer.analyze([trip], now: today);

      final answer = service.answer(
        question: 'Prüfe meine Dateien',
        trips: [trip],
        snapshot: snapshot,
        now: today,
      );

      expect(answer.title, 'Unterlagen prüfen');
      expect(
        answer.body,
        contains('Ein Dokumenteintrag hat noch keine Datei.'),
      );
      expect(answer.body, contains('Betroffen: Wien.'));
      expect(answer.tripId, 'missing-file');
    });

    test('counts a favorite as a favorite moment', () {
      final trip = _trip(
        id: 'favorite',
        entries: [
          TripAlbumEntry(
            id: 'moment',
            typeId: TripAlbumEntryTypes.note.id,
            date: DateTime(2026, 6, 20),
            title: 'Abend am See',
            isFavorite: true,
          ),
        ],
      );
      final snapshot = analyzer.analyze([trip], now: today);

      final answer = service.answer(
        question: 'Zeig meine Favoriten',
        trips: [trip],
        snapshot: snapshot,
        now: today,
      );

      expect(answer.title, 'Abend am See');
      expect(answer.body, contains('1 Lieblingsmoment'));
      expect(answer.tripId, 'favorite');
    });

    test('uses a safe heading when destination and country are empty', () {
      final trip = _trip(
        id: 'safe-heading',
        title: 'Sommerurlaub',
        destination: ' ',
        country: '',
      );
      final snapshot = analyzer.analyze([trip], now: today);

      final answer = service.answer(
        question: 'Was steht als Nächstes an?',
        trips: [trip],
        snapshot: snapshot,
        now: today,
      );

      expect(answer.title, 'Sommerurlaub');
      expect(answer.title, isNot(contains(', ')));
    });

    test('returns a useful response for unknown questions without trips', () {
      final snapshot = analyzer.analyze(const [], now: today);

      final answer = service.answer(
        question: 'Kannst du mir helfen?',
        trips: const [],
        snapshot: snapshot,
        now: today,
      );

      expect(answer.title, 'Noch keine Reisedaten');
      expect(answer.body, contains('Lege zuerst eine Reise an'));
    });

    test('summary uses correct singular forms', () {
      final trip = _trip(id: 'single');
      final snapshot = analyzer.analyze([trip], now: today);

      final answer = service.answer(
        question: 'Meine Übersicht',
        trips: [trip],
        snapshot: snapshot,
        now: today,
      );

      expect(answer.body, startsWith('1 Reise in 1 Land'));
      expect(answer.body, contains('0 Dokumente'));
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
  List<TravelDocument> documents = const [],
  List<TripAlbumEntry> entries = const [],
}) {
  return Trip.fromJson({
    'id': id,
    'title': title,
    'destination': destination,
    'country': country,
    'startDate': (startDate ?? DateTime(2026, 7, 10)).toIso8601String(),
    'endDate': (endDate ?? DateTime(2026, 7, 14)).toIso8601String(),
    'documents': documents.map((document) => document.toJson()).toList(),
    'albumEntries': entries.map((entry) => entry.toJson()).toList(),
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
