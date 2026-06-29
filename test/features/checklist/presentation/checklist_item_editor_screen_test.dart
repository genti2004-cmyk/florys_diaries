import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';
import 'package:florys_diaries/features/checklist/presentation/screens/checklist_item_editor_screen.dart';

void main() {
  testWidgets(
    'editing a checklist item preserves source and clears the due date',
    (tester) async {
      final original = TripChecklistItem(
        id: 'checklist-1',
        title: 'Reisepass einpacken',
        category: TripChecklistCategory.documents,
        priority: TripChecklistPriority.high,
        createdAt: DateTime(2026, 6, 1),
        notes: 'Bestehende Notiz',
        dueDate: DateTime(2026, 6, 28),
        isCompleted: true,
        sourceKey: 'passport',
      );
      final result = ValueNotifier<ChecklistItemEditorResult?>(null);
      addTearDown(result.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: _ChecklistEditorLauncher(
            item: original,
            onResult: (value) => result.value = value,
          ),
        ),
      );

      await tester.tap(find.text('Editor öffnen'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('checklist-editor-title')),
        'Reisepass kontrollieren',
      );
      await tester.tap(find.byTooltip('Datum entfernen'));
      await tester.pump();
      final saveButton = find.byKey(
        const ValueKey<String>('checklist-editor-save'),
      );
      await tester.scrollUntilVisible(
        saveButton,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final saved = result.value?.item;
      expect(saved, isNotNull);
      expect(saved!.id, original.id);
      expect(saved.title, 'Reisepass kontrollieren');
      expect(saved.category, original.category);
      expect(saved.priority, original.priority);
      expect(saved.createdAt, original.createdAt);
      expect(saved.notes, original.notes);
      expect(saved.dueDate, isNull);
      expect(saved.isCompleted, isTrue);
      expect(saved.sourceKey, original.sourceKey);
      expect(result.value?.delete, isFalse);
    },
  );

  testWidgets('back asks before unsaved checklist changes are discarded', (
    tester,
  ) async {
    final result = ValueNotifier<ChecklistItemEditorResult?>(null);
    addTearDown(result.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: _ChecklistEditorLauncher(
          onResult: (value) => result.value = value,
        ),
      ),
    );

    await tester.tap(find.text('Editor öffnen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('checklist-editor-title')),
      'Noch nicht gespeichert',
    );
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Checklisten-Änderungen verwerfen?'), findsOneWidget);
    expect(find.text('Weiter bearbeiten'), findsOneWidget);

    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.byType(ChecklistItemEditorScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Änderungen verwerfen'));
    await tester.pumpAndSettle();

    expect(find.text('Editor öffnen'), findsOneWidget);
    expect(result.value, isNull);
  });
}

class _ChecklistEditorLauncher extends StatelessWidget {
  const _ChecklistEditorLauncher({required this.onResult, this.item});

  final TripChecklistItem? item;
  final ValueChanged<ChecklistItemEditorResult?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await Navigator.of(context)
                .push<ChecklistItemEditorResult>(
                  MaterialPageRoute<ChecklistItemEditorResult>(
                    builder: (_) => ChecklistItemEditorScreen(
                      tripStartDate: DateTime(2026, 7, 1),
                      item: item,
                    ),
                  ),
                );
            onResult(result);
          },
          child: const Text('Editor öffnen'),
        ),
      ),
    );
  }
}
