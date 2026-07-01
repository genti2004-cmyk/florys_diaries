import 'package:florys_diaries/features/map/data/world_geo_lookup.dart';
import 'package:florys_diaries/features/map/domain/map_visit_models.dart';
import 'package:florys_diaries/features/map/domain/world_map_snapshot.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class WorldMapAnalyzer {
  const WorldMapAnalyzer();

  WorldMapSnapshot analyze(List<Trip> source, {int? year}) {
    final years = _travelYears(source);
    final effectiveYear = year != null && years.contains(year) ? year : null;
    final trips = _filterTripsByYear(source, effectiveYear);
    final countries = _buildCountryVisits(trips, year: effectiveYear);
    final cities = _buildCityVisits(
      trips,
      countries,
      year: effectiveYear,
    );
    final routes = _buildTravelRoutes(trips, year: effectiveYear);
    final continents = _buildContinentStats(countries);
    final travelDays = trips.fold<int>(
      0,
      (sum, trip) => sum + _travelDaysForTrip(trip, effectiveYear),
    );

    return WorldMapSnapshot(
      years: List<int>.unmodifiable(years),
      trips: List<Trip>.unmodifiable(trips),
      countries: List<CountryVisit>.unmodifiable(countries),
      cities: List<CityVisit>.unmodifiable(cities),
      routes: List<TravelRoute>.unmodifiable(routes),
      continents: List<ContinentStat>.unmodifiable(continents),
      travelDays: travelDays,
      progressPercent: countries.isEmpty
          ? 0
          : (countries.length / 195 * 100).clamp(0, 100).toDouble(),
    );
  }

  static List<Trip> _filterTripsByYear(List<Trip> trips, int? year) {
    if (year == null) {
      return List<Trip>.from(trips);
    }

    return trips
        .where((trip) {
          final startYear = trip.startDate.year;
          final endYear = trip.endDate.year;
          final firstYear = startYear <= endYear ? startYear : endYear;
          final lastYear = startYear <= endYear ? endYear : startYear;
          return year >= firstYear && year <= lastYear;
        })
        .toList(growable: false);
  }

  static List<int> _travelYears(List<Trip> trips) {
    final years = <int>{};

    for (final trip in trips) {
      final startYear = trip.startDate.year;
      final endYear = trip.endDate.year;
      final firstYear = startYear <= endYear ? startYear : endYear;
      final lastYear = startYear <= endYear ? endYear : startYear;

      for (var year = firstYear; year <= lastYear; year++) {
        years.add(year);
      }
    }

    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  static List<CountryVisit> _buildCountryVisits(
    List<Trip> trips, {
    required int? year,
  }) {
    final grouped = <String, _CountryBucket>{};

    for (final trip in trips) {
      final country = trip.country.trim();
      if (country.isEmpty) {
        continue;
      }

      final key = normalizeGeoName(country);
      grouped
          .putIfAbsent(key, () => _CountryBucket(label: country))
          .trips
          .add(trip);
    }

    final visits = grouped.values
        .map((bucket) {
          final cities = _uniqueValues(
            bucket.trips.map((trip) => trip.destination),
          );

          return CountryVisit(
            country: bucket.label,
            tripCount: bucket.trips.length,
            cityCount: cities.length,
            travelDays: bucket.trips.fold<int>(
              0,
              (sum, trip) => sum + _travelDaysForTrip(trip, year),
            ),
            documentCount: bucket.trips.fold<int>(
              0,
              (sum, trip) => sum + trip.documents.length,
            ),
            highlightCount: bucket.trips.fold<int>(
              0,
              (sum, trip) => sum + trip.highlightCount,
            ),
            cities: List<String>.unmodifiable(cities),
            position: countryPosition(bucket.label),
            continent: continentForCountry(bucket.label),
          );
        })
        .toList(growable: false);

    visits.sort((a, b) {
      final countComparison = b.tripCount.compareTo(a.tripCount);
      if (countComparison != 0) {
        return countComparison;
      }
      return a.country.toLowerCase().compareTo(b.country.toLowerCase());
    });

    return visits;
  }

  static List<CityVisit> _buildCityVisits(
    List<Trip> trips,
    List<CountryVisit> countries, {
    required int? year,
  }) {
    final countryByName = {
      for (final country in countries)
        normalizeGeoName(country.country): country,
    };
    final grouped = <String, _CityBucket>{};

    for (final trip in trips) {
      final country = trip.country.trim();
      final city = trip.destination.trim();
      if (country.isEmpty || city.isEmpty) {
        continue;
      }

      final key = '${normalizeGeoName(country)}|${normalizeGeoName(city)}';
      grouped
          .putIfAbsent(key, () => _CityBucket(country: country, city: city))
          .trips
          .add(trip);
    }

    final cities = grouped.values
        .map((bucket) {
          final countryVisit = countryByName[normalizeGeoName(bucket.country)];

          return CityVisit(
            city: bucket.city,
            country: bucket.country,
            tripCount: bucket.trips.length,
            travelDays: bucket.trips.fold<int>(
              0,
              (sum, trip) => sum + _travelDaysForTrip(trip, year),
            ),
            documentCount: bucket.trips.fold<int>(
              0,
              (sum, trip) => sum + trip.documents.length,
            ),
            highlightCount: bucket.trips.fold<int>(
              0,
              (sum, trip) => sum + trip.highlightCount,
            ),
            position: cityPosition(
              bucket.country,
              bucket.city,
              countryVisit?.position,
            ),
          );
        })
        .toList(growable: false);

    cities.sort((a, b) {
      final countryComparison = a.country.toLowerCase().compareTo(
        b.country.toLowerCase(),
      );
      if (countryComparison != 0) {
        return countryComparison;
      }
      return a.city.toLowerCase().compareTo(b.city.toLowerCase());
    });

    return cities;
  }

  static List<TravelRoute> _buildTravelRoutes(
    List<Trip> trips, {
    required int? year,
  }) {
    final sortedTrips =
        trips
            .where(
              (trip) =>
                  trip.country.trim().isNotEmpty &&
                  trip.destination.trim().isNotEmpty,
            )
            .toList()
          ..sort((a, b) {
            final dateComparison = a.startDate.compareTo(b.startDate);
            if (dateComparison != 0) {
              return dateComparison;
            }
            return a.id.compareTo(b.id);
          });

    final routes = <TravelRoute>[];

    for (var index = 1; index < sortedTrips.length; index++) {
      final previous = sortedTrips[index - 1];
      final current = sortedTrips[index];

      if (_samePlace(previous, current)) {
        continue;
      }

      routes.add(
        TravelRoute(
          id: '${previous.id}_${current.id}_$index',
          tripId: current.id,
          tripTitle: _tripTitle(current),
          fromCity: previous.destination.trim(),
          fromCountry: previous.country.trim(),
          toCity: current.destination.trim(),
          toCountry: current.country.trim(),
          fromPosition: cityPosition(
            previous.country,
            previous.destination,
            countryPosition(previous.country),
          ),
          toPosition: cityPosition(
            current.country,
            current.destination,
            countryPosition(current.country),
          ),
          date: current.startDate,
          travelDays: _travelDaysForTrip(current, year),
          documentCount: current.documents.length,
          highlightCount: current.highlightCount,
        ),
      );
    }

    return routes;
  }

  static List<ContinentStat> _buildContinentStats(
    List<CountryVisit> countries,
  ) {
    final stats = <String, int>{};

    for (final country in countries) {
      stats[country.continent] = (stats[country.continent] ?? 0) + 1;
    }

    final result = stats.entries
        .map((entry) => ContinentStat(name: entry.key, count: entry.value))
        .toList();

    result.sort((a, b) {
      final countComparison = b.count.compareTo(a.count);
      if (countComparison != 0) {
        return countComparison;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return result;
  }

  static int _travelDaysForTrip(Trip trip, int? year) {
    final start = _tripStart(trip);
    final end = _tripEnd(trip);
    if (year == null) {
      return _inclusiveDays(start, end);
    }

    final yearStart = DateTime(year);
    final yearEnd = DateTime(year, 12, 31);
    final overlapStart = start.isAfter(yearStart) ? start : yearStart;
    final overlapEnd = end.isBefore(yearEnd) ? end : yearEnd;
    if (overlapStart.isAfter(overlapEnd)) {
      return 0;
    }
    return _inclusiveDays(overlapStart, overlapEnd);
  }

  static DateTime _tripStart(Trip trip) {
    final start = _dateOnly(trip.startDate);
    final end = _dateOnly(trip.endDate);
    return start.isBefore(end) ? start : end;
  }

  static DateTime _tripEnd(Trip trip) {
    final start = _dateOnly(trip.startDate);
    final end = _dateOnly(trip.endDate);
    return start.isAfter(end) ? start : end;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _inclusiveDays(DateTime start, DateTime end) {
    final utcStart = DateTime.utc(start.year, start.month, start.day);
    final utcEnd = DateTime.utc(end.year, end.month, end.day);
    return utcEnd.difference(utcStart).inDays + 1;
  }

  static List<String> _uniqueValues(Iterable<String> values) {
    final labelsByKey = <String, String>{};

    for (final value in values) {
      final label = value.trim();
      if (label.isEmpty) {
        continue;
      }
      labelsByKey.putIfAbsent(normalizeGeoName(label), () => label);
    }

    return labelsByKey.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  static bool _samePlace(Trip a, Trip b) {
    return normalizeGeoName(a.country) == normalizeGeoName(b.country) &&
        normalizeGeoName(a.destination) == normalizeGeoName(b.destination);
  }

  static String _tripTitle(Trip trip) {
    final title = trip.title.trim();
    if (title.isNotEmpty) {
      return title;
    }
    return '${trip.destination.trim()}, ${trip.country.trim()}';
  }
}

class _CountryBucket {
  _CountryBucket({required this.label});

  final String label;
  final List<Trip> trips = [];
}

class _CityBucket {
  _CityBucket({required this.country, required this.city});

  final String country;
  final String city;
  final List<Trip> trips = [];
}
