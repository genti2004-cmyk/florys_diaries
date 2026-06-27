import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/app_section_title.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/map/data/world_geo_lookup.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final insights = _TravelInsights.fromTrips(store.trips);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const AppSectionTitle(
            title: 'World Statistics Pro',
            subtitle:
                'Länder, Städte, Reisetage und Erinnerungen aus deinen echten Reisen.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _HeroStatsCard(insights: insights),
                const SizedBox(height: 14),
                _WorldProgressCard(insights: insights),
                const SizedBox(height: 14),
                _TravelRecordsCard(insights: insights),
                const SizedBox(height: 14),
                _RankPanel(
                  title: 'Meistbesuchte Länder',
                  emptyText: 'Noch keine Länder erfasst.',
                  items: insights.topCountries,
                ),
                const SizedBox(height: 14),
                _RankPanel(
                  title: 'Meistbesuchte Städte',
                  emptyText: 'Noch keine Städte erfasst.',
                  items: insights.topCities,
                ),
                const SizedBox(height: 14),
                _ContinentPanel(items: insights.continents),
                const SizedBox(height: 14),
                _YearPanel(items: insights.years),
                const SizedBox(height: 14),
                _VaultMemoryPanel(insights: insights),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({required this.insights});

  final _TravelInsights insights;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.18,
      children: [
        _StatTile(
          icon: Icons.flight_takeoff_rounded,
          label: 'Reisen',
          value: insights.tripCount.toString(),
        ),
        _StatTile(
          icon: Icons.public_rounded,
          label: 'Länder',
          value: insights.countryCount.toString(),
        ),
        _StatTile(
          icon: Icons.location_city_rounded,
          label: 'Städte',
          value: insights.cityCount.toString(),
        ),
        _StatTile(
          icon: Icons.calendar_month_rounded,
          label: 'Reisetage',
          value: insights.travelDays.toString(),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 21),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldProgressCard extends StatelessWidget {
  const _WorldProgressCard({required this.insights});

  final _TravelInsights insights;

  @override
  Widget build(BuildContext context) {
    return _StatsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.travel_explore_rounded,
            title: 'Reisefortschritt',
            subtitle: '${insights.worldPercentLabel} der Welt bereist',
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: insights.worldProgressFraction,
              minHeight: 12,
              backgroundColor: AppColors.surfaceSoft,
              color: AppColors.sage,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Bereiste Länder',
            value: '${insights.countryCount} von 195',
          ),
          _InfoRow(
            label: 'Durchschnittliche Reisedauer',
            value: insights.averageTripDaysLabel,
          ),
          _InfoRow(
            label: 'Dokumentierte Fotos',
            value: insights.photoTotal.toString(),
          ),
        ],
      ),
    );
  }
}

class _TravelRecordsCard extends StatelessWidget {
  const _TravelRecordsCard({required this.insights});

  final _TravelInsights insights;

  @override
  Widget build(BuildContext context) {
    return _StatsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.emoji_events_rounded,
            title: 'Reise-Rekorde',
            subtitle: 'Längste, kürzeste und häufigste Reiseziele.',
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Längste Reise', value: insights.longestTripLabel),
          _InfoRow(label: 'Kürzeste Reise', value: insights.shortestTripLabel),
          _InfoRow(label: 'Top-Land', value: insights.topCountryLabel),
          _InfoRow(label: 'Top-Stadt', value: insights.topCityLabel),
        ],
      ),
    );
  }
}

class _RankPanel extends StatelessWidget {
  const _RankPanel({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String emptyText;
  final List<_RankItem> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.isEmpty
        ? 1
        : items.map((item) => item.value).reduce((a, b) => a > b ? a : b);

    return _StatsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(emptyText, style: const TextStyle(color: AppColors.textMuted))
          else
            ...items
                .take(5)
                .map((item) => _RankRow(item: item, maxValue: maxValue)),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.item, required this.maxValue});

  final _RankItem item;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue <= 0 ? 0.0 : item.value / maxValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                item.valueLabel,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (item.subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              item.subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceSoft,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinentPanel extends StatelessWidget {
  const _ContinentPanel({required this.items});

  final List<_RankItem> items;

  @override
  Widget build(BuildContext context) {
    return _StatsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.map_rounded,
            title: 'Kontinente',
            subtitle: 'Verteilung deiner bereisten Länder.',
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Noch keine Kontinente aus Reisen berechnet.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...items.map(
              (item) => _InfoRow(label: item.label, value: item.valueLabel),
            ),
        ],
      ),
    );
  }
}

class _YearPanel extends StatelessWidget {
  const _YearPanel({required this.items});

