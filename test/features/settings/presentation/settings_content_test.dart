import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/data/backup_provider_registry.dart';
import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';
import 'package:florys_diaries/features/backup/domain/backup_sync_status.dart';
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
              backupSyncStatus: const BackupSyncStatus.initial(),
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
              onOpenPrivacy: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Sicherung & App'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('Automatische Backup-Synchronisierung'),
      250,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Automatische Backup-Synchronisierung'), findsOneWidget);
    expect(find.text('Google Drive'), findsWidgets);
    expect(find.text('Microsoft OneDrive'), findsNothing);
    expect(find.text('Dropbox'), findsNothing);
    expect(find.textContaining('bleiben vorbereitet'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Sicherheit'),
      350,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sicherheit'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Version'),
      350,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Version'), findsOneWidget);
  });

  testWidgets(
    'automatic Google Drive switch is visible before selecting Google Drive',
    (tester) async {
      const registry = BackupProviderRegistry();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsContent(
              providers: registry.providers,
              backupSyncStatus: const BackupSyncStatus.initial(),
              selectedProviderId: BackupProviderId.device,
              selectedProviderName: 'Auf diesem Gerät',
              isBusy: false,
              statusText: null,
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
              onOpenPrivacy: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final automaticSettings = find.text(
        'Automatische Google-Drive-Sicherung',
      );
      await tester.scrollUntilVisible(
        automaticSettings,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(automaticSettings, findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Google-Drive-Backups'), findsNothing);
    },
  );

  testWidgets('privacy card invokes its navigation callback', (tester) async {
    var opened = false;
    const registry = BackupProviderRegistry();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsContent(
            providers: registry.providers,
            backupSyncStatus: const BackupSyncStatus.initial(),
            selectedProviderId: BackupProviderId.device,
            selectedProviderName: 'Auf diesem Gerät',
            isBusy: false,
            statusText: null,
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
            onOpenPrivacy: () => opened = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final privacyCard = find.byKey(
      const ValueKey<String>('open-privacy-and-data'),
    );
    await tester.scrollUntilVisible(
      privacyCard,
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(privacyCard);
    await tester.pump();

    expect(opened, isTrue);
  });
}
