import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';

class BackupProviderSelector extends StatelessWidget {
  const BackupProviderSelector({
    required this.providers,
    required this.selectedId,
    required this.isBusy,
    required this.onSelected,
    required this.onUnavailableSelected,
    super.key,
  });

  final List<BackupProvider> providers;
  final BackupProviderId selectedId;
  final bool isBusy;
  final ValueChanged<BackupProviderId> onSelected;
  final ValueChanged<BackupProvider> onUnavailableSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.cloud_sync_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup-Ziel',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Backups können auf dem Gerät oder im privaten Google-Drive-App-Datenordner gespeichert werden.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...List.generate(providers.length, (index) {
              final provider = providers[index];
              return Column(
                children: [
                  _ProviderTile(
                    provider: provider,
                    isSelected: provider.id == selectedId,
                    isBusy: isBusy,
                    onTap: () {
                      if (provider.isAvailable) {
                        onSelected(provider.id);
                      } else {
                        onUnavailableSelected(provider);
                      }
                    },
                  ),
                  if (index != providers.length - 1) const Divider(height: 1),
                ],
              );
            }),
            const SizedBox(height: 10),
            Text(
              'Google Drive ist verfügbar und verwendet ausschließlich den versteckten App-Datenordner. OneDrive und Dropbox bleiben vorbereitet.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({
    required this.provider,
    required this.isSelected,
    required this.isBusy,
    required this.onTap,
  });

  final BackupProvider provider;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isBusy;
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected
                  ? AppColors.primarySoft
                  : AppColors.surfaceSoft,
              foregroundColor: isSelected
                  ? AppColors.primary
                  : AppColors.textMuted,
              child: Icon(_iconFor(provider.id)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    provider.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _ProviderStatus(
              isAvailable: provider.isAvailable,
              isSelected: isSelected,
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(BackupProviderId id) {
    return switch (id) {
      BackupProviderId.device => Icons.phone_android_outlined,
      BackupProviderId.googleDrive => Icons.add_to_drive_outlined,
      BackupProviderId.oneDrive => Icons.cloud_outlined,
      BackupProviderId.dropbox => Icons.cloud_queue_outlined,
    };
  }
}

class _ProviderStatus extends StatelessWidget {
  const _ProviderStatus({required this.isAvailable, required this.isSelected});

  final bool isAvailable;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final label = isSelected
        ? 'Aktiv'
        : isAvailable
        ? 'Verfügbar'
        : 'Vorbereitet';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySoft : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
