import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';
import 'package:florys_diaries/features/backup/domain/backup_integrity_level.dart';
import 'package:florys_diaries/features/settings/presentation/widgets/backup_restore_preview.dart';

void main() {
  testWidgets(
    'Wiederherstellungsübersicht bleibt auf schmalem Display nutzbar',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final inspection = AppBackupInspectionResult(
        backupCreatedAt: DateTime(2026, 6, 28, 12, 30),
        tripCount: 5,
        fileCount: 8,
        sizeBytes: 2048,
        appVersion: '0.19.0',
        countryCount: 3,
        destinationCount: 4,
        documentCount: 6,
        albumEntryCount: 7,
        checklistItemCount: 9,
        firstTripStartAt: DateTime(2024, 1, 1),
        lastTripEndAt: DateTime(2026, 12, 31),
        integrityLevel: BackupIntegrityLevel.sha256,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BackupRestorePreview(
                fileName: 'FlorysDiaries_Backup_Test.zip',
                inspection: inspection,
                sourceLabel: 'Google Drive',
                sourceDetail: 'Konto: test@example.com',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Google Drive'), findsOneWidget);
      expect(find.text('Konto: test@example.com'), findsOneWidget);
      expect(find.text('Reiseinhalt'), findsOneWidget);
      expect(find.text('Gesicherte Inhalte'), findsOneWidget);
      expect(find.text('Sicherheitsprüfung'), findsOneWidget);
      expect(
        find.text('SHA-256-Integrität geprüft'),
        findsNWidgets(2),
      );
      expect(find.text('App-Version: 0.19.0 · 2.0 KB'), findsOneWidget);
      expect(find.text('01.01.2024 – 31.12.2026'), findsOneWidget);
    },
  );
}
