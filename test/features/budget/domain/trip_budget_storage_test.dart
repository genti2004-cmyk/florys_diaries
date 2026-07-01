import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/trips/data/trip_storage_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  late Directory directory;
  late TripStorageService storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('florys_budget_test_');
    storage = TripStorageService(
      documentsDirectoryProvider: () async => directory,
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('storage persists budget and expenses', () async {
    final trip = Trip(
      id: 'trip-1',
      title: 'Paris',
      destination: 'Paris',
      country: 'Frankreich',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 4),
      budgetAmountCents: 150000,
      budgetCurrency: 'EUR',
      budgetExpenses: [
        TripBudgetExpense(
          id: 'expense-1',
          title: 'Hotel',
          date: DateTime(2026, 9, 1),
          amountCents: 42000,
          category: TripExpenseCategory.accommodation,
          status: TripExpenseStatus.paid,
        ),
      ],
    );

    await storage.saveTrips([trip]);
    final loaded = await storage.loadTrips();

    expect(loaded.single.budgetAmountCents, 150000);
    expect(loaded.single.budgetCurrency, 'EUR');
    expect(loaded.single.budgetExpenses.single.title, 'Hotel');
    expect(loaded.single.paidExpenseCents, 42000);
  });
}
