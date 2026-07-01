import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/templates/data/trip_template_service.dart';
import 'package:florys_diaries/features/templates/domain/trip_template.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  test('stores and removes trip templates', () async {
    final directory = await Directory.systemTemp.createTemp('florys-template-');
    addTearDown(() => directory.delete(recursive: true));
    final service = TripTemplateService(
      directoryProvider: () async => directory,
    );
    final template = TripTemplate(
      id: 'template-1',
      name: 'Städtereise',
      createdAt: DateTime(2026, 7, 1),
      sourceTrip: Trip(
        id: 'trip-1',
        title: 'Rom',
        destination: 'Rom',
        country: 'Italien',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 3),
        budgetExpenses: [
          TripBudgetExpense(
            id: 'paid',
            title: 'Flug',
            date: DateTime(2026, 8, 1),
            amountCents: 20000,
            category: TripExpenseCategory.transport,
            status: TripExpenseStatus.paid,
          ),
          TripBudgetExpense(
            id: 'planned',
            title: 'Museum',
            date: DateTime(2026, 8, 2),
            amountCents: 3000,
            category: TripExpenseCategory.activities,
          ),
        ],
      ),
    );

    await service.add(template);
    final loaded = await service.load();

    expect(loaded, hasLength(1));
    expect(loaded.single.name, 'Städtereise');
    expect(loaded.single.sourceTrip.destination, 'Rom');
    expect(loaded.single.sourceTrip.budgetExpenses, hasLength(1));
    expect(
      loaded.single.sourceTrip.budgetExpenses.single.status,
      TripExpenseStatus.planned,
    );

    await service.delete(template.id);
    expect(await service.load(), isEmpty);
  });
}
