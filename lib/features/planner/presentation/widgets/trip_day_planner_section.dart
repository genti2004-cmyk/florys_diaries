import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/planner/presentation/screens/plan_item_editor_screen.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripDayPlannerSection extends StatefulWidget {
  const TripDayPlannerSection({required this.trip, super.key});

  final Trip trip;

  @override
  State<TripDayPlannerSection> createState() => _TripDayPlannerSectionState();
}

class _TripDayPlannerSectionState extends State<TripDayPlannerSection> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _initialDate(widget.trip);
  }

  @override
  void didUpdateWidget(covariant TripDayPlannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.startDate != widget.trip.startDate ||
        oldWidget.trip.endDate != widget.trip.endDate) {
      _selectedDate = _clampDate(_selectedDate, widget.trip);
    }
  }

  Future<void> _openEditor({TripPlanItem? item}) async {
    final store = TripStoreScope.of(context);
    final result = await Navigator.of(context).push<PlanItemEditorResult>(
      MaterialPageRoute<PlanItemEditorResult>(
        builder: (_) => PlanItemEditorScreen(
          trip: widget.trip,
          item: item,
          initialDate: _selectedDate,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final items = List<TripPlanItem>.from(widget.trip.planItems);
    if (result.delete) {
      items.removeWhere((candidate) => candidate.id == result.item.id);
    } else {
      final index = items.indexWhere(
        (candidate) => candidate.id == result.item.id,
      );
      if (index == -1) {
        items.add(result.item);
      } else {
        items[index] = result.item;
      }
    }
    _sortItems(items);

    try {
      await store.updateTrip(widget.trip.copyWith(planItems: items));
      if (mounted && !result.delete) {
        setState(() => _selectedDate = result.item.dateOnly);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Der Programmpunkt konnte nicht gespeichert werden.');
      }
    }
  }

  Future<void> _toggleCompleted(TripPlanItem item) async {
    final store = TripStoreScope.of(context);
    final items = widget.trip.planItems
        .map(
          (candidate) => candidate.id == item.id
              ? candidate.copyWith(isCompleted: !candidate.isCompleted)
              : candidate,
        )
        .toList(growable: true);
    _sortItems(items);

    try {
      await store.updateTrip(widget.trip.copyWith(planItems: items));
    } catch (_) {
      if (mounted) {
        _showMessage('Der Status konnte nicht gespeichert werden.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsForDate(widget.trip.planItems, _selectedDate);
    final total = widget.trip.planItemCount;
    final completed = widget.trip.planCompletedCount;
    final dayNumber = _selectedDate
            .difference(_dateOnly(widget.trip.startDate))
            .inDays +
        1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlannerOverviewCard(
          total: total,
          completed: completed,
          plannedDays: widget.trip.plannedDayCount,
          onAdd: () => _openEditor(),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tagesplan',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tag $dayNumber von ${widget.trip.durationDays}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Eintrag'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DaySelector(
          trip: widget.trip,
          selectedDate: _selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          _EmptyDayCard(
            date: _selectedDate,
            onAdd: () => _openEditor(),
          )
        else
          ...items.indexed.map(
            (indexed) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TimelineItemCard(
                item: indexed.$2,
                isLast: indexed.$1 == items.length - 1,
                documentTitle: _documentTitle(indexed.$2.linkedDocumentId),
                onTap: () => _openEditor(item: indexed.$2),
                onCompletedToggle: () => _toggleCompleted(indexed.$2),
              ),
            ),
          ),
      ],
    );
  }

  String? _documentTitle(String? documentId) {
    if (documentId == null || documentId.isEmpty) {
      return null;
    }
    for (final document in widget.trip.documents) {
      if (document.id == documentId) {
        return document.title;
      }
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static List<TripPlanItem> _itemsForDate(
    List<TripPlanItem> items,
    DateTime date,
  ) {
    final selected = items
        .where((item) => _sameDate(item.date, date))
        .toList(growable: true);
    _sortItems(selected);
    return selected;
  }

  static void _sortItems(List<TripPlanItem> items) {
    items.sort((left, right) {
      final dateComparison = left.dateOnly.compareTo(right.dateOnly);
      if (dateComparison != 0) {
        return dateComparison;
      }
      final timeComparison = left.sortValue.compareTo(right.sortValue);
      if (timeComparison != 0) {
        return timeComparison;
      }
      return left.title.toLowerCase().compareTo(right.title.toLowerCase());
    });
  }

  static DateTime _initialDate(Trip trip) {
    final today = _dateOnly(DateTime.now());
    final start = _dateOnly(trip.startDate);
    final end = _dateOnly(trip.endDate);
    if (!today.isBefore(start) && !today.isAfter(end)) {
      return today;
    }
    if (trip.planItems.isNotEmpty) {
      return _clampDate(trip.planItems.first.dateOnly, trip);
    }
    return start;
  }

  static DateTime _clampDate(DateTime date, Trip trip) {
    final normalized = _dateOnly(date);
    final start = _dateOnly(trip.startDate);
    final end = _dateOnly(trip.endDate);
    if (normalized.isBefore(start)) {
      return start;
    }
    if (normalized.isAfter(end)) {
      return end;
    }
    return normalized;
  }

  static bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class _PlannerOverviewCard extends StatelessWidget {
  const _PlannerOverviewCard({
    required this.total,
    required this.completed,
    required this.plannedDays,
    required this.onAdd,
  });

  final int total;
  final int completed;
  final int plannedDays;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF142B4F), Color(0xFF2D5BDE)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x242D5BDE),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.calendar_view_day_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dein Reiseprogramm',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total == 0
                            ? 'Plane Aktivitäten, Orte und Uhrzeiten pro Reisetag.'
                            : '$completed von $total Programmpunkten erledigt.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OverviewMetric(
                    value: '$total',
                    label: total == 1 ? 'Eintrag' : 'Einträge',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OverviewMetric(
                    value: '$plannedDays',
                    label: plannedDays == 1 ? 'Tag geplant' : 'Tage geplant',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OverviewMetric(
                    value: '$completed',
                    label: 'Erledigt',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Programmpunkt hinzufügen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.trip,
    required this.selectedDate,
    required this.onSelected,
  });

  final Trip trip;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        key: const PageStorageKey<String>('trip-day-planner-days'),
        scrollDirection: Axis.horizontal,
        itemCount: trip.durationDays,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = DateTime(
            trip.startDate.year,
            trip.startDate.month,
            trip.startDate.day + index,
          );
          final selected = _sameDate(date, selectedDate);
          final count = trip.planItems
              .where((item) => _sameDate(item.date, date))
              .length;

          return Semantics(
            button: true,
            selected: selected,
            label: 'Tag ${index + 1}, ${_formatDate(date)}, $count Einträge',
            child: Material(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => onSelected(date),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weekday(date),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.82)
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${date.day}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: selected ? Colors.white : AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        count == 0 ? '–' : '$count',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.82)
                              : AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static bool _sameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static String _weekday(DateTime date) {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return weekdays[date.weekday - 1];
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard({required this.date, required this.onAdd});

  final DateTime date;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
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
                Icons.event_available_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Dieser Reisetag ist noch frei',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Füge für ${_formatDate(date)} eine Aktivität, einen Flug, ein Hotel oder einen Ort hinzu.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ersten Eintrag anlegen'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _TimelineItemCard extends StatelessWidget {
  const _TimelineItemCard({
    required this.item,
    required this.isLast,
    required this.documentTitle,
    required this.onTap,
    required this.onCompletedToggle,
  });

  final TripPlanItem item;
  final bool isLast;
  final String? documentTitle;
  final VoidCallback onTap;
  final VoidCallback onCompletedToggle;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForType(item.type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        SizedBox(
          width: 54,
          child: Column(
            children: [
              Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _formatMinutes(item.startMinutes),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Card(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.type.icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        decoration: item.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                tooltip: item.isCompleted
                                    ? 'Als offen markieren'
                                    : 'Als erledigt markieren',
                                onPressed: onCompletedToggle,
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  item.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: item.isCompleted
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 8,
                            runSpacing: 7,
                            children: [
                              _InfoChip(
                                icon: Icons.schedule_rounded,
                                label: _timeRange(item),
                                color: accent,
                              ),
                              _InfoChip(
                                icon: item.type.icon,
                                label: item.type.label,
                                color: accent,
                              ),
                              if (item.location.trim().isNotEmpty)
                                _InfoChip(
                                  icon: Icons.place_rounded,
                                  label: item.location.trim(),
                                  color: AppColors.plum,
                                ),
                            ],
                          ),
                          if (item.notes.trim().isNotEmpty) ...[
                            const SizedBox(height: 9),
                            Text(
                              item.notes,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                          if (documentTitle != null) ...[
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                const Icon(
                                  Icons.attach_file_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    documentTitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ],
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
          ),
        ],
      ),
    );
  }

  static Color _accentForType(TripPlanItemType type) {
    return switch (type) {
      TripPlanItemType.activity => AppColors.primary,
      TripPlanItemType.flight => const Color(0xFF4D7BC5),
      TripPlanItemType.hotel => AppColors.plum,
      TripPlanItemType.restaurant => AppColors.sand,
      TripPlanItemType.sight => AppColors.rose,
      TripPlanItemType.transport => AppColors.sage,
    };
  }

  static String _timeRange(TripPlanItem item) {
    final start = _formatMinutes(item.startMinutes);
    final end = item.endMinutes;
    return end == null ? start : '$start – ${_formatMinutes(end)}';
  }

  static String _formatMinutes(int value) {
    final safe = value.clamp(0, 1439).toInt();
    final hour = (safe ~/ 60).toString().padLeft(2, '0');
    final minute = (safe % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
