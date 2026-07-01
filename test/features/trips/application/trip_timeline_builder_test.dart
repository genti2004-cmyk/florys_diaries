import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/trips/application/trip_timeline_builder.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  test('builds a chronological timeline from travel content', () {
    final trip = Trip(
      id: 'trip-1',
      title: 'Berlin',
      destination: 'Berlin',
      country: 'Deutschland',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 4),
      planItems: [
        TripPlanItem(
          id: 'plan-2',
          title: 'Abendessen',
          date: DateTime(2026, 7, 2),
          startMinutes: 19 * 60,
          type: TripPlanItemType.restaurant,
        ),
        TripPlanItem(
          id: 'plan-1',
          title: 'Museumsinsel',
          date: DateTime(2026, 7, 1),
          startMinutes: 10 * 60,
          endMinutes: 12 * 60,
          type: TripPlanItemType.sight,
          location: 'Mitte',
          isCompleted: true,
        ),
      ],
      albumEntries: [
        TripAlbumEntry(
          id: 'memory-1',
          typeId: TripAlbumEntryTypes.highlight.id,
          date: DateTime(2026, 7, 1),
          title: 'Sonnenuntergang',
          location: 'Spree',
          isFavorite: true,
        ),
      ],
      budgetCurrency: 'EUR',
      budgetExpenses: [
        TripBudgetExpense(
          id: 'expense-1',
          title: 'Hotel',
          date: DateTime(2026, 7, 1),
          amountCents: 23500,
          category: TripExpenseCategory.accommodation,
          status: TripExpenseStatus.paid,
        ),
      ],
    );

    final snapshot = TripTimelineBuilder.build(trip);

    expect(snapshot.totalEntryCount, 4);
    expect(snapshot.planEntryCount, 2);
    expect(snapshot.memoryEntryCount, 1);
    expect(snapshot.expenseEntryCount, 1);
    expect(snapshot.days, hasLength(2));
    expect(snapshot.days.first.date, DateTime(2026, 7, 1));
    expect(
      snapshot.days.first.entries.map((entry) => entry.kind),
      [
        TripTimelineEntryKind.plan,
        TripTimelineEntryKind.memory,
        TripTimelineEntryKind.expense,
      ],
    );
    expect(snapshot.days.first.entries.first.subtitle, '10:00–12:00 Uhr · Sehenswürdigkeit · Mitte');
    expect(snapshot.days.first.entries.last.subtitle, contains('235,00 €'));
    expect(snapshot.days.last.entries.single.title, 'Abendessen');
  });

  test('returns an empty snapshot for a trip without timeline content', () {
    final trip = Trip(
      id: 'empty',
      title: 'Leer',
      destination: 'Bonn',
      country: 'Deutschland',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 2),
    );

    final snapshot = TripTimelineBuilder.build(trip);

    expect(snapshot.isEmpty, isTrue);
    expect(snapshot.days, isEmpty);
  });
}
