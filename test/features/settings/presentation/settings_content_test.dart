import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/data/backup_provider_registry.dart';
import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';
import 'package:florys_diaries/features/settings/presentation/widgets/settings_content.dart';

void main() {
  testWidgets('settings content stays usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const registry = BackupProviderRegistry();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 1000),
            textScaler: TextScaler.linear(1.2),
          ),
          child: Scaffold(
            body: SettingsContent(
              providers: registry.providers,
              selectedProviderId: BackupProviderId.googleDrive,
              selectedProviderName: 'Google Drive',
              isBusy: false,
              statusText: 'Bereit',
              localBackups: const [],
              isLocalHistoryLoading: false,
              cloudBackups: const [],
              cloudAccountEmail: null,
              isCloudHistoryLoading: false,
              automaticCloudSettings: AutomaticCloudBackupSettings.defaults,
              isAutomaticCloudSettingsLoading: false,
              onProviderSelected: (_) {},
              onUnavailableProviderSelected: (_) {},
              onCreateBackup: () {},
              onRestoreBackup: () {},
              onRefreshCloudBackups: () async {},
              onRestoreCloudBackup: (_) {},
              onDeleteCloudBackup: (_) {},
              onAutomaticCloudEnabledChanged: (_) {},
              onAutomaticCloudIntervalChanged: (_) {},
              onAutomaticCloudRetentionChanged: (_) {},
              onRunAutomaticCloudBackup: () {},
              onCreateLocalBackup: () {},
              onRestoreLocalBackup: (_) async {},
              onDeleteLocalBackup: (_) async {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Sicherheit'), findsOneWidget);
    expect(find.text('Google Drive'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Version'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Version'), findsOneWidget);
  });
}
