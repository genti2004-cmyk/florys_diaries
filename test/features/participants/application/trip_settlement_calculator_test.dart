import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/participants/application/trip_settlement_calculator.dart';
import 'package:florys_diaries/features/participants/domain/trip_participant.dart';

void main() {
  test('calculates the simplest transfer for a shared paid expense', () {
    const alex = TripParticipant(id: 'alex', name: 'Alex');
    const bea = TripParticipant(id: 'bea', name: 'Bea');
    final result = TripSettlementCalculator.calculate(
      participants: const [alex, bea],
      expenses: [
        TripBudgetExpense(
          id: 'expense-1',
          title: 'Hotel',
          date: DateTime(2026, 8, 1),
          amountCents: 10000,
          category: TripExpenseCategory.accommodation,
          status: TripExpenseStatus.paid,
          paidByParticipantId: alex.id,
          participantIds: const ['alex', 'bea'],
        ),
      ],
    );

    expect(
      result.balances
          .singleWhere((item) => item.participant.id == alex.id)
          .balanceCents,
      5000,
    );
    expect(
      result.balances
          .singleWhere((item) => item.participant.id == bea.id)
          .balanceCents,
      -5000,
    );
    expect(result.transfers, hasLength(1));
    expect(result.transfers.single.fromParticipantId, bea.id);
    expect(result.transfers.single.toParticipantId, alex.id);
    expect(result.transfers.single.amountCents, 5000);
  });

  test('ignores planned and unassigned expenses', () {
    const alex = TripParticipant(id: 'alex', name: 'Alex');
    const bea = TripParticipant(id: 'bea', name: 'Bea');
    final result = TripSettlementCalculator.calculate(
      participants: const [alex, bea],
      expenses: [
        TripBudgetExpense(
          id: 'planned',
          title: 'Museum',
          date: DateTime(2026, 8, 2),
          amountCents: 4000,
          category: TripExpenseCategory.activities,
          paidByParticipantId: alex.id,
          participantIds: const ['alex', 'bea'],
        ),
        TripBudgetExpense(
          id: 'unassigned',
          title: 'Taxi',
          date: DateTime(2026, 8, 2),
          amountCents: 2000,
          category: TripExpenseCategory.transport,
          status: TripExpenseStatus.paid,
        ),
      ],
    );

    expect(result.transfers, isEmpty);
    expect(result.balances.every((item) => item.balanceCents == 0), isTrue);
  });
}
