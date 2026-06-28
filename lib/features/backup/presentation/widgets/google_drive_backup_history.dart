import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/backup/domain/google_drive_backup_models.dart';

class GoogleDriveBackupHistory extends StatelessWidget {
  const GoogleDriveBackupHistory({
    required this.entries,
    required this.accountEmail,
    required this.isLoading,
    required this.isBusy,
    required this.onRefresh,
    required this.onRestore,
    required this.onDelete,
    super.key,
  });

  final List<GoogleDriveStoredBackup> entries;
  final String? accountEmail;
  final bool isLoading;
  final bool isBusy;
  final Future<void> Function() onRefresh;
  final ValueChanged<GoogleDriveStoredBackup> onRestore;
  final ValueChanged<GoogleDriveStoredBackup> onDelete;

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
                    Icons.history_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google-Drive-Backup-Historie',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountEmail == null
                            ? 'Mehrere Sicherungsstände getrennt verwalten.'
                            : 'Konto: $accountEmail',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isBusy || isLoading ? null : onRefresh,
                  tooltip: 'Cloud-Historie aktualisieren',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (entries.isEmpty)
              _EmptyCloudHistory(onRefresh: isBusy ? null : onRefresh)
            else
              ...List.generate(entries.length, (index) {
                final entry = entries[index];
                return Column(
                  children: [
                    _CloudBackupTile(
                      entry: entry,
                      isNewest: index == 0,
                      isBusy: isBusy,
                      onRestore: () => onRestore(entry),
                      onDelete: () => onDelete(entry),
                    ),
                    if (index != entries.length - 1) const Divider(height: 1),
                  ],
                );
              }),
            const SizedBox(height: 12),
            Text(
              'Manuelle Cloud-Backups bleiben erhalten. Nur automatische Sicherungen werden nach der eingestellten Aufbewahrungsgrenze bereinigt.',
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

class _EmptyCloudHistory extends StatelessWidget {
  const _EmptyCloudHistory({required this.onRefresh});

  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            'Noch keine Cloud-Sicherung geladen.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.cloud_sync_outlined),
            label: const Text('Historie laden'),
          ),
        ],
      ),
    );
  }
}

class _HistoryBadge extends StatelessWidget {
  const _HistoryBadge({required this.label, required this.emphasized});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.primarySoft : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: emphasized ? AppColors.primary : AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CloudBackupTile extends StatelessWidget {
  const _CloudBackupTile({
    required this.entry,
    required this.isNewest,
    required this.isBusy,
    required this.onRestore,
    required this.onDelete,
  });

  final GoogleDriveStoredBackup entry;
  final bool isNewest;
  final bool isBusy;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isNewest
                ? AppColors.primarySoft
                : AppColors.surfaceSoft,
            foregroundColor: isNewest ? AppColors.primary : AppColors.textMuted,
            child: Icon(isNewest ? Icons.cloud_done : Icons.cloud_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDateTime(entry.createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (entry.isAutomatic)
                          _HistoryBadge(
                            label: 'Automatisch',
                            emphasized: false,
                          ),
                        if (isNewest)
                          const _HistoryBadge(
                            label: 'Neueste',
                            emphasized: true,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatBytes(entry.sizeBytes)} · ${entry.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onRestore,
                      icon: const Icon(Icons.restore, size: 18),
                      label: const Text('Prüfen & wiederherstellen'),
                    ),
                    TextButton.icon(
                      onPressed: isBusy ? null : onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Löschen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}, '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
