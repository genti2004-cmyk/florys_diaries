import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/statistics/domain/travel_statistics.dart';
import 'package:florys_diaries/features/statistics/presentation/widgets/statistics_panel.dart';

class StatisticsHeroGrid extends StatelessWidget {
  const StatisticsHeroGrid({super.key, required this.statistics});

  final TravelStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        icon: Icons.flight_takeoff_rounded,
        label: 'Reisen',
        value: statistics.tripCount.toString(),
      ),
      _StatTile(
        icon: Icons.public_rounded,
        label: 'Länder',
        value: statistics.countryCount.toString(),
      ),
      _StatTile(
        icon: Icons.location_city_rounded,
        label: 'Städte',
        value: statistics.cityCount.toString(),
      ),
      _StatTile(
        icon: Icons.calendar_month_rounded,
        label: 'Reisetage',
        value: statistics.travelDays.toString(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 340 ? 1 : 2;
        final spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((tile) => SizedBox(width: width, child: tile))
              .toList(growable: false),
        );
      },
    );
  }
}

class StatisticsWorldProgressCard extends StatelessWidget {
  const StatisticsWorldProgressCard({super.key, required this.statistics});

  final TravelStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return StatisticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatisticsPanelHeader(
            icon: Icons.travel_explore_rounded,
            title: 'Reisefortschritt',
            subtitle: '${statistics.worldPercentLabel} der Welt bereist',
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: statistics.worldProgressFraction,
              minHeight: 12,
              backgroundColor: AppColors.surfaceSoft,
              color: AppColors.sage,
            ),
          ),
          const SizedBox(height: 12),
          StatisticsInfoRow(
            label: 'Bereiste Länder',
            value: '${statistics.countryCount} von 195',
          ),
          StatisticsInfoRow(
            label: 'Durchschnittliche Reisedauer',
            value: statistics.averageTripDaysLabel,
          ),
          StatisticsInfoRow(
            label: 'Dokumentierte Fotos',
            value: statistics.photoTotal.toString(),
          ),
        ],
      ),
    );
  }
}

class StatisticsRecordsCard extends StatelessWidget {
  const StatisticsRecordsCard({super.key, required this.statistics});

  final TravelStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return StatisticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatisticsPanelHeader(
            icon: Icons.emoji_events_rounded,
            title: 'Reise-Rekorde',
            subtitle: 'Längste, kürzeste und häufigste Reiseziele.',
          ),
          const SizedBox(height: 12),
          StatisticsInfoRow(
            label: 'Längste Reise',
            value: statistics.longestTripLabel,
          ),
          StatisticsInfoRow(
            label: 'Kürzeste Reise',
            value: statistics.shortestTripLabel,
          ),
          StatisticsInfoRow(
            label: 'Top-Land',
            value: statistics.topCountryLabel,
          ),
          StatisticsInfoRow(label: 'Top-Stadt', value: statistics.topCityLabel),
        ],
      ),
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
      child: Container(
        constraints: const BoxConstraints(minHeight: 116),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
