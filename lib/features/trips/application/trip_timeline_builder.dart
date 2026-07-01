import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

enum TripTimelineEntryKind { plan, memory, expense }

class TripTimelineEntry {
  const TripTimelineEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.sortValue,
    this.isCompleted = false,
  });

  final String id;
  final TripTimelineEntryKind kind;
  final String title;
  final String subtitle;
  final DateTime date;
  final int sortValue;
  final bool isCompleted;

  DateTime get dateOnly => DateTime(date.year, date.month, date.day);
}

class TripTimelineDay {
  const TripTimelineDay({required this.date, required this.entries});

  final DateTime date;
  final List<TripTimelineEntry> entries;
}

class TripTimelineSnapshot {
  const TripTimelineSnapshot({
    required this.days,
    required this.totalEntryCount,
    required this.planEntryCount,
    required this.memoryEntryCount,
    required this.expenseEntryCount,
  });

  final List<TripTimelineDay> days;
  final int totalEntryCount;
  final int planEntryCount;
  final int memoryEntryCount;
  final int expenseEntryCount;

  bool get isEmpty => totalEntryCount == 0;
}

class TripTimelineBuilder {
  const TripTimelineBuilder._();

  static TripTimelineSnapshot build(Trip trip) {
    final entries = <TripTimelineEntry>[
      ...trip.planItems.map(_fromPlanItem),
      ...trip.albumEntries.map(_fromAlbumEntry),
      ...trip.budgetExpenses.map(
        (expense) => _fromExpense(expense, trip.budgetCurrency),
      ),
    ]..sort(_compareEntries);

    final groups = <DateTime, List<TripTimelineEntry>>{};
    for (final entry in entries) {
      groups.putIfAbsent(entry.dateOnly, () => <TripTimelineEntry>[]).add(entry);
    }

    final days = groups.entries
        .map(
          (entry) => TripTimelineDay(
            date: entry.key,
            entries: List<TripTimelineEntry>.unmodifiable(entry.value),
          ),
        )
        .toList(growable: false);

    return TripTimelineSnapshot(
      days: List<TripTimelineDay>.unmodifiable(days),
      totalEntryCount: entries.length,
      planEntryCount: entries
          .where((entry) => entry.kind == TripTimelineEntryKind.plan)
          .length,
      memoryEntryCount: entries
          .where((entry) => entry.kind == TripTimelineEntryKind.memory)
          .length,
      expenseEntryCount: entries
          .where((entry) => entry.kind == TripTimelineEntryKind.expense)
          .length,
    );
  }

  static TripTimelineEntry _fromPlanItem(TripPlanItem item) {
    final location = item.location.trim();
    final details = <String>[
      _formatTimeRange(item),
      item.type.label,
      if (location.isNotEmpty) location,
    ];

    return TripTimelineEntry(
      id: item.id,
      kind: TripTimelineEntryKind.plan,
      title: item.title,
      subtitle: details.join(' · '),
      date: item.startsAt,
      sortValue: item.startMinutes,
      isCompleted: item.isCompleted,
    );
  }

  static TripTimelineEntry _fromAlbumEntry(TripAlbumEntry entry) {
    final type = TripAlbumEntryTypes.byId(entry.typeId);
    final location = entry.location.trim();
    final details = <String>[type.label, if (location.isNotEmpty) location];
    final hasExplicitTime = entry.date.hour != 0 || entry.date.minute != 0;

    return TripTimelineEntry(
      id: entry.id,
      kind: TripTimelineEntryKind.memory,
      title: entry.title,
      subtitle: details.join(' · '),
      date: entry.date,
      sortValue: hasExplicitTime
          ? entry.date.hour * 60 + entry.date.minute
          : 18 * 60,
      isCompleted: entry.isFavorite,
    );
  }

  static TripTimelineEntry _fromExpense(
    TripBudgetExpense expense,
    String currency,
  ) {
    return TripTimelineEntry(
      id: expense.id,
      kind: TripTimelineEntryKind.expense,
      title: expense.title,
      subtitle:
          '${TripMoney.format(expense.amountCents, currency)} · '
          '${expense.category.label} · ${expense.status.label}',
      date: expense.date,
      sortValue: 20 * 60,
      isCompleted: expense.isPaid,
    );
  }

  static int _compareEntries(
    TripTimelineEntry left,
    TripTimelineEntry right,
  ) {
    final dateComparison = left.dateOnly.compareTo(right.dateOnly);
    if (dateComparison != 0) {
      return dateComparison;
    }
    final timeComparison = left.sortValue.compareTo(right.sortValue);
    if (timeComparison != 0) {
      return timeComparison;
    }
    final kindComparison = left.kind.index.compareTo(right.kind.index);
    if (kindComparison != 0) {
      return kindComparison;
    }
    return left.title.toLowerCase().compareTo(right.title.toLowerCase());
  }

  static String _formatTimeRange(TripPlanItem item) {
    final start = _formatMinutes(item.startMinutes);
    final end = item.endMinutes;
    return end == null ? '$start Uhr' : '$start–${_formatMinutes(end)} Uhr';
  }

  static String _formatMinutes(int value) {
    final safeValue = value.clamp(0, 1439).toInt();
    final hours = (safeValue ~/ 60).toString().padLeft(2, '0');
    final minutes = (safeValue % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
