import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_detail_snapshot_card.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_detail_timeline.dart';

void main() {
  testWidgets('timeline and snapshot remain usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var planningCalls = 0;
    var memoryCalls = 0;
    final trip = _tripWithTimeline();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TripDetailSnapshotCard(trip: trip),
                const SizedBox(height: 16),
                TripDetailTimeline(
                  trip: trip,
                  now: DateTime(2026, 7, 2),
                  onOpenPlanning: () => planningCalls++,
                  onOpenMemories: () => memoryCalls++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Reise-Timeline'), findsOneWidget);
    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('Programmpunkte'), findsOneWidget);
    expect(find.text('Budget übrig'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('trip-timeline-plan-plan-1')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('trip-timeline-memory-memory-1')),
    );
    await tester.pump();

    expect(planningCalls, 1);
    expect(memoryCalls, 1);
  });

  testWidgets('empty timeline opens planning from its call to action', (
    tester,
  ) async {
    var planningCalls = 0;
    final trip = Trip(
      id: 'empty',
      title: 'Leer',
      destination: 'Bonn',
      country: 'Deutschland',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripDetailTimeline(
            trip: trip,
            onOpenPlanning: () => planningCalls++,
            onOpenMemories: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tagesplan öffnen'));
    await tester.pump();

    expect(planningCalls, 1);
  });
}

Trip _tripWithTimeline() {
  return Trip(
    id: 'trip-1',
    title: 'Berlin',
    destination: 'Berlin',
    country: 'Deutschland',
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 5),
    planItems: [
      TripPlanItem(
        id: 'plan-1',
        title: 'Stadtführung',
        date: DateTime(2026, 7, 2),
        startMinutes: 10 * 60,
        type: TripPlanItemType.sight,
      ),
    ],
    albumEntries: [
      TripAlbumEntry(
        id: 'memory-1',
        typeId: TripAlbumEntryTypes.highlight.id,
        date: DateTime(2026, 7, 2),
        title: 'Lieblingsmoment',
        isFavorite: true,
      ),
    ],
    budgetAmountCents: 100000,
    budgetCurrency: 'EUR',
    budgetExpenses: [
      TripBudgetExpense(
        id: 'expense-1',
        title: 'Hotel',
        date: DateTime(2026, 7, 1),
        amountCents: 30000,
        category: TripExpenseCategory.accommodation,
        status: TripExpenseStatus.paid,
      ),
    ],
  );
}
