import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';

class AlbumEntryCard extends StatelessWidget {
  const AlbumEntryCard({
    required this.entry,
    required this.onTap,
    required this.onFavoriteToggle,
    super.key,
  });

  final TripAlbumEntry entry;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final type = TripAlbumEntryTypes.byId(entry.typeId);
    final accent = _accentForType(entry.typeId);
    final icon = _iconForType(entry.typeId);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.18),
                        accent.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              entry.title.trim().isEmpty
                                  ? 'Moment'
                                  : entry.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: entry.isFavorite
                                ? 'Lieblingsmoment entfernen'
                                : 'Als Lieblingsmoment markieren',
                            onPressed: onFavoriteToggle,
                            visualDensity: VisualDensity.compact,
                            icon: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: entry.isFavorite
                                    ? AppColors.sand.withValues(alpha: 0.16)
                                    : AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                entry.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: entry.isFavorite
                                    ? AppColors.sand
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: icon,
                            label: type.label,
                            accent: accent,
                            highlighted: true,
                          ),
                          _InfoChip(
                            icon: Icons.calendar_today_outlined,
                            label: _formatDate(entry.date),
                            accent: AppColors.primary,
                          ),
                          if (entry.location.trim().isNotEmpty)
                            _InfoChip(
                              icon: Icons.place_rounded,
                              label: entry.location.trim(),
                              accent: AppColors.plum,
                            ),
                        ],
                      ),
                      if (entry.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          entry.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  static Color _accentForType(String typeId) {
    return switch (typeId) {
      'highlight' => AppColors.primary,
      'place' => AppColors.plum,
      'food' => AppColors.sand,
      'memory' => AppColors.rose,
      _ => AppColors.sage,
    };
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.accent,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted
            ? accent.withValues(alpha: 0.12)
            : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: highlighted ? accent : AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
