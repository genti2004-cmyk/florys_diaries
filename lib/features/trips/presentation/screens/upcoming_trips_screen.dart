import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/app_info_card.dart';
import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/core/widgets/app_section_title.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_card.dart';

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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          const AppSectionTitle(
            title: 'Kommende Reisen',
            subtitle: 'Plane Trips, öffne Details und sammle später Dokumente.',
          ),
          Row(
            children: [
              Expanded(
                child: AppInfoCard(
                  icon: Icons.flight_takeoff_rounded,
                  title: nextTrip?.destination ?? 'Keine Reise',
                  subtitle: nextTrip == null
                      ? 'Lege deine erste Reise an.'
                      : _dateRange(nextTrip),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInfoCard(
                  icon: Icons.calendar_month_outlined,
                  title: '${trips.length}',
                  subtitle: trips.length == 1
                      ? 'kommende Reise'
                      : 'kommende Reisen',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (trips.isEmpty)
            AppSectionCard(
              icon: Icons.add_circle_outline,
              title: 'Noch keine kommende Reise',
              subtitle:
                  'Tippe auf „Neue Reise“ und erfasse Ziel, Land, Zeitraum und Notizen.',
              onTap: () => _openEditor(context),
            )
          else
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
      ),
    );
  }

  static String _dateRange(Trip trip) {
    return '${_formatDate(trip.startDate)} – ${_formatDate(trip.endDate)}';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
