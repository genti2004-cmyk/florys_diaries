import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/planner/presentation/screens/plan_item_editor_screen.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  testWidgets('creates a program item for the selected trip day', (tester) async {
    final trip = Trip(
      id: 'trip-1',
      title: 'Wien',
      destination: 'Wien',
      country: 'Österreich',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 4),
    );
    PlanItemEditorResult? result;

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
      find.byKey(const ValueKey<String>('plan-editor-title')),
      'Schloss Schönbrunn',
    );
    await tester.tap(find.byKey(const ValueKey<String>('plan-editor-save')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.delete, isFalse);
    expect(result!.item.title, 'Schloss Schönbrunn');
    expect(result!.item.dateOnly, DateTime(2026, 8, 1));
    expect(result!.item.type, TripPlanItemType.activity);
    expect(find.text('Editor öffnen'), findsOneWidget);
  });
}

class _EditorLauncher extends StatelessWidget {
  const _EditorLauncher({required this.trip, required this.onResult});

  final Trip trip;
  final ValueChanged<PlanItemEditorResult> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<PlanItemEditorResult>(
              MaterialPageRoute<PlanItemEditorResult>(
                builder: (_) => PlanItemEditorScreen(
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
