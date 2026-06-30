import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/backup/domain/data_safety_report.dart';

class DataSafetyCard extends StatelessWidget {
  const DataSafetyCard({
    required this.report,
    required this.isLoading,
    required this.isBusy,
    required this.onCheck,
    super.key,
  });

  final DataSafetyReport? report;
  final bool isLoading;
  final bool isBusy;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final current = report;
    final presentation = _presentation(current?.state);

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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: presentation.background,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(presentation.icon, color: presentation.foreground),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daten-Sicherheitsprüfung',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoading
                            ? 'Reisen, Dokumentdateien und lokale Sicherungen werden geprüft.'
                            : presentation.summary,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ] else if (current != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SafetyMetric(
                      label: 'Reisen',
                      value: current.tripCount.toString(),
                      icon: Icons.luggage_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SafetyMetric(
                      label: 'Dateien',
                      value: current.managedFileCount.toString(),
                      icon: Icons.folder_copy_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SafetyMetric(
                      label: 'Backups',
                      value: current.validBackupCount.toString(),
                      icon: Icons.shield_outlined,
                    ),
                  ),
                ],
              ),
              if (current.state != DataSafetyState.healthy) ...[
                const SizedBox(height: 12),
                _IssuePanel(report: current),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.health_and_safety_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Vor jeder Wiederherstellung erstellt FlorysDiaries automatisch eine lokale Sicherheitskopie des aktuellen Stands.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Geprüft: ${_formatDateTime(current.checkedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: isBusy ? null : onCheck,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Neu prüfen'),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onCheck,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Daten jetzt prüfen'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static _SafetyPresentation _presentation(DataSafetyState? state) {
    return switch (state) {
      DataSafetyState.healthy => const _SafetyPresentation(
        icon: Icons.verified_user_rounded,
        foreground: AppColors.success,
        background: Color(0xFFEAF7F0),
        summary: 'Reisedaten und Dokumentdateien sind vollständig. Eine aktuelle gültige Sicherung ist vorhanden.',
      ),
      DataSafetyState.warning => const _SafetyPresentation(
        icon: Icons.warning_amber_rounded,
        foreground: Color(0xFF9A6700),
        background: Color(0xFFFFF4D6),
        summary: 'Die Daten sind nutzbar, aber mindestens ein Punkt sollte geprüft werden.',
      ),
      DataSafetyState.critical => const _SafetyPresentation(
        icon: Icons.gpp_bad_outlined,
        foreground: AppColors.danger,
        background: Color(0xFFFFECEE),
        summary: 'Mindestens eine Dokumentdatei oder Datenreferenz ist nicht vollständig.',
      ),
      null => const _SafetyPresentation(
        icon: Icons.security_outlined,
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
        summary: 'Der aktuelle Datenstand wurde noch nicht geprüft.',
      ),
    };
  }

  static String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}, '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

class _SafetyMetric extends StatelessWidget {
  const _SafetyMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssuePanel extends StatelessWidget {
  const _IssuePanel({required this.report});

  final DataSafetyReport report;

  @override
  Widget build(BuildContext context) {
    final issues = <String>[];
    if (report.missingFileCount > 0) {
      issues.add('${report.missingFileCount} referenzierte Dokumentdatei(en) fehlen.');
    }
    if (report.invalidReferenceCount > 0) {
      issues.add('${report.invalidReferenceCount} ungültige oder doppelte Datenreferenz(en).');
    }
    if (report.orphanFileCount > 0) {
      issues.add('${report.orphanFileCount} nicht mehr zugeordnete Dokumentdatei(en).');
    }
    if (report.invalidBackupCount > 0) {
      issues.add('${report.invalidBackupCount} beschädigte lokale Sicherung(en).');
    }
    if (report.validBackupCount == 0) {
      issues.add('Es ist noch keine gültige lokale Sicherung vorhanden.');
    } else if (!report.hasRecentBackup) {
      issues.add('Die neueste gültige lokale Sicherung ist älter als 7 Tage.');
    }

    final critical = report.state == DataSafetyState.critical;
    final foreground = critical ? AppColors.danger : const Color(0xFF704B00);
    final background = critical
        ? const Color(0xFFFFECEE)
        : const Color(0xFFFFF4D6);
    final border = critical
        ? const Color(0xFFF4B8BE)
        : const Color(0xFFF4D58A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final issue in issues)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 7, color: foreground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SafetyPresentation {
  const _SafetyPresentation({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.summary,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final String summary;
}
