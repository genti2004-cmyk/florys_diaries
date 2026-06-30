import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';
import 'package:florys_diaries/features/checklist/presentation/screens/trip_checklist_screen.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripChecklistSection extends StatelessWidget {
  const TripChecklistSection({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final total = trip.checklistItems.length;
    final completed = trip.checklistCompletedCount;
    final open = total - completed;
    final overdue = trip.checklistOverdueCount;
    final progress = total == 0 ? 0.0 : completed / total;
    final previewItems = _previewItems(trip.checklistItems);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checkliste',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alle Aufgaben für diese Reise auf einen Blick.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _openChecklist(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Öffnen'),
                  SizedBox(width: 3),
                  Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: InkWell(
            onTap: () => _openChecklist(context),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _ProgressRing(progress: progress),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              total == 0
                                  ? 'Bereit für deine Planung'
                                  : '$completed von $total erledigt',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              total == 0
                                  ? 'Lege eigene Aufgaben an oder nutze intelligente Vorschläge.'
                                  : overdue > 0
                                  ? '$overdue überfällig · $open offen'
                                  : open == 0
                                  ? 'Alles vorbereitet.'
                                  : '$open Aufgaben sind noch offen.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: overdue > 0
                                        ? AppColors.danger
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  if (previewItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    ...previewItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ChecklistPreviewItem(item: item),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceSoft,
                      color: progress >= 1 ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openChecklist(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TripChecklistScreen(trip: trip)),
    );
  }

  static List<TripChecklistItem> _previewItems(
    List<TripChecklistItem> source,
  ) {
    final items = source.where((item) => !item.isCompleted).toList();
    items.sort((left, right) {
      if (left.isOverdue != right.isOverdue) {
        return left.isOverdue ? -1 : 1;
      }
      final priority = right.priority.weight.compareTo(left.priority.weight);
      if (priority != 0) {
        return priority;
      }
      final leftDate = left.dueDate ?? DateTime(2200);
      final rightDate = right.dueDate ?? DateTime(2200);
      return leftDate.compareTo(rightDate);
    });
    return items.take(2).toList(growable: false);
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: AppColors.surfaceSoft,
            color: progress >= 1 ? AppColors.success : AppColors.primary,
          ),
          Text(
            '${(progress * 100).round()}%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistPreviewItem extends StatelessWidget {
  const _ChecklistPreviewItem({required this.item});

  final TripChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final warning = item.isOverdue || item.isDueSoon;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: warning
                ? const Color(0xFFFFF1E8)
                : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.category.icon,
            size: 17,
            color: warning ? AppColors.warning : AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.isOverdue
                    ? 'Überfällig'
                    : item.dueDate == null
                    ? item.category.label
                    : 'Fällig am ${_formatDate(item.dueDate!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: item.isOverdue
                      ? AppColors.danger
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