  final List<_YearStat> items;

  @override
  Widget build(BuildContext context) {
    return _StatsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.timeline_rounded,
            title: 'Jahresübersicht',
            subtitle:
                'Welche Jahre deine Reisegeschichte besonders geprägt haben.',
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Noch keine Jahresdaten vorhanden.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...items.take(6).map((item) => _YearRow(item: item)),
        ],
      ),
    );
  }
}

class _YearRow extends StatelessWidget {
  const _YearRow({required this.item});

  final _YearStat item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              item.year.toString(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.tripCount} Reisen · ${item.travelDays} Tage',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.countryCount} Länder · ${item.cityCount} Städte',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultMemoryPanel extends StatelessWidget {
  const _VaultMemoryPanel({required this.insights});

  final _TravelInsights insights;

  @override
  Widget build(BuildContext context) {
    return _StatsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            icon: Icons.auto_stories_rounded,
            title: 'Vault & Erinnerungen',
            subtitle: 'Dokumente, Fotos, Highlights und Lieblingsmomente.',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Dokumente gesamt',
            value: insights.documentCount.toString(),
          ),
          _InfoRow(label: 'PDFs', value: insights.pdfCount.toString()),
          _InfoRow(
            label: 'Bilder / Screenshots',
            value: insights.imageCount.toString(),
          ),
          _InfoRow(
            label: 'Favorisierte Dokumente',
            value: insights.favoriteDocumentCount.toString(),
          ),
          _InfoRow(
            label: 'Album-Einträge',
            value: insights.albumEntryCount.toString(),
          ),
          _InfoRow(
            label: 'Highlights',
            value: insights.highlightCount.toString(),
          ),
          _InfoRow(
            label: 'Lieblingsmomente',
            value: insights.favoriteMomentCount.toString(),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _TravelInsights {
  const _TravelInsights({
    required this.tripCount,
    required this.countryCount,
    required this.cityCount,
    required this.worldProgressFraction,
    required this.travelDays,
    required this.averageTripDays,
    required this.documentCount,
    required this.pdfCount,
    required this.imageCount,
    required this.photoTotal,
    required this.favoriteDocumentCount,
    required this.albumEntryCount,
    required this.highlightCount,
    required this.favoriteMomentCount,
    required this.longestTrip,
    required this.shortestTrip,
    required this.topCountries,
    required this.topCities,
    required this.continents,
    required this.years,
  });

  final int tripCount;
  final int countryCount;
  final int cityCount;
  final double worldProgressFraction;
  final int travelDays;
  final double averageTripDays;
  final int documentCount;
  final int pdfCount;
  final int imageCount;
  final int photoTotal;
  final int favoriteDocumentCount;
  final int albumEntryCount;
  final int highlightCount;
  final int favoriteMomentCount;
  final Trip? longestTrip;
  final Trip? shortestTrip;
  final List<_RankItem> topCountries;
  final List<_RankItem> topCities;
  final List<_RankItem> continents;
  final List<_YearStat> years;

  String get worldPercentLabel =>
      '${(worldProgressFraction * 100).toStringAsFixed(1)} %';

  String get averageTripDaysLabel {
    if (tripCount == 0) return '0 Tage';
    return '${averageTripDays.toStringAsFixed(1)} Tage';
  }

  String get longestTripLabel => longestTrip == null
      ? 'Noch keine Reise'
      : '${_tripName(longestTrip!)} · ${longestTrip!.durationDays} Tage';

  String get shortestTripLabel => shortestTrip == null
      ? 'Noch keine Reise'
      : '${_tripName(shortestTrip!)} · ${shortestTrip!.durationDays} Tage';

  String get topCountryLabel => topCountries.isEmpty
      ? 'Noch kein Land'
      : '${topCountries.first.label} · ${topCountries.first.valueLabel}';

  String get topCityLabel => topCities.isEmpty
      ? 'Noch keine Stadt'
      : '${topCities.first.label} · ${topCities.first.valueLabel}';

  static _TravelInsights fromTrips(List<Trip> trips) {
    final normalizedCountries = <String, _GroupedTrips>{};
    final normalizedCities = <String, _GroupedTrips>{};
    final years = <int, _YearBucket>{};

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

      final bucket = years.putIfAbsent(
        trip.startDate.year,
        () => _YearBucket(trip.startDate.year),
      );
      bucket.trips.add(trip);
    }

    final documents = trips
        .expand((trip) => trip.documents)
        .toList(growable: false);
    final albumEntries = trips
        .expand((trip) => trip.albumEntries)
        .toList(growable: false);
    final travelDays = trips.fold<int>(
      0,
      (sum, trip) => sum + trip.durationDays,
    );
    final sortedByDuration = trips.toList()
      ..sort((a, b) => b.durationDays.compareTo(a.durationDays));
    final topCountries = _rankCountryItems(normalizedCountries);
    final topCities = _rankCityItems(normalizedCities);
    final continents = _rankContinentItems(normalizedCountries);
    final yearStats = years.values.map((bucket) => bucket.toStat()).toList()
      ..sort((a, b) => b.year.compareTo(a.year));

    return _TravelInsights(
      tripCount: trips.length,
      countryCount: normalizedCountries.length,
      cityCount: normalizedCities.length,
      worldProgressFraction: normalizedCountries.isEmpty
          ? 0
          : (normalizedCountries.length / 195).clamp(0, 1).toDouble(),
      travelDays: travelDays,
      averageTripDays: trips.isEmpty ? 0 : travelDays / trips.length,
      documentCount: documents.length,
      pdfCount: documents.where(_isPdfDocument).length,
      imageCount: documents.where(_isImageDocument).length,
      photoTotal:
          trips.fold<int>(0, (sum, trip) => sum + trip.photoCount) +
          documents.where(_isImageDocument).length,
      favoriteDocumentCount: documents
          .where((document) => document.isFavorite)
          .length,
      albumEntryCount: albumEntries.length,
      highlightCount: albumEntries.where((entry) => entry.isHighlight).length,
      favoriteMomentCount: albumEntries
          .where((entry) => entry.isFavorite)
          .length,
      longestTrip: sortedByDuration.isEmpty ? null : sortedByDuration.first,
      shortestTrip: sortedByDuration.isEmpty ? null : sortedByDuration.last,
      topCountries: topCountries,
      topCities: topCities,
      continents: continents,
      years: yearStats,
    );
  }

  static List<_RankItem> _rankCountryItems(Map<String, _GroupedTrips> grouped) {
    final items = grouped.values.map((group) {
      final cities = group.trips
          .map((trip) => trip.destination.trim())
          .where((city) => city.isNotEmpty)
          .toSet();
      final days = group.trips.fold<int>(
        0,
        (sum, trip) => sum + trip.durationDays,
      );
      return _RankItem(
        label: group.label,
        subtitle: '${cities.length} Städte · $days Tage',
        value: group.trips.length,
        valueLabel: '${group.trips.length} Reisen',
      );
    }).toList()..sort(_sortRankItems);
    return items;
  }

  static List<_RankItem> _rankCityItems(Map<String, _GroupedTrips> grouped) {
    final items = grouped.values.map((group) {
      final days = group.trips.fold<int>(
        0,
        (sum, trip) => sum + trip.durationDays,
      );
      return _RankItem(
        label: group.label,
        subtitle: '${group.subtitle} · $days Tage',
        value: group.trips.length,
        valueLabel: '${group.trips.length} Reisen',
      );
    }).toList()..sort(_sortRankItems);
    return items;
  }

  static List<_RankItem> _rankContinentItems(
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
      return _RankItem(
        label: entry.key,
        subtitle: 'Bereiste Länder in dieser Region',
        value: entry.value.length,
        valueLabel: '${entry.value.length} Länder',
      );
    }).toList()..sort(_sortRankItems);
    return items;
  }

