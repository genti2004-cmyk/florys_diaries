import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/domain/google_drive_backup_models.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/google_drive_backup_history.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/local_backup_history.dart';

void main() {
  testWidgets('Cloud-Historie benennt die sichere Restore-Aktion eindeutig', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoogleDriveBackupHistory(
            entries: [
              GoogleDriveStoredBackup(
                id: 'cloud-1',
                name: 'FlorysDiaries_Backup_Test.zip',
                createdAt: DateTime(2026, 6, 28, 12),
                sizeBytes: 2048,
                isAutomatic: false,
              ),
            ],
            accountEmail: 'test@example.com',
            isLoading: false,
            isBusy: false,
            onRefresh: () async {},
            onRestore: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Prüfen & wiederherstellen'), findsOneWidget);
  });

  testWidgets('Lokale Historie verwendet dieselbe Restore-Bezeichnung', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalBackupHistory(
            entries: [
              LocalBackupEntry(
                file: File('C:/temp/FlorysDiaries_Backup_Test.zip'),
                createdAt: DateTime(2026, 6, 28, 12),
                sizeBytes: 2048,
                isAutomatic: false,
              ),
            ],
            isLoading: false,
            isBusy: false,
            onCreateLocalBackup: () {},
            onRestore: (_) async {},
            onDelete: (_) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Backup-Aktionen'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Prüfen & wiederherstellen'), findsOneWidget);
  });
  testWidgets('beschädigtes lokales Backup kann nur gelöscht werden', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalBackupHistory(
            entries: [
              LocalBackupEntry(
                file: File('C:/temp/FlorysDiaries_Backup_Beschaedigt.zip'),
                createdAt: DateTime(2026, 6, 28, 12),
                sizeBytes: 512,
                isAutomatic: true,
                isValid: false,
                validationError:
                    'Die Sicherung ist beschädigt oder unvollständig.',
              ),
            ],
            isLoading: false,
            isBusy: false,
            onCreateLocalBackup: () {},
            onRestore: (_) async {},
            onDelete: (_) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Beschädigt ·'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('local-backup-warning')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Backup-Aktionen'));
    await tester.pumpAndSettle();

    expect(find.text('Prüfen & wiederherstellen'), findsNothing);
    expect(find.text('Löschen'), findsOneWidget);
  });
}
