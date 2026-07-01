import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/trips/application/trip_timeline_builder.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripTimelineDayView extends StatelessWidget {
  const TripTimelineDayView({
    super.key,
    required this.trip,
    required this.day,
    required this.today,
    required this.isLast,
    required this.onEntryTap,
  });

  final Trip trip;
  final TripTimelineDay day;
  final DateTime today;
  final bool isLast;
  final ValueChanged<TripTimelineEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    final isToday = _dateOnly(day.date) == today;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 62,
            child: _DayBadge(
              label: _dayLabel(trip, day.date),
              weekday: _weekday(day.date.weekday),
              date: _formatDate(day.date),
              isToday: isToday,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(top: 13),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primary : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isToday ? AppColors.primary : AppColors.border,
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  for (var index = 0; index < day.entries.length; index++) ...[
                    _TimelineEntryCard(
                      entry: day.entries[index],
                      onTap: () => onEntryTap(day.entries[index]),
                    ),
                    if (index < day.entries.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({
    required this.label,
    required this.weekday,
    required this.date,
    required this.isToday,
  });

  final String label;
  final String weekday;
  final String date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isToday ? AppColors.primary : AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            weekday,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            date,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Heute',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineEntryCard extends StatelessWidget {
  const _TimelineEntryCard({required this.entry, required this.onTap});

  final TripTimelineEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _EntryVisual.forKind(entry.kind);

    return Material(
      key: ValueKey<String>(
        'trip-timeline-${entry.kind.name}-${entry.id}',
      ),
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(visual.icon, size: 20, color: visual.color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              if (entry.isCompleted)
                Icon(
                  entry.kind == TripTimelineEntryKind.memory
                      ? Icons.star_rounded
                      : Icons.check_circle_rounded,
                  size: 19,
                  color: entry.kind == TripTimelineEntryKind.memory
                      ? AppColors.rose
                      : AppColors.success,
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryVisual {
  const _EntryVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static _EntryVisual forKind(TripTimelineEntryKind kind) {
    return switch (kind) {
      TripTimelineEntryKind.plan => const _EntryVisual(
        icon: Icons.event_note_rounded,
        color: AppColors.primary,
      ),
      TripTimelineEntryKind.memory => const _EntryVisual(
        icon: Icons.favorite_rounded,
        color: AppColors.rose,
      ),
      TripTimelineEntryKind.expense => const _EntryVisual(
        icon: Icons.receipt_long_rounded,
        color: AppColors.sand,
      ),
    };
  }
}

String _dayLabel(Trip trip, DateTime date) {
  final start = _dateOnly(trip.startDate);
  final current = _dateOnly(date);
  final end = _dateOnly(trip.endDate);

  if (current.isBefore(start)) {
    return 'Vor Reise';
  }
  if (current.isAfter(end)) {
    return 'Danach';
  }
  return 'Tag ${current.difference(start).inDays + 1}';
}

String _weekday(int weekday) {
  return const <String>['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][weekday - 1];
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.';
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
