import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';

class GoogleDriveAutomaticBackupSettings extends StatelessWidget {
  const GoogleDriveAutomaticBackupSettings({
    required this.settings,
    required this.isLoading,
    required this.isBusy,
    required this.onEnabledChanged,
    required this.onIntervalChanged,
    required this.onRetentionChanged,
    required this.onRunNow,
    super.key,
  });

  final AutomaticCloudBackupSettings settings;
  final bool isLoading;
  final bool isBusy;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<int> onRetentionChanged;
  final VoidCallback onRunNow;

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
                        'Automatische Google-Drive-Sicherung',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Beim App-Start wird geprüft, ob das eingestellte Intervall erreicht ist.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.enabled,
                  onChanged: isLoading || isBusy ? null : onEnabledChanged,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isLoading)
              const LinearProgressIndicator()
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _SettingField(
                      label: 'Intervall',
                      child: DropdownButton<int>(
                        value: settings.intervalDays,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        onChanged: !settings.enabled || isBusy
                            ? null
                            : (value) {
                                if (value != null) {
                                  onIntervalChanged(value);
                                }
                              },
                        items: AutomaticCloudBackupSettings.allowedIntervalDays
                            .map(
                              (days) => DropdownMenuItem<int>(
                                value: days,
                                child: Text(_intervalLabel(days)),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SettingField(
                      label: 'Aufbewahrung',
                      child: DropdownButton<int>(
                        value: settings.retentionLimit,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        onChanged: !settings.enabled || isBusy
                            ? null
                            : (value) {
                                if (value != null) {
                                  onRetentionChanged(value);
                                }
                              },
                        items: AutomaticCloudBackupSettings
                            .allowedRetentionLimits
                            .map(
                              (count) => DropdownMenuItem<int>(
                                value: count,
                                child: Text('$count Backups'),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _statusText(settings),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isBusy || !settings.enabled ? null : onRunNow,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Jetzt automatisch sichern'),
              ),
              const SizedBox(height: 10),
              Text(
                'Nur automatisch erzeugte Cloud-Backups werden nach der gewählten Grenze bereinigt. Manuelle Sicherungen bleiben erhalten.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _intervalLabel(int days) {
    return days == 1 ? 'Täglich' : 'Alle $days Tage';
  }

  static String _statusText(AutomaticCloudBackupSettings settings) {
    if (!settings.enabled) {
      return 'Automatische Cloud-Sicherung ist ausgeschaltet.';
    }

    final lastBackup = settings.lastSuccessfulBackupAt;
    final lastChecked = settings.lastCheckedAt;
    if (lastBackup == null) {
      return 'Noch keine automatische Cloud-Sicherung. Der erste Lauf erfolgt beim nächsten App-Start oder über „Jetzt automatisch sichern“.';
    }

    final nextBackup = settings.nextBackupAt;
    final checkedText = lastChecked == null
        ? ''
        : ' Zuletzt geprüft: ${_formatDateTime(lastChecked.toLocal())}.';
    return 'Zuletzt gesichert: ${_formatDateTime(lastBackup.toLocal())}.'
        '$checkedText Nächste Prüfung ab '
        '${_formatDateTime(nextBackup!.toLocal())}.';
  }

  static String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}, '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

class _SettingField extends StatelessWidget {
  const _SettingField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
