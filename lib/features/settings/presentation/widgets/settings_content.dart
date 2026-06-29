import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/constants/app_metadata.dart';
import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';
import 'package:florys_diaries/features/backup/domain/backup_sync_status.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';
import 'package:florys_diaries/features/backup/domain/google_drive_backup_models.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/backup_panel.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/backup_provider_selector.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/backup_sync_status_card.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/google_drive_automatic_backup_settings.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/google_drive_backup_history.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/local_backup_history.dart';
import 'package:florys_diaries/features/settings/presentation/widgets/settings_overview_card.dart';
import 'package:florys_diaries/features/settings/presentation/widgets/settings_section_header.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({
    super.key,
    required this.providers,
    required this.backupSyncStatus,
    required this.selectedProviderId,
    required this.selectedProviderName,
    required this.isBusy,
    required this.statusText,
    required this.localBackups,
    required this.isLocalHistoryLoading,
    required this.cloudBackups,
    required this.cloudAccountEmail,
    required this.isCloudHistoryLoading,
    required this.automaticCloudSettings,
    required this.isAutomaticCloudSettingsLoading,
    required this.onProviderSelected,
    required this.onUnavailableProviderSelected,
    required this.onCreateBackup,
    required this.onRestoreBackup,
    required this.onRefreshCloudBackups,
    required this.onRestoreCloudBackup,
    required this.onDeleteCloudBackup,
    required this.onAutomaticCloudEnabledChanged,
    required this.onAutomaticCloudIntervalChanged,
    required this.onAutomaticCloudRetentionChanged,
    required this.onRunAutomaticCloudBackup,
    required this.onCreateLocalBackup,
    required this.onRestoreLocalBackup,
    required this.onDeleteLocalBackup,
  });

  final List<BackupProvider> providers;
  final BackupSyncStatus backupSyncStatus;
  final BackupProviderId selectedProviderId;
  final String selectedProviderName;
  final bool isBusy;
  final String? statusText;
  final List<LocalBackupEntry> localBackups;
  final bool isLocalHistoryLoading;
  final List<GoogleDriveStoredBackup> cloudBackups;
  final String? cloudAccountEmail;
  final bool isCloudHistoryLoading;
  final AutomaticCloudBackupSettings automaticCloudSettings;
  final bool isAutomaticCloudSettingsLoading;
  final ValueChanged<BackupProviderId> onProviderSelected;
  final ValueChanged<BackupProvider> onUnavailableProviderSelected;
  final VoidCallback onCreateBackup;
  final VoidCallback onRestoreBackup;
  final Future<void> Function() onRefreshCloudBackups;
  final ValueChanged<GoogleDriveStoredBackup> onRestoreCloudBackup;
  final ValueChanged<GoogleDriveStoredBackup> onDeleteCloudBackup;
  final ValueChanged<bool> onAutomaticCloudEnabledChanged;
  final ValueChanged<int> onAutomaticCloudIntervalChanged;
  final ValueChanged<int> onAutomaticCloudRetentionChanged;
  final VoidCallback onRunAutomaticCloudBackup;
  final VoidCallback onCreateLocalBackup;
  final Future<void> Function(LocalBackupEntry entry) onRestoreLocalBackup;
  final Future<void> Function(LocalBackupEntry entry) onDeleteLocalBackup;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        key: const PageStorageKey<String>('settings-content'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            'Sicherung & App',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            'Backups verwalten, Wiederherstellung prüfen und App-Informationen ansehen.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          SettingsOverviewCard(
            providerName: selectedProviderName,
            localBackupCount: localBackups.length,
            cloudBackupCount: cloudBackups.length,
            cloudAccountEmail: cloudAccountEmail,
            automaticCloudEnabled: automaticCloudSettings.enabled,
            syncStatus: backupSyncStatus,
          ),
          const SizedBox(height: 14),
          const SettingsSectionHeader(
            title: 'Backup & Synchronisierung',
            subtitle:
                'Sicherungsziel auswählen, neue Backups erstellen und bestehende Stände prüfen.',
          ),
          BackupProviderSelector(
            providers: providers,
            selectedId: selectedProviderId,
            isBusy: isBusy,
            onSelected: onProviderSelected,
            onUnavailableSelected: onUnavailableProviderSelected,
          ),
          const SizedBox(height: 12),
          BackupPanel(
            providerName: selectedProviderName,
            isBusy: isBusy,
            statusText: statusText,
            onCreateBackup: onCreateBackup,
            onRestoreBackup: onRestoreBackup,
          ),
          const SizedBox(height: 12),
          BackupSyncStatusCard(status: backupSyncStatus),
          if (selectedProviderId == BackupProviderId.googleDrive) ...[
            const SizedBox(height: 12),
            GoogleDriveBackupHistory(
              entries: cloudBackups,
              accountEmail: cloudAccountEmail,
              isLoading: isCloudHistoryLoading,
              isBusy: isBusy,
              onRefresh: onRefreshCloudBackups,
              onRestore: onRestoreCloudBackup,
              onDelete: onDeleteCloudBackup,
            ),
            const SizedBox(height: 12),
            GoogleDriveAutomaticBackupSettings(
              settings: automaticCloudSettings,
              isLoading: isAutomaticCloudSettingsLoading,
              isBusy: isBusy,
              onEnabledChanged: onAutomaticCloudEnabledChanged,
              onIntervalChanged: onAutomaticCloudIntervalChanged,
              onRetentionChanged: onAutomaticCloudRetentionChanged,
              onRunNow: onRunAutomaticCloudBackup,
            ),
          ],
          const SizedBox(height: 12),
          LocalBackupHistory(
            entries: localBackups,
            isLoading: isLocalHistoryLoading,
            isBusy: isBusy,
            onCreateLocalBackup: onCreateLocalBackup,
            onRestore: onRestoreLocalBackup,
            onDelete: onDeleteLocalBackup,
          ),
          const SizedBox(height: 14),
          const SettingsSectionHeader(
            title: 'App & Datenschutz',
            subtitle: 'Lokale Speicherung, zukünftiger App-Schutz und Version.',
          ),
          const AppSectionCard(
            icon: Icons.lock_outline_rounded,
            title: 'Sicherheit',
            subtitle:
                'Reisedaten werden lokal auf diesem Gerät gespeichert. PIN und Biometrie sind für eine spätere Version vorgesehen.',
          ),
          const SizedBox(height: 12),
          const AppSectionCard(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle:
                '${AppMetadata.name} ${AppMetadata.displayVersion} – '
                'Release Candidate mit gehärteter Daten-, Dokument- und '
                'Backup-Sicherheit.',
          ),
        ],
      ),
    );
  }
}
