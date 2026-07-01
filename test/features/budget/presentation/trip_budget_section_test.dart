import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/budget/presentation/widgets/trip_budget_section.dart';
import 'package:florys_diaries/features/trips/application/trip_store.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/data/trip_storage_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  testWidgets('budget summary remains readable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final trip = Trip(
      id: 'trip-1',
      title: 'Rom',
      destination: 'Rom',
      country: 'Italien',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 4),
      budgetAmountCents: 100000,
      budgetCurrency: 'EUR',
      budgetExpenses: [
        TripBudgetExpense(
          id: 'expense-1',
          title: 'Hotel',
          date: DateTime(2026, 8, 1),
          amountCents: 32000,
          category: TripExpenseCategory.accommodation,
          status: TripExpenseStatus.paid,
        ),
      ],
    );
    final store = TripStore(
      storageService: _FakeTripStorageService([trip]),
      now: () => DateTime(2026, 7, 1),
    );
    await store.load();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      TripStoreScope(
        store: store,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TripBudgetSection(trip: trip),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Reisekosten & Budget'), findsOneWidget);
    expect(find.text('1.000,00 €'), findsOneWidget);
    expect(find.text('320,00 €'), findsWidgets);
    expect(find.text('Hotel'), findsOneWidget);
    expect(find.text('Nach Kategorie'), findsOneWidget);
    expect(find.text('Nach Reisetag'), findsOneWidget);
  });
}

class _FakeTripStorageService extends TripStorageService {
  _FakeTripStorageService(List<Trip> trips) : _trips = List<Trip>.from(trips);

  List<Trip> _trips;

  @override
  Future<List<Trip>> loadTrips() async => List<Trip>.from(_trips);

  @override
  Future<void> saveTrips(List<Trip> trips) async {
    _trips = List<Trip>.from(trips);
  }
}
