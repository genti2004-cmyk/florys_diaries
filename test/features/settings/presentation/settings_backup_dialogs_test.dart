import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/settings/presentation/widgets/settings_backup_dialogs.dart';

void main() {
  testWidgets('delete dialog remains usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showLocalBackupDeleteDialog(
                      context,
                      LocalBackupEntry(
                        file: File(
                          'FlorysDiaries_Backup_mit_einem_sehr_langen_Dateinamen.zip',
                        ),
                        createdAt: DateTime(2026, 6, 29),
                        sizeBytes: 2048,
                        isAutomatic: false,
                      ),
                    );
                  },
                  child: const Text('Dialog öffnen'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Lokales Backup löschen?'), findsOneWidget);
    expect(find.text('Löschen'), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
