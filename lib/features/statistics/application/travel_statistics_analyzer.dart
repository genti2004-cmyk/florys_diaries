import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/map/data/world_geo_lookup.dart';
import 'package:florys_diaries/features/statistics/domain/travel_statistics.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TravelStatisticsAnalyzer {
  const TravelStatisticsAnalyzer();

  TravelStatistics analyze(List<Trip> trips) {
    final normalizedCountries = <String, _GroupedTrips>{};
    final normalizedCities = <String, _GroupedTrips>{};
    final years = <int, _YearBucket>{};

    final documents = <TravelDocument>[];
    var albumEntryCount = 0;
    var highlightCount = 0;
    var favoriteMomentCount = 0;
    var travelDays = 0;
    var storedPhotoCount = 0;
    Trip? longestTrip;
    Trip? shortestTrip;

    for (final trip in trips) {
      final country = trip.country.trim();
      final city = trip.destination.trim();

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

      years
          .putIfAbsent(
            trip.startDate.year,
            () => _YearBucket(trip.startDate.year),
          )
          .trips
          .add(trip);

      documents.addAll(trip.documents);
      albumEntryCount += trip.albumEntries.length;
      highlightCount += trip.albumEntries
          .where((entry) => entry.isHighlight)
          .length;
      favoriteMomentCount += trip.albumEntries
          .where((entry) => entry.isFavorite)
          .length;
      travelDays += trip.durationDays;
      storedPhotoCount += trip.photoCount;

      if (longestTrip == null || trip.durationDays > longestTrip.durationDays) {
        longestTrip = trip;
      }
      if (shortestTrip == null ||
          trip.durationDays < shortestTrip.durationDays) {
        shortestTrip = trip;
      }
    }

    final topCountries = _rankCountryItems(normalizedCountries);
    final topCities = _rankCityItems(normalizedCities);
    final continents = _rankContinentItems(normalizedCountries);
    final yearStats = years.values.map((bucket) => bucket.toStat()).toList()
      ..sort((a, b) => b.year.compareTo(a.year));
    final pdfCount = documents.where(_isPdfDocument).length;
    final imageCount = documents.where(_isImageDocument).length;

    return TravelStatistics(
      tripCount: trips.length,
      countryCount: normalizedCountries.length,
      cityCount: normalizedCities.length,
      worldProgressFraction: normalizedCountries.isEmpty
          ? 0
          : (normalizedCountries.length / 195).clamp(0, 1).toDouble(),
      travelDays: travelDays,
      averageTripDays: trips.isEmpty ? 0 : travelDays / trips.length,
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
      longestTripLabel: _tripDurationLabel(longestTrip),
      shortestTripLabel: _tripDurationLabel(shortestTrip),
      topCountries: List<StatisticsRankItem>.unmodifiable(topCountries),
      topCities: List<StatisticsRankItem>.unmodifiable(topCities),
      continents: List<StatisticsRankItem>.unmodifiable(continents),
      years: List<YearStatistics>.unmodifiable(yearStats),
    );
  }

  static List<StatisticsRankItem> _rankCountryItems(
    Map<String, _GroupedTrips> grouped,
  ) {
    final items = grouped.values.map((group) {
      final cities = group.trips
          .map((trip) => trip.destination.trim())
          .where((city) => city.isNotEmpty)
          .toSet();
      final days = group.trips.fold<int>(
        0,
        (sum, trip) => sum + trip.durationDays,
      );
      return StatisticsRankItem(
        label: group.label,
        subtitle: '${cities.length} Städte · $days Tage',
        value: group.trips.length,
        valueLabel: '${group.trips.length} Reisen',
      );
    }).toList()..sort(_sortRankItems);
    return items;
  }

  static List<StatisticsRankItem> _rankCityItems(
    Map<String, _GroupedTrips> grouped,
  ) {
    final items = grouped.values.map((group) {
      final days = group.trips.fold<int>(
        0,
        (sum, trip) => sum + trip.durationDays,
      );
      return StatisticsRankItem(
        label: group.label,
        subtitle: '${group.subtitle} · $days Tage',
        value: group.trips.length,
        valueLabel: '${group.trips.length} Reisen',
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

  static String _tripDurationLabel(Trip? trip) {
    if (trip == null) {
      return 'Noch keine Reise';
    }
    return '${_tripName(trip)} · ${trip.durationDays} Tage';
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
}

class _GroupedTrips {
  _GroupedTrips({required this.label, this.subtitle = ''});

  final String label;
  final String subtitle;
  final List<Trip> trips = [];
}

class _YearBucket {
  _YearBucket(this.year);

  final int year;
  final List<Trip> trips = [];

  YearStatistics toStat() {
    final countries = trips
        .map((trip) => trip.country.trim())
        .where((country) => country.isNotEmpty)
        .toSet();
    final cities = trips
        .map((trip) => trip.destination.trim())
        .where((city) => city.isNotEmpty)
        .toSet();
    return YearStatistics(
      year: year,
      tripCount: trips.length,
      travelDays: trips.fold<int>(0, (sum, trip) => sum + trip.durationDays),
      countryCount: countries.length,
      cityCount: cities.length,
    );
  }
}
