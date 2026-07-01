import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';
import 'package:florys_diaries/features/participants/domain/trip_participant.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/templates/application/trip_clone_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  test('shifts reusable trip content and excludes paid expenses', () {
    final source = Trip(
      id: 'source',
      title: 'Rom',
      destination: 'Rom',
      country: 'Italien',
      startDate: DateTime(2026, 5, 10),
      endDate: DateTime(2026, 5, 12),
      participants: const [
        TripParticipant(id: 'alex', name: 'Alex'),
        TripParticipant(id: 'bea', name: 'Bea'),
      ],
      planItems: [
        TripPlanItem(
          id: 'plan-1',
          title: 'Kolosseum',
          date: DateTime(2026, 5, 11),
          startMinutes: 600,
          type: TripPlanItemType.sight,
          linkedDocumentId: 'ticket-1',
          reminderMinutesBefore: 60,
        ),
      ],
      checklistItems: [
        TripChecklistItem(
          id: 'check-1',
          title: 'Koffer packen',
          category: TripChecklistCategory.luggage,
          priority: TripChecklistPriority.high,
          createdAt: DateTime(2026, 4, 1),
          dueDate: DateTime(2026, 5, 9),
          isCompleted: true,
        ),
      ],
      budgetAmountCents: 100000,
      budgetExpenses: [
        TripBudgetExpense(
          id: 'planned',
          title: 'Hotel',
          date: DateTime(2026, 5, 10),
          amountCents: 30000,
          category: TripExpenseCategory.accommodation,
          paidByParticipantId: 'alex',
          participantIds: const ['alex', 'bea'],
        ),
        TripBudgetExpense(
          id: 'paid',
          title: 'Flug',
          date: DateTime(2026, 5, 10),
          amountCents: 25000,
          category: TripExpenseCategory.transport,
          status: TripExpenseStatus.paid,
        ),
      ],
    );

    final cloned = TripCloneService.clone(
      source: source,
      newId: 'clone',
      title: 'Rom 2027',
      startDate: DateTime(2027, 6, 20),
    );

    expect(cloned.startDate, DateTime(2027, 6, 20));
    expect(cloned.endDate, DateTime(2027, 6, 22));
    expect(cloned.planItems.single.dateOnly, DateTime(2027, 6, 21));
    expect(cloned.planItems.single.linkedDocumentId, isNull);
    expect(cloned.planItems.single.reminderMinutesBefore, 60);
    expect(cloned.checklistItems.single.dueDate, DateTime(2027, 6, 19));
    expect(cloned.checklistItems.single.isCompleted, isFalse);
    expect(cloned.budgetExpenses, hasLength(1));
    expect(cloned.budgetExpenses.single.status, TripExpenseStatus.planned);
    expect(cloned.participants, hasLength(2));
    expect(cloned.budgetExpenses.single.participantIds, hasLength(2));
    expect(cloned.documents, isEmpty);
    expect(cloned.albumEntries, isEmpty);
  });
}
