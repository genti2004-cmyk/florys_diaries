import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
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
      return _ConfirmationDialog(
        icon: Icons.cloud_off_outlined,
        title: 'Cloud-Backup löschen?',
        description:
            '${entry.name}\n\n'
            'Sicherung vom '
            '${SettingsBackupFormatter.formatDateTime(entry.createdAt.toLocal())}.\n'
            'Dieser Cloud-Stand wird dauerhaft entfernt.',
        confirmLabel: 'Dauerhaft löschen',
        confirmIcon: Icons.delete_outline_rounded,
        destructive: true,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
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
      return _ConfirmationDialog(
        icon: Icons.delete_sweep_outlined,
        title: 'Lokales Backup löschen?',
        description:
            '${entry.fileName}\n\n'
            'Diese Sicherung wird dauerhaft vom Gerät entfernt.',
        confirmLabel: 'Löschen',
        confirmIcon: Icons.delete_outline_rounded,
        destructive: true,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
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
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.90,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DialogHeader(
                  icon: Icons.restore_page_outlined,
                  title: 'Backup-Inhalt prüfen',
                  subtitle:
                      'Kontrolliere Quelle und Inhalt, bevor dieser Stand die aktuellen App-Daten ersetzt.',
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: BackupRestorePreview(
                      fileName: fileName,
                      inspection: inspection,
                      sourceLabel: sourceLabel,
                      sourceDetail: sourceDetail,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 12),
                _DialogActions(
                  confirmLabel: 'Diesen Stand wiederherstellen',
                  confirmIcon: Icons.restore_rounded,
                  onCancel: () => Navigator.of(dialogContext).pop(false),
                  onConfirm: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog({
    required this.icon,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.confirmIcon,
    required this.onCancel,
    required this.onConfirm,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String confirmLabel;
  final IconData confirmIcon;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogHeader(
                icon: icon,
                title: title,
                subtitle: destructive
                    ? 'Diese Aktion kann nicht rückgängig gemacht werden.'
                    : 'Bitte prüfe die Angaben vor dem Fortfahren.',
                destructive: destructive,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: destructive
                      ? const Color(0xFFFDECEC)
                      : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: destructive
                        ? const Color(0xFFF2B8B5)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 12),
              _DialogActions(
                confirmLabel: confirmLabel,
                confirmIcon: confirmIcon,
                destructive: destructive,
                onCancel: onCancel,
                onConfirm: onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive
        ? const Color(0xFFB42318)
        : AppColors.primary;
    final background = destructive
        ? const Color(0xFFFDECEC)
        : AppColors.primarySoft;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: foreground),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.confirmLabel,
    required this.confirmIcon,
    required this.onCancel,
    required this.onConfirm,
    this.destructive = false,
  });

  final String confirmLabel;
  final IconData confirmIcon;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final cancelButton = TextButton(
      onPressed: onCancel,
      child: const Text('Abbrechen'),
    );

    final confirmButton = FilledButton.icon(
      onPressed: onConfirm,
      icon: Icon(confirmIcon),
      label: Text(confirmLabel),
      style: destructive
          ? FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
              foregroundColor: Colors.white,
            )
          : null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [confirmButton, const SizedBox(height: 8), cancelButton],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            cancelButton,
            const SizedBox(width: 8),
            Flexible(child: confirmButton),
          ],
        );
      },
    );
  }
}
