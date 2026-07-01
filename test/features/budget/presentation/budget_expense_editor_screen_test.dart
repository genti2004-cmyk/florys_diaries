import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/budget/presentation/screens/budget_expense_editor_screen.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  testWidgets('creates an expense for the selected trip day', (tester) async {
    final trip = Trip(
      id: 'trip-1',
      title: 'Wien',
      destination: 'Wien',
      country: 'Österreich',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 4),
      budgetAmountCents: 100000,
      budgetCurrency: 'EUR',
    );
    BudgetExpenseEditorResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: _EditorLauncher(
          trip: trip,
          onResult: (value) => result = value,
        ),
      ),
    );

    await tester.tap(find.text('Editor öffnen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('expense-editor-title')),
      'Abendessen',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('expense-editor-amount')),
      '48,50',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('expense-editor-save')),
    );
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.delete, isFalse);
    expect(result!.expense.title, 'Abendessen');
    expect(result!.expense.amountCents, 4850);
    expect(result!.expense.dateOnly, DateTime(2026, 8, 1));
    expect(result!.expense.category, TripExpenseCategory.other);
    expect(find.text('Editor öffnen'), findsOneWidget);
  });
}

class _EditorLauncher extends StatelessWidget {
  const _EditorLauncher({required this.trip, required this.onResult});

  final Trip trip;
  final ValueChanged<BudgetExpenseEditorResult> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await Navigator.of(context)
                .push<BudgetExpenseEditorResult>(
                  MaterialPageRoute<BudgetExpenseEditorResult>(
                    builder: (_) => BudgetExpenseEditorScreen(
                      trip: trip,
                      initialDate: trip.startDate,
                    ),
                  ),
                );
            if (result != null) {
              onResult(result);
            }
          },
          child: const Text('Editor öffnen'),
        ),
      ),
    );
  }
}
