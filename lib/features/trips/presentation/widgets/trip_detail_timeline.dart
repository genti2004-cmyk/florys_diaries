import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/trips/application/trip_timeline_builder.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_timeline_day_view.dart';

class TripDetailTimeline extends StatefulWidget {
  const TripDetailTimeline({
    required this.trip,
    required this.onOpenPlanning,
    required this.onOpenMemories,
    this.now,
    super.key,
  });

  final Trip trip;
  final VoidCallback onOpenPlanning;
  final VoidCallback onOpenMemories;
  final DateTime? now;

  @override
  State<TripDetailTimeline> createState() => _TripDetailTimelineState();
}

class _TripDetailTimelineState extends State<TripDetailTimeline> {
  static const int _collapsedDayCount = 4;

  bool _expanded = false;

  @override
  void didUpdateWidget(covariant TripDetailTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.id != widget.trip.id) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = TripTimelineBuilder.build(widget.trip);
    if (snapshot.isEmpty) {
      return _EmptyTimeline(onOpenPlanning: widget.onOpenPlanning);
    }

    final today = _dateOnly(widget.now ?? DateTime.now());
    final visibleDays = _visibleDays(snapshot.days, today);
    final hiddenDayCount = snapshot.days.length - visibleDays.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: _TimelineHeader(snapshot: snapshot),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            child: Column(
              children: [
                for (var index = 0; index < visibleDays.length; index++)
                  TripTimelineDayView(
                    trip: widget.trip,
                    day: visibleDays[index],
                    today: today,
                    isLast: index == visibleDays.length - 1,
                    onEntryTap: _openEntry,
                  ),
              ],
            ),
          ),
          if (snapshot.days.length > _collapsedDayCount)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: const ValueKey<String>('trip-timeline-toggle'),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                  label: Text(
                    _expanded
                        ? 'Weniger anzeigen'
                        : '$hiddenDayCount weitere Reisetage anzeigen',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<TripTimelineDay> _visibleDays(
    List<TripTimelineDay> days,
    DateTime today,
  ) {
    if (_expanded || days.length <= _collapsedDayCount) {
      return days;
    }

    final firstCurrentOrFuture = days.indexWhere(
      (day) => !_dateOnly(day.date).isBefore(today),
    );

    if (firstCurrentOrFuture == -1) {
      return days.sublist(days.length - _collapsedDayCount);
    }

    final maximumStart = days.length - _collapsedDayCount;
    final start = (firstCurrentOrFuture - 1).clamp(0, maximumStart).toInt();
    return days.sublist(start, start + _collapsedDayCount);
  }

  void _openEntry(TripTimelineEntry entry) {
    switch (entry.kind) {
      case TripTimelineEntryKind.plan:
      case TripTimelineEntryKind.expense:
        widget.onOpenPlanning();
        return;
      case TripTimelineEntryKind.memory:
        widget.onOpenMemories();
        return;
    }
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({required this.snapshot});

  final TripTimelineSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.plum],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.route_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reise-Timeline',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${snapshot.totalEntryCount} Einträge auf '
                    '${snapshot.days.length} Reisetagen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CountChip(
              icon: Icons.event_note_rounded,
              label: '${snapshot.planEntryCount} Planung',
              color: AppColors.primary,
            ),
            _CountChip(
              icon: Icons.favorite_rounded,
              label: '${snapshot.memoryEntryCount} Momente',
              color: AppColors.rose,
            ),
            _CountChip(
              icon: Icons.receipt_long_rounded,
              label: '${snapshot.expenseEntryCount} Ausgaben',
              color: AppColors.sand,
            ),
          ],
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({required this.onOpenPlanning});

  final VoidCallback onOpenPlanning;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.route_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Deine Reise-Timeline ist noch leer',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Programmpunkte, Momente und Ausgaben erscheinen hier '
            'automatisch in chronologischer Reihenfolge.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onOpenPlanning,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tagesplan öffnen'),
          ),
        ],
      ),
    );
  }
}


DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
