import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/core/widgets/trip_cover_image.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_empty_state.dart';

import 'trip_detail_screen.dart';
import 'trip_editor_screen.dart';

enum _TripFilter { all, upcoming, past }

class PastTripsScreen extends StatefulWidget {
  const PastTripsScreen({super.key});

  @override
  State<PastTripsScreen> createState() => _PastTripsScreenState();
}

class _PastTripsScreenState extends State<PastTripsScreen> {
  _TripFilter _filter = _TripFilter.all;

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
    final upcoming = store.upcomingTrips;
    final past = store.pastTrips.reversed.toList(growable: false);
    final countryCount = store.trips
        .map((trip) => trip.country.trim().toLowerCase())
        .where((country) => country.isNotEmpty)
        .toSet()
        .length;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('all-trips-v6'),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 132),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reisen',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Geplante und erlebte Reisen an einem Ort.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Neu'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (store.isLoading)
              const _TripsLoadingState()
            else if (store.trips.isEmpty)
              TripEmptyState(onCreateTrip: () => _openEditor(context))
            else ...[
              _TripsOverviewBar(
                upcomingCount: upcoming.length,
                pastCount: past.length,
                countryCount: countryCount,
              ),
              const SizedBox(height: 14),
              _FilterBar(
                value: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 20),
              if (_filter == _TripFilter.all) ...[
                if (upcoming.isNotEmpty)
                  _TripsSection(
                    title: 'Geplant',
                    subtitle: '${upcoming.length} kommende Reisen',
                    trips: upcoming,
                    onOpenTrip: (trip) => _openTrip(context, trip),
                  ),
                if (upcoming.isNotEmpty && past.isNotEmpty)
                  const SizedBox(height: 22),
                if (past.isNotEmpty)
                  _TripsSection(
                    title: 'Erlebt',
                    subtitle: '${past.length} abgeschlossene Reisen',
                    trips: past,
                    onOpenTrip: (trip) => _openTrip(context, trip),
                  ),
              ] else if (_filter == _TripFilter.upcoming) ...[
                if (upcoming.isEmpty)
                  const _FilteredEmptyState(
                    icon: Icons.flight_takeoff_rounded,
                    title: 'Keine geplanten Reisen',
                    text: 'Lege eine neue Reise an, sobald dein nächstes Ziel feststeht.',
                  )
                else
                  _TripsSection(
                    title: 'Geplant',
                    subtitle: '${upcoming.length} kommende Reisen',
                    trips: upcoming,
                    onOpenTrip: (trip) => _openTrip(context, trip),
                  ),
              ] else ...[
                if (past.isEmpty)
                  const _FilteredEmptyState(
                    icon: Icons.auto_stories_rounded,
                    title: 'Noch keine erlebten Reisen',
                    text: 'Abgeschlossene Reisen erscheinen später automatisch hier.',
                  )
                else
                  _TripsSection(
                    title: 'Erlebt',
                    subtitle: '${past.length} abgeschlossene Reisen',
                    trips: past,
                    onOpenTrip: (trip) => _openTrip(context, trip),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _TripsOverviewBar extends StatelessWidget {
  const _TripsOverviewBar({
    required this.upcomingCount,
    required this.pastCount,
    required this.countryCount,
  });

  final int upcomingCount;
  final int pastCount;
  final int countryCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _OverviewValue(
                value: '$upcomingCount',
                label: 'Geplant',
                icon: Icons.schedule_rounded,
              ),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _OverviewValue(
                value: '$pastCount',
                label: 'Erlebt',
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const _VerticalDivider(),
            Expanded(
              child: _OverviewValue(
                value: '$countryCount',
                label: 'Länder',
                icon: Icons.public_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(height: 7),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 54, color: AppColors.border);
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.value, required this.onChanged});

  final _TripFilter value;
  final ValueChanged<_TripFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_TripFilter>(
        segments: const [
          ButtonSegment(
            value: _TripFilter.all,
            icon: Icon(Icons.view_list_rounded),
            label: Text('Alle'),
          ),
          ButtonSegment(
            value: _TripFilter.upcoming,
            icon: Icon(Icons.flight_takeoff_rounded),
            label: Text('Geplant'),
          ),
          ButtonSegment(
            value: _TripFilter.past,
            icon: Icon(Icons.history_rounded),
            label: Text('Erlebt'),
          ),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            onChanged(selection.first);
          }
        },
      ),
    );
  }
}

class _TripsSection extends StatelessWidget {
  const _TripsSection({
    required this.title,
    required this.subtitle,
    required this.trips,
    required this.onOpenTrip,
  });

  final String title;
  final String subtitle;
  final List<Trip> trips;
  final ValueChanged<Trip> onOpenTrip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        ...trips.map(
          (trip) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _JourneyListCard(
              trip: trip,
              onTap: () => onOpenTrip(trip),
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneyListCard extends StatelessWidget {
  const _JourneyListCard({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 138,
              width: double.infinity,
              child: TripCoverImage(
                trip: trip,
                borderRadius: BorderRadius.zero,
                overlay: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x09000000), Color(0xB807111F)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: _StatusPill(isPast: trip.isPast, onImage: true),
                      ),
                      const Spacer(),
                      Text(
                        trip.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(color: Color(0x66000000), blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${trip.destination}, ${trip.country}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TravelVisuals.formatDateRange(
                            trip.startDate,
                            trip.endDate,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${trip.durationDays} Tage · '
                          '${trip.documentCount} Dokumente · '
                          '${trip.albumEntryCount} Momente',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isPast, this.onImage = false});

  final bool isPast;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.black.withValues(alpha: 0.28)
            : (isPast ? AppColors.surfaceSoft : AppColors.primarySoft),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPast ? 'Erlebt' : 'Geplant',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: onImage
              ? Colors.white
              : (isPast ? AppColors.textMuted : AppColors.primary),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 42, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripsLoadingState extends StatelessWidget {
  const _TripsLoadingState();

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
          Text('Reisen werden geladen …'),
        ],
      ),
    );
  }
}
