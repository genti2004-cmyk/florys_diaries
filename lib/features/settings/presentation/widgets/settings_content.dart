import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';
import 'package:florys_diaries/features/backup/domain/google_drive_backup_models.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/backup_panel.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/backup_provider_selector.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/google_drive_automatic_backup_settings.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/google_drive_backup_history.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/local_backup_history.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({
    super.key,
    required this.providers,
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionCard(
            icon: Icons.lock_outline,
            title: 'Sicherheit',
            subtitle: 'PIN, Biometrie und verschlüsselte Ablage folgen später.',
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          const AppSectionCard(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle:
                'FlorysDiaries v0.19.0 – Stabilität, Performance und sichere Backups.',
          ),
        ],
      ),
    );
  }
}
