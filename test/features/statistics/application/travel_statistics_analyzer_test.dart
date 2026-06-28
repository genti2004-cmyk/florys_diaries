import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/statistics/application/travel_statistics_analyzer.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  const analyzer = TravelStatisticsAnalyzer();

  test('returns a complete empty state', () {
    final statistics = analyzer.analyze(const <Trip>[]);

    expect(statistics.tripCount, 0);
    expect(statistics.countryCount, 0);
    expect(statistics.cityCount, 0);
    expect(statistics.travelDays, 0);
    expect(statistics.averageTripDays, 0);
    expect(statistics.documentCount, 0);
    expect(statistics.photoTotal, 0);
    expect(statistics.worldProgressFraction, 0);
    expect(statistics.worldPercentLabel, '0.0 %');
    expect(statistics.averageTripDaysLabel, '0 Tage');
    expect(statistics.longestTripLabel, 'Noch keine Reise');
    expect(statistics.shortestTripLabel, 'Noch keine Reise');
    expect(statistics.topCountryLabel, 'Noch kein Land');
    expect(statistics.topCityLabel, 'Noch keine Stadt');
    expect(statistics.topCountries, isEmpty);
    expect(statistics.topCities, isEmpty);
    expect(statistics.continents, isEmpty);
    expect(statistics.years, isEmpty);
  });

  test('aggregates trips, documents, memories and yearly records', () {
    final trips = <Trip>[
      Trip(
        id: 'berlin',
        title: 'Berlin Wochenende',
        destination: 'Berlin',
        country: 'Deutschland',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 3),
        photoCount: 2,
        documents: [
          TravelDocument(
            id: 'pdf',
            title: 'Buchung',
            categoryId: DocumentCategories.pdf.id,
            createdAt: DateTime(2025, 1, 1),
            fileExtension: 'pdf',
            isFavorite: true,
          ),
          TravelDocument(
            id: 'photo',
            title: 'Screenshot',
            categoryId: DocumentCategories.photo.id,
            createdAt: DateTime(2025, 1, 1),
            fileExtension: 'png',
          ),
        ],
        albumEntries: [
          TripAlbumEntry(
            id: 'highlight',
            typeId: TripAlbumEntryTypes.highlight.id,
            date: DateTime(2025, 1, 2),
            title: 'Museum',
            isFavorite: true,
          ),
        ],
      ),
      Trip(
        id: 'munich',
        title: '',
        destination: 'München',
        country: 'Deutschland',
        startDate: DateTime(2025, 2, 10),
        endDate: DateTime(2025, 2, 11),
        photoCount: 1,
        albumEntries: [
          TripAlbumEntry(
            id: 'note',
            typeId: TripAlbumEntryTypes.note.id,
            date: DateTime(2025, 2, 10),
            title: 'Notiz',
          ),
        ],
      ),
      Trip(
        id: 'rome',
        title: '',
        destination: 'Rom',
        country: 'Italien',
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 1),
        documents: [
          TravelDocument(
            id: 'jpeg',
            title: 'Foto',
            categoryId: DocumentCategories.other.id,
            createdAt: DateTime(2024, 6, 1),
            fileExtension: 'JPEG',
          ),
        ],
      ),
    ];

    final statistics = analyzer.analyze(trips);

    expect(statistics.tripCount, 3);
    expect(statistics.countryCount, 2);
    expect(statistics.cityCount, 3);
    expect(statistics.travelDays, 6);
    expect(statistics.averageTripDays, 2);
    expect(statistics.documentCount, 3);
    expect(statistics.pdfCount, 1);
    expect(statistics.imageCount, 2);
    expect(statistics.photoTotal, 5);
    expect(statistics.favoriteDocumentCount, 1);
    expect(statistics.albumEntryCount, 2);
    expect(statistics.highlightCount, 1);
    expect(statistics.favoriteMomentCount, 1);
    expect(statistics.longestTripLabel, 'Berlin Wochenende · 3 Tage');
    expect(statistics.shortestTripLabel, 'Rom, Italien · 1 Tage');

    expect(statistics.topCountries.first.label, 'Deutschland');
    expect(statistics.topCountries.first.value, 2);
    expect(statistics.topCountries.first.valueLabel, '2 Reisen');
    expect(statistics.topCountryLabel, 'Deutschland · 2 Reisen');

    expect(statistics.topCities.map((item) => item.label), [
      'Berlin',
      'München',
      'Rom',
    ]);
    expect(statistics.topCityLabel, 'Berlin · 1 Reisen');

    expect(statistics.continents, hasLength(1));
    expect(statistics.continents.single.label, 'Europa');
    expect(statistics.continents.single.value, 2);

    expect(statistics.years.map((item) => item.year), [2025, 2024]);
    expect(statistics.years.first.tripCount, 2);
    expect(statistics.years.first.travelDays, 5);
    expect(statistics.years.first.countryCount, 1);
    expect(statistics.years.first.cityCount, 2);
  });

  test('groups country and city names case-insensitively', () {
    final statistics = analyzer.analyze([
      Trip(
        id: 'one',
        title: 'One',
        destination: 'Berlin',
        country: 'Deutschland',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 1),
      ),
      Trip(
        id: 'two',
        title: 'Two',
        destination: 'BERLIN',
        country: 'deutschland',
        startDate: DateTime(2025, 2, 1),
        endDate: DateTime(2025, 2, 1),
      ),
    ]);

    expect(statistics.countryCount, 1);
    expect(statistics.cityCount, 1);
    expect(statistics.topCountries.single.value, 2);
    expect(statistics.topCities.single.value, 2);
  });

  test('does not mutate the source list and exposes immutable results', () {
    final first = Trip(
      id: 'first',
      title: 'First',
      destination: 'Paris',
      country: 'Frankreich',
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 1, 2),
    );
    final second = Trip(
      id: 'second',
      title: 'Second',
      destination: 'Rom',
      country: 'Italien',
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 1),
    );
    final source = <Trip>[first, second];

    final statistics = analyzer.analyze(source);

    expect(source, [first, second]);
    expect(
      () => statistics.topCountries.add(statistics.topCountries.first),
      throwsUnsupportedError,
    );
    expect(
      () => statistics.years.add(statistics.years.first),
      throwsUnsupportedError,
    );
  });
}
