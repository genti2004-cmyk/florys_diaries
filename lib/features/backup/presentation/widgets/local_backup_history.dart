import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';

class LocalBackupHistory extends StatelessWidget {
  const LocalBackupHistory({
    required this.entries,
    required this.isLoading,
    required this.isBusy,
    required this.onCreateLocalBackup,
    required this.onRestore,
    required this.onDelete,
    super.key,
  });

  final List<LocalBackupEntry> entries;
  final bool isLoading;
  final bool isBusy;
  final VoidCallback onCreateLocalBackup;
  final Future<void> Function(LocalBackupEntry entry) onRestore;
  final Future<void> Function(LocalBackupEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final invalidCount = entries.where((entry) => !entry.isValid).length;

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
                        'Lokale Backup-Historie',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Automatisch bleiben die 7 neuesten Sicherungen erhalten. Vor einer Wiederherstellung werden zusätzlich bis zu 3 Sicherheitskopien des vorherigen Stands bewahrt.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (invalidCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                key: const ValueKey<String>('local-backup-warning'),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  invalidCount == 1
                      ? 'Eine lokale Sicherung ist beschädigt und wurde für die Wiederherstellung gesperrt.'
                      : '$invalidCount lokale Sicherungen sind beschädigt und wurden für die Wiederherstellung gesperrt.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB42318),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onCreateLocalBackup,
              icon: const Icon(Icons.add_to_photos_outlined),
              label: const Text('Jetzt lokal sichern'),
            ),
            const SizedBox(height: 14),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (entries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Noch keine lokale Sicherung vorhanden.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              )
            else
              ...List.generate(entries.length, (index) {
                final entry = entries[index];
                return Column(
                  children: [
                    _LocalBackupTile(
                      entry: entry,
                      isBusy: isBusy,
                      onRestore: () => onRestore(entry),
                      onDelete: () => onDelete(entry),
                    ),
                    if (index != entries.length - 1) const Divider(height: 1),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _LocalBackupTile extends StatelessWidget {
  const _LocalBackupTile({
    required this.entry,
    required this.isBusy,
    required this.onRestore,
    required this.onDelete,
  });

  final LocalBackupEntry entry;
  final bool isBusy;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final label = !entry.isValid
        ? 'Beschädigt'
        : entry.isSafetyCopy
        ? 'Sicherheitskopie'
        : entry.isAutomatic
        ? 'Automatisch'
        : 'Manuell';
    final subtitle = !entry.isValid
        ? '${entry.validationError ?? 'Die Sicherung ist ungültig.'}\n'
              '${_formatBytes(entry.sizeBytes)} · ${entry.fileName}'
        : entry.isSafetyCopy
        ? 'Vor einer Wiederherstellung erstellt · ${_formatBytes(entry.sizeBytes)}'
        : '${_formatBytes(entry.sizeBytes)} · ${entry.fileName}';

    final icon = !entry.isValid
        ? Icons.warning_amber_rounded
        : entry.isSafetyCopy
        ? Icons.health_and_safety_outlined
        : entry.isAutomatic
        ? Icons.autorenew_outlined
        : Icons.save_outlined;

    return ListTile(
      key: ValueKey<String>('local-backup-${entry.fileName}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: entry.isValid
            ? entry.isSafetyCopy
                ? const Color(0xFFEAF7F0)
                : AppColors.primarySoft
            : const Color(0xFFFFF1F0),
        foregroundColor: entry.isValid
            ? entry.isSafetyCopy
                ? AppColors.success
                : AppColors.primary
            : const Color(0xFFB42318),
        child: Icon(icon),
      ),
      title: Text(
        '$label · ${_formatDateTime(entry.createdAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        maxLines: entry.isValid ? 2 : 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<_LocalBackupAction>(
        enabled: !isBusy,
        tooltip: 'Backup-Aktionen',
        onSelected: (action) {
          switch (action) {
            case _LocalBackupAction.restore:
              onRestore();
              break;
            case _LocalBackupAction.delete:
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          if (entry.canRestore)
            const PopupMenuItem(
              value: _LocalBackupAction.restore,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.restore),
                title: Text('Prüfen & wiederherstellen'),
              ),
            ),
          const PopupMenuItem(
            value: _LocalBackupAction.delete,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline),
              title: Text('Löschen'),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}, '
        '${two(value.hour)}:${two(value.minute)}';
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
}

enum _LocalBackupAction { restore, delete }
