class TravelStatistics {
  const TravelStatistics({
    required this.selectedYear,
    required this.availableYears,
    required this.tripCount,
    required this.countryCount,
    required this.cityCount,
    required this.worldProgressFraction,
    required this.travelDays,
    required this.averageTripDays,
    required this.completedTripCount,
    required this.activeTripCount,
    required this.upcomingTripCount,
    required this.documentCount,
    required this.pdfCount,
    required this.imageCount,
    required this.photoTotal,
    required this.favoriteDocumentCount,
    required this.albumEntryCount,
    required this.highlightCount,
    required this.favoriteMomentCount,
    required this.longestTripLabel,
    required this.shortestTripLabel,
    required this.topCountries,
    required this.topCities,
    required this.continents,
    required this.years,
  });

  final int? selectedYear;
  final List<int> availableYears;
  final int tripCount;
  final int countryCount;
  final int cityCount;
  final double worldProgressFraction;
  final int travelDays;
  final double averageTripDays;
  final int completedTripCount;
  final int activeTripCount;
  final int upcomingTripCount;
  final int documentCount;
  final int pdfCount;
  final int imageCount;
  final int photoTotal;
  final int favoriteDocumentCount;
  final int albumEntryCount;
  final int highlightCount;
  final int favoriteMomentCount;
  final String longestTripLabel;
  final String shortestTripLabel;
  final List<StatisticsRankItem> topCountries;
  final List<StatisticsRankItem> topCities;
  final List<StatisticsRankItem> continents;
  final List<YearStatistics> years;

  String get periodLabel => selectedYear == null
      ? 'Alle Jahre'
      : selectedYear.toString();

  String get worldPercentLabel =>
      '${(worldProgressFraction * 100).toStringAsFixed(1)} %';

  String get averageTripDaysLabel {
    if (tripCount == 0) {
      return '0 Tage';
    }
    return '${averageTripDays.toStringAsFixed(1)} Tage';
  }

  String get topCountryLabel => topCountries.isEmpty
      ? 'Noch kein Land'
      : '${topCountries.first.label} · ${topCountries.first.valueLabel}';

  String get topCityLabel => topCities.isEmpty
      ? 'Noch keine Stadt'
      : '${topCities.first.label} · ${topCities.first.valueLabel}';
}

class StatisticsRankItem {
  const StatisticsRankItem({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.valueLabel,
  });

  final String label;
  final String subtitle;
  final int value;
  final String valueLabel;
}

class YearStatistics {
  const YearStatistics({
    required this.year,
    required this.tripCount,
    required this.travelDays,
    required this.countryCount,
    required this.cityCount,
  });

  final int year;
  final int tripCount;
  final int travelDays;
  final int countryCount;
  final int cityCount;
}
