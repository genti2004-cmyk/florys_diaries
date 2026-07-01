import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/documents/presentation/screens/document_editor_screen.dart';

void main() {
  testWidgets('editing a document preserves favorite and file metadata', (
    tester,
  ) async {
    final original = TravelDocument(
      id: 'document-1',
      title: 'Flugticket',
      categoryId: DocumentCategories.flight.id,
      createdAt: DateTime(2026, 6, 1),
      description: 'Bestehende Beschreibung',
      fileName: 'ticket.pdf',
      relativePath: 'documents/trip-1/document-1.pdf',
      fileSizeBytes: 4096,
      fileExtension: 'pdf',
      isFavorite: true,
      expiresAt: DateTime(2027, 6, 1),
      expiryReminderDaysBefore: 30,
    );
    final result = ValueNotifier<DocumentEditorResult?>(null);
    addTearDown(result.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: _DocumentEditorLauncher(
          document: original,
          onResult: (value) => result.value = value,
        ),
      ),
    );

    await tester.tap(find.text('Editor öffnen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('document-editor-title')),
      'Aktualisiertes Flugticket',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('document-editor-save')),
    );
    await tester.pumpAndSettle();

    final saved = result.value?.document;
    expect(saved, isNotNull);
    expect(saved!.title, 'Aktualisiertes Flugticket');
    expect(saved.description, original.description);
    expect(saved.createdAt, original.createdAt);
    expect(saved.fileName, original.fileName);
    expect(saved.relativePath, original.relativePath);
    expect(saved.fileSizeBytes, original.fileSizeBytes);
    expect(saved.fileExtension, original.fileExtension);
    expect(saved.isFavorite, isTrue);
    expect(saved.expiresAt, original.expiresAt);
    expect(
      saved.expiryReminderDaysBefore,
      original.expiryReminderDaysBefore,
    );
    expect(result.value?.delete, isFalse);
  });

  testWidgets('back asks before unsaved document changes are discarded', (
    tester,
  ) async {
    final result = ValueNotifier<DocumentEditorResult?>(null);
    addTearDown(result.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: _DocumentEditorLauncher(
          onResult: (value) => result.value = value,
        ),
      ),
    );

    await tester.tap(find.text('Editor öffnen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('document-editor-title')),
      'Noch nicht gespeichert',
    );
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Dokumentänderungen verwerfen?'), findsOneWidget);
    expect(find.text('Weiter bearbeiten'), findsOneWidget);

    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentEditorScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Änderungen verwerfen'));
    await tester.pumpAndSettle();

    expect(find.text('Editor öffnen'), findsOneWidget);
    expect(result.value, isNull);
  });
}

class _DocumentEditorLauncher extends StatelessWidget {
  const _DocumentEditorLauncher({required this.onResult, this.document});

  final TravelDocument? document;
  final ValueChanged<DocumentEditorResult?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await Navigator.of(context)
                .push<DocumentEditorResult>(
                  MaterialPageRoute<DocumentEditorResult>(
                    builder: (_) => DocumentEditorScreen(
                      tripId: 'trip-1',
                      document: document,
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
