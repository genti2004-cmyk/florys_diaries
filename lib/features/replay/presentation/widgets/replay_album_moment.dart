import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_document_moment.dart';

class ReplayAlbumMoment extends StatelessWidget {
  const ReplayAlbumMoment({required this.entry, super.key});

  final TripAlbumEntry entry;

  @override
  Widget build(BuildContext context) {
    final type = TripAlbumEntryTypes.byId(entry.typeId);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: entry.isFavorite
                    ? AppColors.primarySoft
                    : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                _iconFor(entry.typeId),
                color: entry.isFavorite
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      if (entry.isFavorite)
                        const Icon(
                          Icons.favorite_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  if (entry.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (entry.location.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ReplayMemoryInfoLine(
                      icon: Icons.place_outlined,
                      text: entry.location,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String typeId) {
    if (typeId == TripAlbumEntryTypes.highlight.id) {
      return Icons.star_rounded;
    }
    if (typeId == TripAlbumEntryTypes.place.id) {
      return Icons.location_city_outlined;
    }
    if (typeId == TripAlbumEntryTypes.food.id) {
      return Icons.restaurant_outlined;
    }
    if (typeId == TripAlbumEntryTypes.memory.id) {
      return Icons.favorite_border_rounded;
    }
    return Icons.notes_rounded;
  }
}

class ReplayPhotoSummary extends StatelessWidget {
  const ReplayPhotoSummary({required this.photoCount, super.key});

  final int photoCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ReplayMemoryInfoLine(
          icon: Icons.photo_library_outlined,
          text:
              '$photoCount Fotos sind für diese Reise erfasst. '
              'Gespeicherte Bilddateien erscheinen einzeln im Replay.',
        ),
      ),
    );
  }
}
