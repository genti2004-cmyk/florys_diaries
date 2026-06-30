import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/archive_empty_state.dart';

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
    final countryCount = trips
        .map((trip) => trip.country.trim().toLowerCase())
        .where((country) => country.isNotEmpty)
        .toSet()
        .length;
    final memoryCount = trips.fold<int>(0, (sum, trip) => sum + trip.albumEntryCount);

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('past-trips'),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 150),
          children: [
            Text('Timeline', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Deine Reisen in chronologischer Reihenfolge – elegant, klar und voller Erinnerungen.',
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
              Row(
                children: [
                  Expanded(
                    child: _TopInfoCard(
                      title: 'Reisen',
                      value: '${trips.length}',
                      icon: Icons.flight_takeoff_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TopInfoCard(
                      title: 'Länder',
                      value: '$countryCount',
                      icon: Icons.public_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TopInfoCard(
                      title: 'Momente',
                      value: '$memoryCount',
                      icon: Icons.favorite_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ...groupedTrips.entries.map(
                (entry) => _YearTimelineSection(
                  year: entry.key,
                  trips: entry.value,
                  onOpenTrip: (trip) => _openTrip(context, trip),
                ),
              ),
            ],
          ],
        ),
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

class _TopInfoCard extends StatelessWidget {
  const _TopInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _YearTimelineSection extends StatelessWidget {
  const _YearTimelineSection({
    required this.year,
    required this.trips,
    required this.onOpenTrip,
  });

  final int year;
  final List<Trip> trips;
  final ValueChanged<Trip> onOpenTrip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  '$year',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...trips.map(
            (trip) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TimelineTripItem(trip: trip, onTap: () => onOpenTrip(trip)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTripItem extends StatelessWidget {
  const _TimelineTripItem({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TravelVisuals.forText(
      '${trip.destination} ${trip.country} ${trip.title}',
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: palette.gradient.last,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140D1728),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: palette.gradient,
                              ),
                            ),
                            child: Icon(palette.icon, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${trip.destination}, ${trip.country}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TimelineChip(
                            icon: Icons.calendar_today_outlined,
                            label: TravelVisuals.formatDateRange(
                              trip.startDate,
                              trip.endDate,
                            ),
                          ),
                          _TimelineChip(
                            icon: Icons.timelapse_rounded,
                            label: '${trip.durationDays} Tage',
                          ),
                          if (trip.albumEntryCount > 0)
                            _TimelineChip(
                              icon: Icons.favorite_outline_rounded,
                              label: '${trip.albumEntryCount} Momente',
                            ),
                        ],
                      ),
                      if (trip.notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          trip.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineChip extends StatelessWidget {
  const _TimelineChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('Timeline wird geladen …'),
        ],
      ),
    );
  }
}
