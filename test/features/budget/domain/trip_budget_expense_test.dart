import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  test('expense json round trip preserves all values', () {
    final expense = TripBudgetExpense(
      id: 'expense-1',
      title: 'Hotel',
      date: DateTime(2026, 8, 2),
      amountCents: 24990,
      category: TripExpenseCategory.accommodation,
      status: TripExpenseStatus.paid,
      notes: 'Zwei Nächte',
    );

    final restored = TripBudgetExpense.fromJson(expense.toJson());

    expect(restored.id, 'expense-1');
    expect(restored.title, 'Hotel');
    expect(restored.dateOnly, DateTime(2026, 8, 2));
    expect(restored.amountCents, 24990);
    expect(restored.category, TripExpenseCategory.accommodation);
    expect(restored.status, TripExpenseStatus.paid);
    expect(restored.notes, 'Zwei Nächte');
  });

  test('trip calculates paid planned and remaining budget', () {
    final trip = Trip(
      id: 'trip-1',
      title: 'Rom',
      destination: 'Rom',
      country: 'Italien',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 4),
      budgetAmountCents: 100000,
      budgetExpenses: [
        TripBudgetExpense(
          id: 'paid',
          title: 'Hotel',
          date: DateTime(2026, 8, 1),
          amountCents: 30000,
          category: TripExpenseCategory.accommodation,
          status: TripExpenseStatus.paid,
        ),
        TripBudgetExpense(
          id: 'planned',
          title: 'Museum',
          date: DateTime(2026, 8, 2),
          amountCents: 15000,
          category: TripExpenseCategory.activities,
        ),
      ],
    );

    expect(trip.paidExpenseCents, 30000);
    expect(trip.plannedExpenseCents, 15000);
    expect(trip.totalExpenseCents, 45000);
    expect(trip.remainingBudgetCents, 55000);
    expect(trip.budgetProgress, 0.45);
  });

  test('money parser accepts comma and dot decimals', () {
    expect(TripMoney.parseToCents('1.234,56'), 123456);
    expect(TripMoney.parseToCents('1234.56'), 123456);
    expect(TripMoney.parseToCents('89,9'), 8990);
    expect(TripMoney.parseToCents('0'), isNull);
    expect(TripMoney.format(123456, 'EUR'), '1.234,56 €');
  });
}
