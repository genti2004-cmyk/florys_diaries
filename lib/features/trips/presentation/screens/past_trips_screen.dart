import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/archive_empty_state.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/archive_overview_card.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/archive_year_header.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_card.dart';

import 'trip_detail_screen.dart';

class PastTripsScreen extends StatelessWidget {
  const PastTripsScreen({super.key});

  void _openTrip(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TripDetailScreen(trip: trip)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final trips = store.pastTrips.reversed.toList(growable: false);
    final groupedTrips = _groupByYear(trips);

    return SafeArea(
      top: false,
      child: ListView(
        key: const PageStorageKey<String>('past-trips'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text('Reisearchiv', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 5),
          Text(
            'Abgeschlossene Reisen, Unterlagen und Erinnerungen nach Jahr.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          if (store.isLoading)
            const _ArchiveLoadingState()
          else if (trips.isEmpty)
            const ArchiveEmptyState()
          else ...[
            ArchiveOverviewCard(trips: trips),
            for (final entry in groupedTrips.entries) ...[
              ArchiveYearHeader(year: entry.key, trips: entry.value),
              ...entry.value.map(
                (trip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TripCard(
                    trip: trip,
                    onTap: () => _openTrip(context, trip),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static Map<int, List<Trip>> _groupByYear(List<Trip> trips) {
    final groupedTrips = <int, List<Trip>>{};
    for (final trip in trips) {
      groupedTrips.putIfAbsent(trip.endDate.year, () => []).add(trip);
    }
    return groupedTrips;
  }
}

class _ArchiveLoadingState extends StatelessWidget {
  const _ArchiveLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('Reisearchiv wird geladen …'),
        ],
      ),
    );
  }
}
