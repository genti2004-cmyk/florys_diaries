import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/map/data/world_geo_lookup.dart';
import 'package:florys_diaries/features/statistics/domain/travel_statistics.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TravelStatisticsAnalyzer {
  const TravelStatisticsAnalyzer();

  TravelStatistics analyze(
    List<Trip> source, {
    int? year,
    DateTime? now,
  }) {
    final availableYears = _travelYears(source);
    final effectiveYear = year != null && availableYears.contains(year)
        ? year
        : null;
    final trips = _filterTripsByYear(source, effectiveYear);
    final normalizedCountries = <String, _GroupedTrips>{};
    final normalizedCities = <String, _GroupedTrips>{};

    final documents = <TravelDocument>[];
    var albumEntryCount = 0;
    var highlightCount = 0;
    var favoriteMomentCount = 0;
    var travelDays = 0;
    var storedPhotoCount = 0;
    Trip? longestTrip;
    Trip? shortestTrip;
    var longestTripDays = 0;
    var shortestTripDays = 0;

    for (final trip in trips) {
      final country = trip.country.trim();
      final city = trip.destination.trim();
      final tripDays = _travelDaysForTrip(trip, effectiveYear);

      if (country.isNotEmpty) {
        final countryKey = normalizeGeoName(country);
        normalizedCountries
            .putIfAbsent(countryKey, () => _GroupedTrips(label: country))
            .trips
            .add(trip);
      }
      if (country.isNotEmpty && city.isNotEmpty) {
        final cityKey =
            '${normalizeGeoName(country)}|${normalizeGeoName(city)}';
        normalizedCities
            .putIfAbsent(
              cityKey,
              () => _GroupedTrips(label: city, subtitle: country),
            )
            .trips
            .add(trip);
      }

      documents.addAll(trip.documents);
      albumEntryCount += trip.albumEntries.length;
      highlightCount += trip.albumEntries
          .where((entry) => entry.isHighlight)
          .length;
      favoriteMomentCount += trip.albumEntries
          .where((entry) => entry.isFavorite)
          .length;
      travelDays += tripDays;
      storedPhotoCount += trip.photoCount;

      if (longestTrip == null || tripDays > longestTripDays) {
        longestTrip = trip;
        longestTripDays = tripDays;
      }
      if (shortestTrip == null || tripDays < shortestTripDays) {
        shortestTrip = trip;
        shortestTripDays = tripDays;
      }
    }

    final referenceDate = _dateOnly(now ?? DateTime.now());
    final completedTripCount = trips
        .where((trip) => _tripEnd(trip).isBefore(referenceDate))
        .length;
    final upcomingTripCount = trips
        .where((trip) => _tripStart(trip).isAfter(referenceDate))
        .length;
    final activeTripCount = trips.length - completedTripCount - upcomingTripCount;

    final topCountries = _rankCountryItems(
      normalizedCountries,
      year: effectiveYear,
    );
    final topCities = _rankCityItems(
      normalizedCities,
      year: effectiveYear,
    );
    final continents = _rankContinentItems(normalizedCountries);
    final yearStats = availableYears
        .map((travelYear) => _yearStatistics(source, travelYear))
        .toList(growable: false);
    final pdfCount = documents.where(_isPdfDocument).length;
    final imageCount = documents.where(_isImageDocument).length;

    return TravelStatistics(
      selectedYear: effectiveYear,
      availableYears: List<int>.unmodifiable(availableYears),
      tripCount: trips.length,
      countryCount: normalizedCountries.length,
      cityCount: normalizedCities.length,
      worldProgressFraction: normalizedCountries.isEmpty
          ? 0
          : (normalizedCountries.length / 195).clamp(0, 1).toDouble(),
      travelDays: travelDays,
      averageTripDays: trips.isEmpty ? 0 : travelDays / trips.length,
      completedTripCount: completedTripCount,
      activeTripCount: activeTripCount,
      upcomingTripCount: upcomingTripCount,
      documentCount: documents.length,
      pdfCount: pdfCount,
      imageCount: imageCount,
      photoTotal: storedPhotoCount + imageCount,
      favoriteDocumentCount: documents
          .where((document) => document.isFavorite)
          .length,
      albumEntryCount: albumEntryCount,
      highlightCount: highlightCount,
      favoriteMomentCount: favoriteMomentCount,
      longestTripLabel: _tripDurationLabel(longestTrip, longestTripDays),
      shortestTripLabel: _tripDurationLabel(shortestTrip, shortestTripDays),
      topCountries: List<StatisticsRankItem>.unmodifiable(topCountries),
      topCities: List<StatisticsRankItem>.unmodifiable(topCities),
      continents: List<StatisticsRankItem>.unmodifiable(continents),
      years: List<YearStatistics>.unmodifiable(yearStats),
    );
  }

  static List<Trip> _filterTripsByYear(List<Trip> trips, int? year) {
    if (year == null) {
      return List<Trip>.from(trips);
    }
    return trips
        .where((trip) => _travelDaysForTrip(trip, year) > 0)
        .toList(growable: false);
  }

  static List<int> _travelYears(List<Trip> trips) {
    final years = <int>{};
    for (final trip in trips) {
      final firstYear = _tripStart(trip).year;
      final lastYear = _tripEnd(trip).year;
      for (var year = firstYear; year <= lastYear; year++) {
        years.add(year);
      }
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
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

  static List<StatisticsRankItem> _rankCountryItems(
    Map<String, _GroupedTrips> grouped, {
    required int? year,
  }) {
    final items = grouped.values.map((group) {
      final cities = group.trips
          .map((trip) => trip.destination.trim())
          .where((city) => city.isNotEmpty)
          .toSet();
      final days = group.trips.fold<int>(
        0,
        (sum, trip) => sum + _travelDaysForTrip(trip, year),
      );
      return StatisticsRankItem(
        label: group.label,
        subtitle: '${cities.length} Städte · ${_dayLabel(days)}',
        value: group.trips.length,
        valueLabel: _tripCountLabel(group.trips.length),
      );
    }).toList()..sort(_sortRankItems);
    return items;
  }

  static List<StatisticsRankItem> _rankCityItems(
    Map<String, _GroupedTrips> grouped, {
    required int? year,
  }) {
    final items = grouped.values.map((group) {
      final days = group.trips.fold<int>(
        0,
        (sum, trip) => sum + _travelDaysForTrip(trip, year),
      );
      return StatisticsRankItem(
        label: group.label,
        subtitle: '${group.subtitle} · ${_dayLabel(days)}',
        value: group.trips.length,
        valueLabel: _tripCountLabel(group.trips.length),
      );
    }).toList()..sort(_sortRankItems);
    return items;
  }

  static List<StatisticsRankItem> _rankContinentItems(
    Map<String, _GroupedTrips> groupedCountries,
  ) {
    final buckets = <String, Set<String>>{};
    for (final group in groupedCountries.values) {
      final continent = continentForCountry(group.label);
      buckets
          .putIfAbsent(continent, () => <String>{})
          .add(normalizeGeoName(group.label));
    }
    final items = buckets.entries.map((entry) {
      return StatisticsRankItem(
        label: entry.key,
        subtitle: 'Bereiste Länder in dieser Region',
        value: entry.value.length,
        valueLabel: '${entry.value.length} Länder',
      );
    }).toList()..sort(_sortRankItems);
    return items;
  }

  static YearStatistics _yearStatistics(List<Trip> source, int year) {
    final trips = _filterTripsByYear(source, year);
    final countries = trips
        .map((trip) => normalizeGeoName(trip.country))
        .where((country) => country.isNotEmpty)
        .toSet();
    final cities = trips
        .where(
          (trip) =>
              trip.country.trim().isNotEmpty &&
              trip.destination.trim().isNotEmpty,
        )
        .map(
          (trip) =>
              '${normalizeGeoName(trip.country)}|${normalizeGeoName(trip.destination)}',
        )
        .toSet();

    return YearStatistics(
      year: year,
      tripCount: trips.length,
      travelDays: trips.fold<int>(
        0,
        (sum, trip) => sum + _travelDaysForTrip(trip, year),
      ),
      countryCount: countries.length,
      cityCount: cities.length,
    );
  }

  static int _sortRankItems(StatisticsRankItem a, StatisticsRankItem b) {
    final valueCompare = b.value.compareTo(a.value);
    if (valueCompare != 0) {
      return valueCompare;
    }
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  }

  static bool _isPdfDocument(TravelDocument document) {
    return document.category.id == DocumentCategories.pdf.id ||
        document.fileExtension.trim().toLowerCase() == 'pdf';
  }

  static bool _isImageDocument(TravelDocument document) {
    final extension = document.fileExtension.trim().toLowerCase();
    return document.category.id == DocumentCategories.photo.id ||
        extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp' ||
        extension == 'heic';
  }

  static String _tripDurationLabel(Trip? trip, int days) {
    if (trip == null) {
      return 'Noch keine Reise';
    }
    return '${_tripName(trip)} · ${_dayLabel(days)}';
  }

  static String _tripName(Trip trip) {
    final title = trip.title.trim();
    if (title.isNotEmpty) {
      return title;
    }
    final city = trip.destination.trim();
    final country = trip.country.trim();
    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    }
    if (city.isNotEmpty) {
      return city;
    }
    return country.isNotEmpty ? country : 'Reise';
  }

  static String _tripCountLabel(int count) =>
      count == 1 ? '1 Reise' : '$count Reisen';

  static String _dayLabel(int days) => days == 1 ? '1 Tag' : '$days Tage';

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
}

class _GroupedTrips {
  _GroupedTrips({required this.label, this.subtitle = ''});

  final String label;
  final String subtitle;
  final List<Trip> trips = [];
}
