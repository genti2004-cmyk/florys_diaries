import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/participants/domain/trip_participant.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  test('trip keeps participants and expense split during JSON round trip', () {
    final trip = Trip(
      id: 'trip-1',
      title: 'Rom',
      destination: 'Rom',
      country: 'Italien',
      startDate: DateTime(2026, 7, 10),
      endDate: DateTime(2026, 7, 14),
      participants: const [
        TripParticipant(id: 'p1', name: 'Ali'),
        TripParticipant(id: 'p2', name: 'Flory'),
      ],
      budgetExpenses: [
        TripBudgetExpense(
          id: 'expense-1',
          title: 'Hotel',
          date: DateTime(2026, 7, 10),
          amountCents: 42000,
          category: TripExpenseCategory.accommodation,
          status: TripExpenseStatus.paid,
          paidByParticipantId: 'p1',
          participantIds: const ['p1', 'p2'],
        ),
      ],
    );

    final restored = Trip.fromJson(trip.toJson());

    expect(restored.participants, hasLength(2));
    expect(restored.participants[0].name, 'Ali');
    expect(restored.participants[1].name, 'Flory');
    expect(restored.budgetExpenses, hasLength(1));
    expect(restored.budgetExpenses.single.paidByParticipantId, 'p1');
    expect(restored.budgetExpenses.single.participantIds, ['p1', 'p2']);
  });
}
