import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/documents/application/trip_document_query.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';

void main() {
  final documents = <TravelDocument>[
    TravelDocument(
      id: 'hotel',
      title: 'Hotel Berlin',
      categoryId: DocumentCategories.hotel.id,
      createdAt: DateTime(2026, 6, 2),
      description: 'Reservierung Alexanderplatz',
      fileName: 'hotel.pdf',
      fileExtension: 'pdf',
      isFavorite: true,
    ),
    TravelDocument(
      id: 'flight',
      title: 'Flugticket',
      categoryId: DocumentCategories.flight.id,
      createdAt: DateTime(2026, 6, 3),
      description: 'Gate A12',
      fileName: 'boarding-pass.png',
      fileExtension: 'png',
    ),
    TravelDocument(
      id: 'note',
      title: 'Packliste',
      categoryId: DocumentCategories.note.id,
      createdAt: DateTime(2026, 6, 1),
      description: 'Reisepass nicht vergessen',
      isFavorite: true,
    ),
  ];

  test('filters across title, file, category and description', () {
    expect(const TripDocumentQuery(searchText: 'boarding').apply(documents), [
      documents[1],
    ]);
    expect(const TripDocumentQuery(searchText: 'hotel').apply(documents), [
      documents[0],
    ]);
    expect(const TripDocumentQuery(searchText: 'reisepass').apply(documents), [
      documents[2],
    ]);
  });

  test('combines category and favorite filters', () {
    final result = TripDocumentQuery(
      categoryId: DocumentCategories.hotel.id,
      favoritesOnly: true,
    ).apply(documents);

    expect(result, [documents[0]]);
  });

  test('supports every sort mode without mutating the source', () {
    final original = List<TravelDocument>.from(documents);

    expect(const TripDocumentQuery().apply(documents).map((item) => item.id), [
      'flight',
      'hotel',
      'note',
    ]);
    expect(
      const TripDocumentQuery(
        sortMode: DocumentSortMode.oldest,
      ).apply(documents).map((item) => item.id),
      ['note', 'hotel', 'flight'],
    );
    expect(
      const TripDocumentQuery(
        sortMode: DocumentSortMode.title,
      ).apply(documents).map((item) => item.id),
      ['flight', 'hotel', 'note'],
    );
    expect(
      const TripDocumentQuery(
        sortMode: DocumentSortMode.category,
      ).apply(documents).map((item) => item.id),
      ['flight', 'hotel', 'note'],
    );
    expect(documents, original);
  });

  test('returns an immutable result and compares query values', () {
    const query = TripDocumentQuery(searchText: 'hotel');
    final result = query.apply(documents);

    expect(() => result.add(documents.first), throwsUnsupportedError);
    expect(
      query.hasSameValues(const TripDocumentQuery(searchText: 'hotel')),
      isTrue,
    );
    expect(
      query.hasSameValues(const TripDocumentQuery(searchText: 'flug')),
      isFalse,
    );
  });
}
