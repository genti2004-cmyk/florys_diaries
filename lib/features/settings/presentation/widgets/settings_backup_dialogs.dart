import 'package:flutter/material.dart';

import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';
import 'package:florys_diaries/features/backup/domain/google_drive_backup_models.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/settings/presentation/settings_backup_formatter.dart';
import 'package:florys_diaries/features/settings/presentation/widgets/backup_restore_preview.dart';

Future<bool> showGoogleDriveBackupDeleteDialog(
  BuildContext context,
  GoogleDriveStoredBackup entry,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Cloud-Backup löschen?'),
        content: Text(
          '${entry.name}\n\n'
          'Sicherung vom '
          '${SettingsBackupFormatter.formatDateTime(entry.createdAt.toLocal())}.\n'
          'Dieser Cloud-Stand wird dauerhaft entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Dauerhaft löschen'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

Future<bool> showLocalBackupDeleteDialog(
  BuildContext context,
  LocalBackupEntry entry,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Lokales Backup löschen?'),
        content: Text(
          '${entry.fileName}\n\n'
          'Diese Sicherung wird dauerhaft vom Gerät entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Löschen'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

Future<bool?> showBackupRestoreConfirmationDialog(
  BuildContext context, {
  required String fileName,
  required AppBackupInspectionResult inspection,
  required String sourceLabel,
  String? sourceDetail,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Backup-Inhalt prüfen'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: BackupRestorePreview(
              fileName: fileName,
              inspection: inspection,
              sourceLabel: sourceLabel,
              sourceDetail: sourceDetail,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.restore),
            label: const Text('Diesen Stand wiederherstellen'),
          ),
        ],
      );
    },
  );
}
