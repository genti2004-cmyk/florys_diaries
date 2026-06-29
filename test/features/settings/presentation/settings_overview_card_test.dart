import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/domain/backup_sync_status.dart';
import 'package:florys_diaries/features/settings/presentation/widgets/settings_overview_card.dart';

void main() {
  testWidgets('settings overview remains usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SettingsOverviewCard(
              providerName: 'Google Drive',
              localBackupCount: 4,
              cloudBackupCount: 6,
              cloudAccountEmail: 'ein.sehr.langes.konto@example.com',
              automaticCloudEnabled: true,
              syncStatus: BackupSyncStatus.initial(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sicherung im Blick'), findsOneWidget);
    expect(find.text('Aktives Ziel: Google Drive'), findsOneWidget);
    expect(find.text('Lokal'), findsOneWidget);
    expect(find.text('Drive'), findsOneWidget);
    expect(find.text('Automatik'), findsOneWidget);
  });
}
