import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_data_empty_state.dart';
import 'package:florys_diaries/core/widgets/travel_visuals.dart';
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
    final memories = _buildMemories(store.trips, favoritesOnly: _favoritesOnly);
    final totalFavorites = store.trips.fold<int>(
      0,
      (sum, trip) =>
          sum + trip.albumEntries.where((entry) => entry.isFavorite).length,
    );

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('memories-screen'),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 150),
          children: [
            Text(
              'Erinnerungen',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Deine schönsten Momente, Highlights und Lieblingsorte in einer eleganten Übersicht.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            _MemoryOverviewCard(
              memoryCount: memories.length,
              favoriteCount: totalFavorites,
              favoritesOnly: _favoritesOnly,
              onFavoritesChanged: (value) {
                setState(() => _favoritesOnly = value);
              },
            ),
            const SizedBox(height: 18),
            if (memories.isEmpty)
              TravelDataEmptyState(
                icon: Icons.favorite_outline_rounded,
                title: _favoritesOnly
                    ? 'Noch keine Lieblingsmomente vorhanden'
                    : 'Noch keine Erinnerungen vorhanden',
                description: _favoritesOnly
                    ? 'Markiere Einträge im Reisealbum als Favorit, damit sie hier gesammelt erscheinen.'
                    : 'Sobald du in einer Reise Album-Einträge anlegst, erscheinen sie hier als persönliche Erinnerungswand.',
                hint:
                    'Du kannst Highlights, Orte, Notizen und besondere Momente direkt in jeder Reise speichern.',
              )
            else
              ...memories.map(
                (memory) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _MemoryCard(
                    memory: memory,
                    onTap: () => _openTrip(context, memory.trip),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static List<_TripMemory> _buildMemories(
    List<Trip> trips, {
    required bool favoritesOnly,
  }) {
    final memories = <_TripMemory>[];
    for (final trip in trips) {
      for (final entry in trip.albumEntries) {
        if (!favoritesOnly || entry.isFavorite) {
          memories.add(_TripMemory(trip: trip, entry: entry));
        }
      }
    }
    memories.sort((left, right) => right.entry.date.compareTo(left.entry.date));
    return memories;
  }
}

class _MemoryOverviewCard extends StatelessWidget {
  const _MemoryOverviewCard({
    required this.memoryCount,
    required this.favoriteCount,
    required this.favoritesOnly,
    required this.onFavoritesChanged,
  });

  final int memoryCount;
  final int favoriteCount;
  final bool favoritesOnly;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _TopMetric(
                    title: 'Momente',
                    value: '$memoryCount',
                    icon: Icons.auto_stories_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopMetric(
                    title: 'Favoriten',
                    value: '$favoriteCount',
                    icon: Icons.favorite_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text('Nur Lieblingsmomente'),
                value: favoritesOnly,
                onChanged: onFavoritesChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopMetric extends StatelessWidget {
  const _TopMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
      ),
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
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory, required this.onTap});

  final _TripMemory memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TravelVisuals.forText(
      '${memory.trip.destination} ${memory.trip.country} ${memory.entry.title}',
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.gradient,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140E1B30),
                blurRadius: 20,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(palette.icon, size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _typeLabel(memory.entry),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (memory.entry.isFavorite)
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  memory.entry.title.trim().isEmpty
                      ? memory.trip.title
                      : memory.entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  memory.entry.description.trim().isEmpty
                      ? 'Gespeichert in ${memory.trip.title}'
                      : memory.entry.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      context,
                      Icons.location_on_outlined,
                      memory.entry.location.trim().isEmpty
                          ? '${memory.trip.destination}, ${memory.trip.country}'
                          : memory.entry.location,
                    ),
                    _chip(
                      context,
                      Icons.calendar_today_outlined,
                      TravelVisuals.formatDate(memory.entry.date),
                    ),
                    _chip(context, Icons.flight_outlined, memory.trip.title),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(TripAlbumEntry entry) {
    return TripAlbumEntryTypes.byId(entry.typeId).label;
  }
}

class _TripMemory {
  const _TripMemory({required this.trip, required this.entry});

  final Trip trip;
  final TripAlbumEntry entry;
}
