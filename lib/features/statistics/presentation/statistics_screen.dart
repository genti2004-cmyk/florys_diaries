import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_data_empty_state.dart';
import 'package:florys_diaries/features/statistics/application/travel_statistics_analyzer.dart';
import 'package:florys_diaries/features/statistics/domain/travel_statistics.dart';
import 'package:florys_diaries/features/statistics/presentation/widgets/statistics_overview_cards.dart';
import 'package:florys_diaries/features/statistics/presentation/widgets/statistics_period_filter.dart';
import 'package:florys_diaries/features/statistics/presentation/widgets/statistics_rank_panels.dart';
import 'package:florys_diaries/features/statistics/presentation/widgets/statistics_vault_memory_panel.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    this.analyzer = const TravelStatisticsAnalyzer(),
    this.showHeader = true,
    this.initialYear,
  });

  final TravelStatisticsAnalyzer analyzer;
  final bool showHeader;
  final int? initialYear;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Trip>? _analyzedTrips;
  int? _selectedYear;
  int? _analyzedYear;
  TravelStatistics? _statistics;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshStatistics();
  }

  @override
  void didUpdateWidget(covariant StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final yearChanged = widget.initialYear != oldWidget.initialYear;
    if (yearChanged) {
      _selectedYear = widget.initialYear;
    }
    if (yearChanged || !identical(widget.analyzer, oldWidget.analyzer)) {
      _recalculate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statistics = _statistics!;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('travel-statistics-v23'),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 150),
          children: [
            if (widget.showHeader) ...[
              Text(
                'Statistiken',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Fortschritt, Rekorde und Reisezahlen in einer klaren Premium-Ansicht.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
            ],
            if (statistics.availableYears.isNotEmpty) ...[
              StatisticsPeriodFilter(
                selectedYear: statistics.selectedYear,
                years: statistics.availableYears,
                onChanged: _selectYear,
              ),
              const SizedBox(height: 14),
            ],
            if (statistics.tripCount == 0)
              const TravelDataEmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'Noch keine Reisebilanz vorhanden',
                description:
                    'Die Statistik entsteht automatisch aus gespeicherten Reisen, Ländern, Städten, Dokumenten und Momenten.',
                hint:
                    'Nach deiner ersten Reise werden alle Werte beim Öffnen dieser Seite automatisch neu berechnet.',
              )
            else ...[
              StatisticsHeroGrid(statistics: statistics),
              const SizedBox(height: 14),
              StatisticsTripStatusCard(statistics: statistics),
              const SizedBox(height: 14),
              StatisticsWorldProgressCard(statistics: statistics),
              const SizedBox(height: 14),
              StatisticsRecordsCard(statistics: statistics),
              const SizedBox(height: 14),
              StatisticsRankPanel(
                title: 'Meistbesuchte Länder',
                emptyText: 'Noch keine Länder erfasst.',
                items: statistics.topCountries,
              ),
              const SizedBox(height: 14),
              StatisticsRankPanel(
                title: 'Meistbesuchte Städte',
                emptyText: 'Noch keine Städte erfasst.',
                items: statistics.topCities,
              ),
              const SizedBox(height: 14),
              StatisticsContinentPanel(items: statistics.continents),
              const SizedBox(height: 14),
              StatisticsYearPanel(items: statistics.years),
              const SizedBox(height: 14),
              StatisticsVaultMemoryPanel(statistics: statistics),
            ],
          ],
        ),
      ),
    );
  }

  void _selectYear(int? year) {
    if (year == _selectedYear) {
      return;
    }
    setState(() {
      _selectedYear = year;
      _recalculate();
    });
  }

  void _refreshStatistics() {
    final trips = TripStoreScope.of(context).trips;
    if (identical(_analyzedTrips, trips) &&
        _analyzedYear == _selectedYear &&
        _statistics != null) {
      return;
    }

    _analyzedTrips = trips;
    _recalculate();
  }

  void _recalculate() {
    final trips = _analyzedTrips;
    if (trips == null) {
      return;
    }
    final statistics = widget.analyzer.analyze(trips, year: _selectedYear);
    _selectedYear = statistics.selectedYear;
    _analyzedYear = statistics.selectedYear;
    _statistics = statistics;
  }
}
