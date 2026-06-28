import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/backup/domain/backup_sync_status.dart';

class BackupSyncStatusCard extends StatelessWidget {
  const BackupSyncStatusCard({required this.status, super.key});

  final BackupSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(status.overallState);

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
                    color: presentation.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    presentation.icon,
                    color: presentation.foregroundColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automatische Backup-Synchronisierung',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        presentation.summary,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StatusPill(
                        label: presentation.label,
                        foregroundColor: presentation.foregroundColor,
                        backgroundColor: presentation.backgroundColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status.overallState == BackupSyncOverallState.running) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 16),
            _ChannelStatusRow(
              icon: Icons.phone_android_outlined,
              label: 'Lokal auf diesem Gerät',
              state: status.localState,
            ),
            const SizedBox(height: 10),
            _ChannelStatusRow(
              icon: Icons.cloud_outlined,
              label: 'Google Drive',
              state: status.cloudState,
            ),
            if (status.lastCompletedAt != null) ...[
              const SizedBox(height: 14),
              Text(
                'Zuletzt geprüft: '
                '${_formatDateTime(status.lastCompletedAt!.toLocal())}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static _StatusPresentation _presentationFor(BackupSyncOverallState state) {
    return switch (state) {
      BackupSyncOverallState.idle => const _StatusPresentation(
        icon: Icons.cloud_queue_outlined,
        label: 'Bereit',
        summary: 'Die automatische Sicherung wartet auf die erste Prüfung.',
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.primarySoft,
      ),
      BackupSyncOverallState.scheduled => const _StatusPresentation(
        icon: Icons.schedule_outlined,
        label: 'Vorgemerkt',
        summary: 'Änderungen werden in Kürze auf Sicherungen geprüft.',
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.primarySoft,
      ),
      BackupSyncOverallState.running => const _StatusPresentation(
        icon: Icons.sync,
        label: 'Prüfung läuft',
        summary: 'Lokale Sicherung und Google Drive werden geprüft.',
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.primarySoft,
      ),
      BackupSyncOverallState.completed => const _StatusPresentation(
        icon: Icons.cloud_done_outlined,
        label: 'Aktuell',
        summary: 'Die letzte automatische Prüfung wurde abgeschlossen.',
        foregroundColor: AppColors.sage,
        backgroundColor: Color(0xFFEAF4EB),
      ),
      BackupSyncOverallState.attention => const _StatusPresentation(
        icon: Icons.cloud_off_outlined,
        label: 'Anmeldung nötig',
        summary:
            'Google Drive benötigt eine Anmeldung. Lokale Backups laufen weiter.',
        foregroundColor: Color(0xFF9A6700),
        backgroundColor: Color(0xFFFFF4D6),
      ),
      BackupSyncOverallState.failed => const _StatusPresentation(
        icon: Icons.error_outline,
        label: 'Prüfung fehlgeschlagen',
        summary: 'Mindestens eine automatische Sicherung ist fehlgeschlagen.',
        foregroundColor: Color(0xFFB42318),
        backgroundColor: Color(0xFFFDECEC),
      ),
    };
  }

  static String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}, '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

class _ChannelStatusRow extends StatelessWidget {
  const _ChannelStatusRow({
    required this.icon,
    required this.label,
    required this.state,
  });

  final IconData icon;
  final String label;
  final BackupSyncChannelState state;

  @override
  Widget build(BuildContext context) {
    final statusText = switch (state) {
      BackupSyncChannelState.waiting => 'Noch nicht geprüft',
      BackupSyncChannelState.checking => 'Wird geprüft …',
      BackupSyncChannelState.created => 'Neues Backup erstellt',
      BackupSyncChannelState.upToDate => 'Aktuell',
      BackupSyncChannelState.disabled => 'Ausgeschaltet',
      BackupSyncChannelState.signInRequired => 'Anmeldung erforderlich',
      BackupSyncChannelState.failed => 'Fehlgeschlagen',
    };

    final statusIcon = switch (state) {
      BackupSyncChannelState.waiting => Icons.hourglass_empty_outlined,
      BackupSyncChannelState.checking => Icons.sync,
      BackupSyncChannelState.created => Icons.check_circle_outline,
      BackupSyncChannelState.upToDate => Icons.check_circle_outline,
      BackupSyncChannelState.disabled => Icons.toggle_off_outlined,
      BackupSyncChannelState.signInRequired => Icons.login_outlined,
      BackupSyncChannelState.failed => Icons.error_outline,
    };

    final statusColor = switch (state) {
      BackupSyncChannelState.failed => const Color(0xFFB42318),
      BackupSyncChannelState.signInRequired => const Color(0xFF9A6700),
      BackupSyncChannelState.created ||
      BackupSyncChannelState.upToDate => AppColors.sage,
      _ => AppColors.textMuted,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.icon,
    required this.label,
    required this.summary,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final String summary;
  final Color foregroundColor;
  final Color backgroundColor;
}
