import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/core/widgets/app_section_title.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const AppSectionTitle(
            title: 'Vergangene Reisen',
            subtitle: 'Abgeschlossene Trips werden automatisch hier angezeigt.',
          ),
          if (trips.isEmpty)
            const AppSectionCard(
              icon: Icons.history_rounded,
              title: 'Noch kein Archiv',
              subtitle: 'Wenn das Enddatum vorbei ist, erscheint die Reise hier.',
            )
          else
            for (final entry in groupedTrips.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: Text(
                  entry.key.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
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
