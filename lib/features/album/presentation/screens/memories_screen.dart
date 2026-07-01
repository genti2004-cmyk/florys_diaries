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
          key: const PageStorageKey<String>('moments-screen-v67'),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 156),
          children: [
            Text('Momente', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Deine schönsten Erinnerungen aus allen Reisen – bildstärker, ruhiger und persönlicher.',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${moments.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.memoryGradient,
        ),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
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
                    icon: Icons.auto_awesome_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OverviewMetric(
                    value: '$favoriteCount',
                    label: 'Favoriten',
                    icon: Icons.favorite_rounded,
                    accent: AppColors.rose,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OverviewMetric(
                    value: '$tripCount',
                    label: 'Reisen',
                    icon: Icons.flight_takeoff_rounded,
                    accent: AppColors.plum,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                const SizedBox(width: 10),
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
    this.accent = AppColors.primary,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 10),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 22,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Card(
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
                  showFallbackIcon: true,
                  overlay: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x08000000), Color(0x6B07111F)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _MomentPill(
                              icon: _iconForType(moment.entry.typeId),
                              label: _typeLabel(moment.entry),
                            ),
                            const Spacer(),
                            if (moment.entry.isFavorite)
                              const _MomentFavoriteBadge(),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.26),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Icon(
                            palette.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moment.entry.title.trim().isEmpty
                          ? moment.trip.title
                          : moment.entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      moment.entry.description.trim().isEmpty
                          ? 'Gespeichert in ${moment.trip.title}'
                          : moment.entry.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.place_rounded,
                          label: moment.entry.location.trim().isEmpty
                              ? '${moment.trip.destination}, ${moment.trip.country}'
                              : moment.entry.location.trim(),
                        ),
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: TravelVisuals.formatDate(moment.entry.date),
                        ),
                        _InfoChip(
                          icon: Icons.flight_outlined,
                          label: moment.trip.title,
                          highlighted: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _typeLabel(TripAlbumEntry entry) {
    return TripAlbumEntryTypes.byId(entry.typeId).label;
  }

  static IconData _iconForType(String typeId) {
    return switch (typeId) {
      'highlight' => Icons.auto_awesome_rounded,
      'place' => Icons.place_rounded,
      'food' => Icons.restaurant_rounded,
      'memory' => Icons.favorite_rounded,
      _ => Icons.notes_rounded,
    };
  }
}

class _MomentPill extends StatelessWidget {
  const _MomentPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentFavoriteBadge extends StatelessWidget {
  const _MomentFavoriteBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_rounded, size: 14, color: AppColors.rose),
          const SizedBox(width: 6),
          Text(
            'Favorit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final background = highlighted ? AppColors.primarySoft : AppColors.surfaceSoft;
    final foreground = highlighted ? AppColors.primary : AppColors.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
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
