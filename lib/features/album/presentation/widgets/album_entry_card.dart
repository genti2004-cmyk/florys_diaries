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
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconForType(entry.typeId), color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: entry.isFavorite
                              ? 'Lieblingsmoment entfernen'
                              : 'Als Lieblingsmoment markieren',
                          onPressed: onFavoriteToggle,
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
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _AlbumChip(label: type.label),
                        _AlbumChip(label: _formatDate(entry.date)),
                        if (entry.location.trim().isNotEmpty)
                          _AlbumChip(label: entry.location.trim()),
                      ],
                    ),
                    if (entry.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _AlbumChip extends StatelessWidget {
  const _AlbumChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
