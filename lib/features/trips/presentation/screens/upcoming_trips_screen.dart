import 'package:flutter/material.dart';

import 'package:florys_diaries/features/assistant/presentation/travel_assistant_screen.dart';
import 'package:florys_diaries/features/map/presentation/world_map_screen.dart';
import 'package:florys_diaries/features/reminders/domain/trip_reminder_entry.dart';
import 'package:florys_diaries/features/search/presentation/global_search_screen.dart';
import 'package:florys_diaries/features/settings/presentation/settings_screen.dart';
import 'package:florys_diaries/features/statistics/presentation/statistics_screen.dart';
import 'package:florys_diaries/features/templates/presentation/screens/trip_templates_screen.dart';
import 'package:florys_diaries/features/trips/application/home_dashboard_snapshot.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/home/premium_home_chrome.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/home/premium_home_insights.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/home/premium_home_states.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/upcoming_trip_hero.dart';

import 'past_trips_screen.dart';
import 'trip_detail_screen.dart';
import 'trip_editor_screen.dart';

class UpcomingTripsScreen extends StatelessWidget {
  const UpcomingTripsScreen({
    this.onOpenTrips,
    this.onOpenMap,
    super.key,
  });

  final VoidCallback? onOpenTrips;
  final VoidCallback? onOpenMap;

  Future<void> _openEditor(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TripEditorScreen()));
  }

  Future<void> _openAssistant(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TravelAssistantScreen()),
    );
  }

  Future<void> _openSettings(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openSearch(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GlobalSearchScreen()),
    );
  }

  Future<void> _openTemplates(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TripTemplatesScreen()),
    );
  }

  Future<void> _openStatistics(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Reisebilanz')),
          body: const StatisticsScreen(showHeader: false),
        ),
      ),
    );
  }

  void _showTrips(BuildContext context) {
    final callback = onOpenTrips;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PastTripsScreen()),
    );
  }

  void _showMap(BuildContext context) {
    final callback = onOpenMap;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WorldMapScreen()),
    );
  }

  void _openTrip(
    BuildContext context,
    Trip trip, {
    TripDetailSection initialSection = TripDetailSection.overview,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailScreen(
          trip: trip,
          initialSection: initialSection,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final snapshot = HomeDashboardSnapshot.fromTrips(store.trips);
    final focusTrip = snapshot.focusTrip;
    final additionalTrips = snapshot.upcomingTrips
        .where((trip) => trip.id != focusTrip?.id)
        .take(2)
        .toList(growable: false);

    return PremiumHomeBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('premium-home-v7'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 136),
          children: [
            PremiumHomeHeader(
              onOpenAssistant: () => _openAssistant(context),
              onOpenSearch: () => _openSearch(context),
              onOpenSettings: () => _openSettings(context),
            ),
            const SizedBox(height: 20),
            if (store.isLoading)
              const PremiumHomeLoading()
            else if (store.trips.isEmpty)
              PremiumHomeEmpty(onCreateTrip: () => _openEditor(context))
            else ...[
              if (focusTrip == null)
                PremiumHomeNoUpcoming(
                  onCreateTrip: () => _openEditor(context),
                )
              else
                UpcomingTripHero(
                  trip: focusTrip,
                  onTap: () => _openTrip(context, focusTrip),
                ),
              const SizedBox(height: 14),
              PremiumHomeQuickActions(
                onCreateTrip: () => _openEditor(context),
                onOpenTrips: () => _showTrips(context),
                onOpenStatistics: () => _openStatistics(context),
                onOpenTemplates: () => _openTemplates(context),
              ),
              if (snapshot.hasInsights) ...[
                const SizedBox(height: 24),
                const PremiumHomeSectionHeader(
                  title: 'Heute & demnächst',
                  subtitle: 'Wichtige Reiseinformationen ohne Umwege',
                ),
                const SizedBox(height: 12),
                PremiumHomeInsights(
                  snapshot: snapshot,
                  onOpenPlan: (trip) => _openTrip(
                    context,
                    trip,
                    initialSection: TripDetailSection.planning,
                  ),
                  onOpenReminder: (trip, sourceType) => _openTrip(
                    context,
                    trip,
                    initialSection:
                        sourceType == TripReminderSourceType.documentExpiry
                        ? TripDetailSection.documents
                        : TripDetailSection.planning,
                  ),
                  onOpenBudget: (trip) => _openTrip(context, trip),
                  onOpenMoment: (trip) => _openTrip(
                    context,
                    trip,
                    initialSection: TripDetailSection.memories,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PremiumHomeOverviewCard(
                tripCount: snapshot.tripCount,
                countryCount: snapshot.countryCount,
                documentCount: snapshot.documentCount,
                memoryCount: snapshot.memoryCount,
                onOpenMap: () => _showMap(context),
              ),
              if (additionalTrips.isNotEmpty) ...[
                const SizedBox(height: 24),
                PremiumHomeSectionHeader(
                  title: 'Weitere geplante Reisen',
                  subtitle: '${additionalTrips.length} weitere Ziele im Blick',
                  actionLabel: 'Alle Reisen',
                  onAction: () => _showTrips(context),
                ),
                const SizedBox(height: 12),
                ...additionalTrips.map(
                  (trip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PremiumUpcomingTripRow(
                      trip: trip,
                      onTap: () => _openTrip(context, trip),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
