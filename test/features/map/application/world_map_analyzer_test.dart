import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/map/application/world_map_analyzer.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  const analyzer = WorldMapAnalyzer();

  test('returns a complete empty snapshot', () {
    final snapshot = analyzer.analyze(const <Trip>[]);

    expect(snapshot.years, isEmpty);
    expect(snapshot.trips, isEmpty);
    expect(snapshot.countries, isEmpty);
    expect(snapshot.cities, isEmpty);
    expect(snapshot.routes, isEmpty);
    expect(snapshot.continents, isEmpty);
    expect(snapshot.travelDays, 0);
    expect(snapshot.progressPercent, 0);
  });

  test('groups country and city names case-insensitively', () {
    final snapshot = analyzer.analyze([
      Trip(
        id: 'berlin-one',
        title: 'Berlin 1',
        destination: 'Berlin',
        country: 'Deutschland',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 2),
      ),
      Trip(
        id: 'berlin-two',
        title: 'Berlin 2',
        destination: 'BERLIN',
        country: 'deutschland',
        startDate: DateTime(2025, 2, 1),
        endDate: DateTime(2025, 2, 1),
      ),
      Trip(
        id: 'paris',
        title: 'Paris',
        destination: 'Paris',
        country: 'Frankreich',
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 3, 3),
      ),
    ]);

    expect(snapshot.tripCount, 3);
    expect(snapshot.countryCount, 2);
    expect(snapshot.cityCount, 2);
    expect(snapshot.countries.first.country, 'Deutschland');
    expect(snapshot.countries.first.tripCount, 2);
    expect(snapshot.countries.first.cityCount, 1);
    expect(snapshot.routes, hasLength(1));
    expect(snapshot.routes.single.fromCity, 'BERLIN');
    expect(snapshot.routes.single.toCity, 'Paris');
  });

  test('includes a multi-year trip in every affected year', () {
    final trip = Trip(
      id: 'long-trip',
      title: 'Lange Reise',
      destination: 'Reykjavik',
      country: 'Island',
      startDate: DateTime(2023, 12, 30),
      endDate: DateTime(2025, 1, 2),
    );

    final allYears = analyzer.analyze([trip]);
    final middleYear = analyzer.analyze([trip], year: 2024);

    expect(allYears.years, [2025, 2024, 2023]);
    expect(middleYear.trips, [trip]);
    expect(middleYear.countryCount, 1);
    expect(middleYear.cityCount, 1);
  });

  test('does not mutate source data and exposes immutable lists', () {
    final first = Trip(
      id: 'first',
      title: 'First',
      destination: 'Rom',
      country: 'Italien',
      startDate: DateTime(2025, 2, 1),
      endDate: DateTime(2025, 2, 2),
    );
    final second = Trip(
      id: 'second',
      title: 'Second',
      destination: 'Paris',
      country: 'Frankreich',
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 1, 2),
    );
    final source = <Trip>[first, second];

    final snapshot = analyzer.analyze(source);

    expect(source, [first, second]);
    expect(() => snapshot.trips.add(first), throwsUnsupportedError);
    expect(
      () => snapshot.countries.add(snapshot.countries.first),
      throwsUnsupportedError,
    );
    expect(
      () => snapshot.routes.add(snapshot.routes.first),
      throwsUnsupportedError,
    );
  });
}
