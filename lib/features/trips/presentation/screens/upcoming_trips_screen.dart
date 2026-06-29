import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_card.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_empty_state.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_overview_metrics.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/upcoming_trip_hero.dart';

import 'trip_detail_screen.dart';
import 'trip_editor_screen.dart';

class UpcomingTripsScreen extends StatelessWidget {
  const UpcomingTripsScreen({super.key});

  Future<void> _openEditor(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TripEditorScreen()));
  }

  void _openTrip(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TripDetailScreen(trip: trip)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final trips = store.upcomingTrips;
    final nextTrip = trips.isEmpty ? null : trips.first;
    final countryCount = trips
        .map((trip) => trip.country.trim().toLowerCase())
        .where((country) => country.isNotEmpty)
        .toSet()
        .length;
    final documentCount = trips.fold<int>(
      0,
      (sum, trip) => sum + trip.documentCount,
    );

    return SafeArea(
      top: false,
      child: ListView(
        key: const PageStorageKey<String>('upcoming-trips'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          Text(
            'Deine Reisen',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            'Alles Wichtige für die nächste Reise auf einen Blick.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          if (store.isLoading)
            const _LoadingState()
          else if (nextTrip == null)
            TripEmptyState(onCreateTrip: () => _openEditor(context))
          else ...[
            UpcomingTripHero(
              trip: nextTrip,
              onTap: () => _openTrip(context, nextTrip),
            ),
            const SizedBox(height: 14),
            TripOverviewMetrics(
              upcomingCount: trips.length,
              countryCount: countryCount,
              documentCount: documentCount,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kommende Reisen',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${trips.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...trips.map(
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
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
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
          Text('Reisen werden geladen …'),
        ],
      ),
    );
  }
}
