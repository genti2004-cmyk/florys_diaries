import 'package:flutter/material.dart';

import 'package:florys_diaries/features/backup/domain/backup_sync_status.dart';

class SettingsOverviewCard extends StatelessWidget {
  const SettingsOverviewCard({
    required this.providerName,
    required this.localBackupCount,
    required this.cloudBackupCount,
    required this.cloudAccountEmail,
    required this.automaticCloudEnabled,
    required this.syncStatus,
    super.key,
  });

  final String providerName;
  final int localBackupCount;
  final int cloudBackupCount;
  final String? cloudAccountEmail;
  final bool automaticCloudEnabled;
  final BackupSyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation(syncStatus.overallState);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F4C5C),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 340;
          final metricWidth = narrow
              ? (constraints.maxWidth - 8) / 2
              : (constraints.maxWidth - 16) / 3;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Icon(
                      presentation.icon,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sicherung im Blick',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          presentation.summary,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.backup_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aktives Ziel: $providerName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: metricWidth,
                    child: _OverviewMetric(
                      icon: Icons.phone_android_outlined,
                      value: localBackupCount.toString(),
                      label: 'Lokal',
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _OverviewMetric(
                      icon: Icons.cloud_outlined,
                      value: cloudBackupCount.toString(),
                      label: cloudAccountEmail == null ? 'Cloud' : 'Drive',
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _OverviewMetric(
                      icon: automaticCloudEnabled
                          ? Icons.sync_rounded
                          : Icons.sync_disabled_rounded,
                      value: automaticCloudEnabled ? 'An' : 'Aus',
                      label: 'Automatik',
                    ),
                  ),
                ],
              ),
              if (cloudAccountEmail != null &&
                  cloudAccountEmail!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 17,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        cloudAccountEmail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static _SettingsOverviewPresentation _presentation(
    BackupSyncOverallState state,
  ) {
    return switch (state) {
      BackupSyncOverallState.idle => const _SettingsOverviewPresentation(
        icon: Icons.cloud_queue_outlined,
        summary:
            'Backups sind eingerichtet und bereit für die nächste Prüfung.',
      ),
      BackupSyncOverallState.scheduled => const _SettingsOverviewPresentation(
        icon: Icons.schedule_outlined,
        summary: 'Neue Änderungen werden in Kürze auf Sicherungen geprüft.',
      ),
      BackupSyncOverallState.running => const _SettingsOverviewPresentation(
        icon: Icons.sync_rounded,
        summary: 'Lokale Sicherung und Google Drive werden gerade geprüft.',
      ),
      BackupSyncOverallState.completed => const _SettingsOverviewPresentation(
        icon: Icons.cloud_done_outlined,
        summary: 'Die letzte automatische Backup-Prüfung ist abgeschlossen.',
      ),
      BackupSyncOverallState.attention => const _SettingsOverviewPresentation(
        icon: Icons.cloud_off_outlined,
        summary: 'Google Drive benötigt Aufmerksamkeit; lokal läuft weiter.',
      ),
      BackupSyncOverallState.failed => const _SettingsOverviewPresentation(
        icon: Icons.error_outline_rounded,
        summary: 'Mindestens eine Sicherung konnte nicht geprüft werden.',
      ),
    };
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsOverviewPresentation {
  const _SettingsOverviewPresentation({
    required this.icon,
    required this.summary,
  });

  final IconData icon;
  final String summary;
}
