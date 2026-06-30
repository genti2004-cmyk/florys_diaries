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

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  _iconForType(entry.typeId),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title.trim().isEmpty ? 'Moment' : entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(type.label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (entry.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: entry.isFavorite
                    ? 'Lieblingsmoment entfernen'
                    : 'Als Lieblingsmoment markieren',
                onPressed: onFavoriteToggle,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  entry.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: entry.isFavorite
                      ? AppColors.sand
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(String typeLabel) {
    final parts = <String>[typeLabel, _formatDate(entry.date)];
    if (entry.location.trim().isNotEmpty) {
      parts.add(entry.location.trim());
    }
    return parts.join(' · ');
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

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
