import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/replay/domain/replay_event.dart';

class ReplayTimelineView extends StatelessWidget {
  const ReplayTimelineView({
    required this.events,
    required this.currentIndex,
    required this.onEventTap,
    super.key,
  });

  final List<ReplayEvent> events;
  final int currentIndex;
  final ValueChanged<int> onEventTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < events.length; index++)
          _ReplayTimelineTile(
            event: events[index],
            index: index,
            isActive: index == currentIndex,
            isLast: index == events.length - 1,
            onTap: () => onEventTap(index),
          ),
      ],
    );
  }
}

class _ReplayTimelineTile extends StatelessWidget {
  const _ReplayTimelineTile({
    required this.event,
    required this.index,
    required this.isActive,
    required this.isLast,
    required this.onTap,
  });

  final ReplayEvent event;
  final int index;
  final bool isActive;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? AppColors.primary : AppColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primarySoft
                        : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Icon(_iconFor(event.type), size: 20, color: iconColor),
                ),
                if (!isLast)
                  Container(width: 2, height: 34, color: AppColors.border),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primarySoft : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        Text(
                          _formatDate(event.date),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    if (event.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.subtitle,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(ReplayEventType type) {
    switch (type) {
      case ReplayEventType.start:
        return Icons.flag_outlined;
      case ReplayEventType.destination:
        return Icons.place_outlined;
      case ReplayEventType.document:
        return Icons.description_outlined;
      case ReplayEventType.photo:
        return Icons.photo_library_outlined;
      case ReplayEventType.note:
        return Icons.notes_outlined;
      case ReplayEventType.highlight:
        return Icons.star_rounded;
      case ReplayEventType.place:
        return Icons.location_city_outlined;
      case ReplayEventType.food:
        return Icons.restaurant_outlined;
      case ReplayEventType.memory:
        return Icons.favorite_border_rounded;
      case ReplayEventType.end:
        return Icons.emoji_events_outlined;
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
