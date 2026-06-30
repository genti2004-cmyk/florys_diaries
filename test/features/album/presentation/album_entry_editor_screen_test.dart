import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/album/presentation/screens/album_entry_editor_screen.dart';

void main() {
  testWidgets('editing an album entry preserves all existing metadata', (
    tester,
  ) async {
    final original = TripAlbumEntry(
      id: 'album-1',
      typeId: TripAlbumEntryTypes.highlight.id,
      date: DateTime(2026, 7, 4),
      title: 'Alter Titel',
      description: 'Bestehende Erinnerung',
      location: 'Prizren',
      isFavorite: true,
    );
    final result = ValueNotifier<AlbumEntryEditorResult?>(null);
    addTearDown(result.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: _AlbumEditorLauncher(
          entry: original,
          onResult: (value) => result.value = value,
        ),
      ),
    );

    await tester.tap(find.text('Editor öffnen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('album-editor-title')),
      'Neuer Titel',
    );
    final saveButton = find.byKey(const ValueKey<String>('album-editor-save'));
    await tester.scrollUntilVisible(
      saveButton,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final saved = result.value?.entry;
    expect(saved, isNotNull);
    expect(saved!.id, original.id);
    expect(saved.title, 'Neuer Titel');
    expect(saved.typeId, original.typeId);
    expect(saved.date, original.date);
    expect(saved.description, original.description);
    expect(saved.location, original.location);
    expect(saved.isFavorite, isTrue);
    expect(result.value?.delete, isFalse);
  });

  testWidgets('back asks before unsaved album changes are discarded', (
    tester,
  ) async {
    final result = ValueNotifier<AlbumEntryEditorResult?>(null);
    addTearDown(result.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: _AlbumEditorLauncher(onResult: (value) => result.value = value),
      ),
    );

    await tester.tap(find.text('Editor öffnen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('album-editor-title')),
      'Noch nicht gespeichert',
    );
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Momentänderungen verwerfen?'), findsOneWidget);
    expect(find.text('Weiter bearbeiten'), findsOneWidget);

    await tester.tap(find.text('Weiter bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumEntryEditorScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Änderungen verwerfen'));
    await tester.pumpAndSettle();

    expect(find.text('Editor öffnen'), findsOneWidget);
    expect(result.value, isNull);
  });
}

class _AlbumEditorLauncher extends StatelessWidget {
  const _AlbumEditorLauncher({required this.onResult, this.entry});

  final TripAlbumEntry? entry;
  final ValueChanged<AlbumEntryEditorResult?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await Navigator.of(context)
                .push<AlbumEntryEditorResult>(
                  MaterialPageRoute<AlbumEntryEditorResult>(
                    builder: (_) => AlbumEntryEditorScreen(
                      tripStartDate: DateTime(2026, 7, 1),
                      entry: entry,
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