  static int _sortRankItems(_RankItem a, _RankItem b) {
    final valueCompare = b.value.compareTo(a.value);
    if (valueCompare != 0) return valueCompare;
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

  static String _tripName(Trip trip) {
    final title = trip.title.trim();
    if (title.isNotEmpty) return title;
    final city = trip.destination.trim();
    final country = trip.country.trim();
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    if (city.isNotEmpty) return city;
    return country.isNotEmpty ? country : 'Reise';
  }
}

class _GroupedTrips {
  _GroupedTrips({required this.label, this.subtitle = ''});

  final String label;
  final String subtitle;
  final List<Trip> trips = [];
}

class _RankItem {
  const _RankItem({
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

class _YearBucket {
  _YearBucket(this.year);

  final int year;
  final List<Trip> trips = [];

  _YearStat toStat() {
    final countries = trips
        .map((trip) => trip.country.trim())
        .where((country) => country.isNotEmpty)
        .toSet();
    final cities = trips
        .map((trip) => trip.destination.trim())
        .where((city) => city.isNotEmpty)
        .toSet();
    return _YearStat(
      year: year,
      tripCount: trips.length,
      travelDays: trips.fold<int>(0, (sum, trip) => sum + trip.durationDays),
      countryCount: countries.length,
      cityCount: cities.length,
    );
  }
}

class _YearStat {
  const _YearStat({
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
