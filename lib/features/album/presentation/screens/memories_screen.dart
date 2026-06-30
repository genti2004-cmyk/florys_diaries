import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_data_empty_state.dart';
import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/core/widgets/trip_cover_image.dart';
import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/screens/trip_detail_screen.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  bool _favoritesOnly = false;

  void _openTrip(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TripDetailScreen(trip: trip)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final allMoments = _buildMoments(store.trips);
    final moments = _favoritesOnly
        ? allMoments.where((moment) => moment.entry.isFavorite).toList()
        : allMoments;
    final favoriteCount = allMoments
        .where((moment) => moment.entry.isFavorite)
        .length;
    final tripCount = allMoments.map((moment) => moment.trip.id).toSet().length;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('moments-screen-v63'),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 132),
          children: [
            Text('Momente', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Deine schönsten Erinnerungen aus allen Reisen an einem Ort.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            _MomentsOverview(
              momentCount: allMoments.length,
              favoriteCount: favoriteCount,
              tripCount: tripCount,
              favoritesOnly: _favoritesOnly,
              onFavoritesChanged: (value) {
                setState(() => _favoritesOnly = value);
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _favoritesOnly ? 'Lieblingsmomente' : 'Alle Momente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${moments.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (moments.isEmpty)
              TravelDataEmptyState(
                icon: Icons.favorite_outline_rounded,
                title: _favoritesOnly
                    ? 'Noch keine Lieblingsmomente'
                    : 'Noch keine Momente gespeichert',
                description: _favoritesOnly
                    ? 'Markiere einen Moment in einer Reise als Favorit, damit er hier erscheint.'
                    : 'Sobald du in einer Reise einen Moment anlegst, erscheint er automatisch auf dieser Seite.',
                hint:
                    'Highlights, Orte, Essen und Tagesnotizen bleiben direkt mit der jeweiligen Reise verbunden.',
              )
            else
              ...moments.map(
                (moment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MomentCard(
                    moment: moment,
                    onTap: () => _openTrip(context, moment.trip),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static List<_TripMoment> _buildMoments(List<Trip> trips) {
    final moments = <_TripMoment>[];
    for (final trip in trips) {
      for (final entry in trip.albumEntries) {
        moments.add(_TripMoment(trip: trip, entry: entry));
      }
    }
    moments.sort((left, right) => right.entry.date.compareTo(left.entry.date));
    return moments;
  }
}

class _MomentsOverview extends StatelessWidget {
  const _MomentsOverview({
    required this.momentCount,
    required this.favoriteCount,
    required this.tripCount,
    required this.favoritesOnly,
    required this.onFavoritesChanged,
  });

  final int momentCount;
  final int favoriteCount;
  final int tripCount;
  final bool favoritesOnly;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _OverviewMetric(
                    value: '$momentCount',
                    label: 'Momente',
                    icon: Icons.auto_stories_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OverviewMetric(
                    value: '$favoriteCount',
                    label: 'Favoriten',
                    icon: Icons.favorite_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OverviewMetric(
                    value: '$tripCount',
                    label: 'Reisen',
                    icon: Icons.flight_takeoff_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    selected: !favoritesOnly,
                    onSelected: (_) => onFavoritesChanged(false),
                    avatar: const Icon(Icons.grid_view_rounded, size: 17),
                    label: const SizedBox(
                      width: double.infinity,
                      child: Text('Alle', textAlign: TextAlign.center),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    selected: favoritesOnly,
                    onSelected: (_) => onFavoritesChanged(true),
                    avatar: const Icon(Icons.favorite_rounded, size: 17),
                    label: const SizedBox(
                      width: double.infinity,
                      child: Text('Favoriten', textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(height: 7),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({required this.moment, required this.onTap});

  final _TripMoment moment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TravelVisuals.forText(
      '${moment.trip.destination} ${moment.trip.country} ${moment.entry.title}',
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 164,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 116,
                child: TripCoverImage(
                  trip: moment.trip,
                  borderRadius: BorderRadius.zero,
                  showFallbackIcon: true,
                  overlay: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x08000000), Color(0x6607111F)],
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          palette.icon,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              moment.entry.title.trim().isEmpty
                                  ? moment.trip.title
                                  : moment.entry.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (moment.entry.isFavorite)
                            const Icon(
                              Icons.favorite_rounded,
                              size: 18,
                              color: AppColors.sand,
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _subtitle(moment),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (moment.entry.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          moment.entry.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        moment.trip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(_TripMoment moment) {
    final parts = <String>[
      TripAlbumEntryTypes.byId(moment.entry.typeId).label,
      TravelVisuals.formatDate(moment.entry.date),
    ];
    if (moment.entry.location.trim().isNotEmpty) {
      parts.add(moment.entry.location.trim());
    } else {
      parts.add(moment.trip.destination);
    }
    return parts.join(' · ');
  }
}

class _TripMoment {
  const _TripMoment({required this.trip, required this.entry});

  final Trip trip;
  final TripAlbumEntry entry;
}
