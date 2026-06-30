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
    final allMoments = _buildMoments(store.trips, favoritesOnly: false);
    final moments = _favoritesOnly
        ? allMoments.where((moment) => moment.entry.isFavorite).toList()
        : allMoments;
    final favoriteCount = allMoments
        .where((moment) => moment.entry.isFavorite)
        .length;

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('moments-screen-v61'),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 132),
          children: [
            Text('Momente', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Fotos, Highlights, Lieblingsorte und persönliche Geschichten aus deinen Reisen.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            _MomentsOverview(
              momentCount: allMoments.length,
              favoriteCount: favoriteCount,
              favoritesOnly: _favoritesOnly,
              onFavoritesChanged: (value) {
                setState(() => _favoritesOnly = value);
              },
            ),
            const SizedBox(height: 16),
            if (moments.isEmpty)
              TravelDataEmptyState(
                icon: Icons.favorite_outline_rounded,
                title: _favoritesOnly
                    ? 'Noch keine Lieblingsmomente'
                    : 'Noch keine Momente gespeichert',
                description: _favoritesOnly
                    ? 'Markiere einen Moment im Reisealbum als Favorit, damit er hier erscheint.'
                    : 'Sobald du im Reisealbum einen Eintrag anlegst, erscheint er automatisch auf dieser Seite.',
                hint:
                    'Highlights, Orte, Essen und Tagesnotizen bleiben direkt mit der jeweiligen Reise verbunden.',
              )
            else
              ...moments.map(
                (moment) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
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

  static List<_TripMoment> _buildMoments(
    List<Trip> trips, {
    required bool favoritesOnly,
  }) {
    final moments = <_TripMoment>[];
    for (final trip in trips) {
      for (final entry in trip.albumEntries) {
        if (!favoritesOnly || entry.isFavorite) {
          moments.add(_TripMoment(trip: trip, entry: entry));
        }
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
    required this.favoritesOnly,
    required this.onFavoritesChanged,
  });

  final int momentCount;
  final int favoriteCount;
  final bool favoritesOnly;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$momentCount Momente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$favoriteCount Favoriten',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilterChip(
              selected: favoritesOnly,
              onSelected: onFavoritesChanged,
              avatar: Icon(
                favoritesOnly
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 17,
              ),
              label: const Text('Favoriten'),
            ),
          ],
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 176,
              width: double.infinity,
              child: TripCoverImage(
                trip: moment.trip,
                borderRadius: BorderRadius.zero,
                showFallbackIcon: false,
                overlay: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x12000000), Color(0xB807111F)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ImageChip(
                            icon: palette.icon,
                            label: _typeLabel(moment.entry),
                          ),
                          const Spacer(),
                          if (moment.entry.isFavorite)
                            const _ImageChip(
                              icon: Icons.favorite_rounded,
                              label: 'Favorit',
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        moment.entry.title.trim().isEmpty
                            ? moment.trip.title
                            : moment.entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(color: Color(0x66000000), blurRadius: 10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${moment.trip.destination}, ${moment.trip.country}',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (moment.entry.description.trim().isNotEmpty) ...[
                    Text(
                      moment.entry.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DetailChip(
                        icon: Icons.calendar_today_outlined,
                        label: TravelVisuals.formatDate(moment.entry.date),
                      ),
                      _DetailChip(
                        icon: Icons.location_on_outlined,
                        label: moment.entry.location.trim().isEmpty
                            ? moment.trip.destination
                            : moment.entry.location,
                      ),
                      _DetailChip(
                        icon: Icons.flight_outlined,
                        label: moment.trip.title,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _typeLabel(TripAlbumEntry entry) {
    return TripAlbumEntryTypes.byId(entry.typeId).label;
  }
}

class _ImageChip extends StatelessWidget {
  const _ImageChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripMoment {
  const _TripMoment({required this.trip, required this.entry});

  final Trip trip;
  final TripAlbumEntry entry;
}
