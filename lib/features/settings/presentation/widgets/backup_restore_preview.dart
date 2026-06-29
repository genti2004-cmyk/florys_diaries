import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';
import 'package:florys_diaries/features/settings/presentation/settings_backup_formatter.dart';

class BackupRestorePreview extends StatelessWidget {
  const BackupRestorePreview({
    required this.fileName,
    required this.inspection,
    required this.sourceLabel,
    this.sourceDetail,
    super.key,
  });

  final String fileName;
  final AppBackupInspectionResult inspection;
  final String sourceLabel;
  final String? sourceDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderCard(
          fileName: fileName,
          inspection: inspection,
          sourceLabel: sourceLabel,
          sourceDetail: sourceDetail,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Reiseinhalt',
          icon: Icons.luggage_outlined,
          children: [
            _DetailRow(label: 'Reisen', value: inspection.tripCount.toString()),
            _DetailRow(
              label: 'Länder',
              value: inspection.countryCount.toString(),
            ),
            _DetailRow(
              label: 'Reiseziele',
              value: inspection.destinationCount.toString(),
            ),
            if (inspection.hasTravelPeriod)
              _DetailRow(
                label: 'Reisezeitraum',
                value:
                    '${_formatDate(inspection.firstTripStartAt!.toLocal())} – '
                    '${_formatDate(inspection.lastTripEndAt!.toLocal())}',
              ),
          ],
        ),
        const SizedBox(height: 10),
        _SectionCard(
          title: 'Gesicherte Inhalte',
          icon: Icons.inventory_2_outlined,
          children: [
            _DetailRow(
              label: 'Dokumenteinträge',
              value: inspection.documentCount.toString(),
            ),
            _DetailRow(
              label: 'Albumeinträge',
              value: inspection.albumEntryCount.toString(),
            ),
            _DetailRow(
              label: 'Checklistenpunkte',
              value: inspection.checklistItemCount.toString(),
            ),
            _DetailRow(
              label: 'Dateien im Archiv',
              value: inspection.fileCount.toString(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4D6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF4D58A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFF9A6700)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bei der Wiederherstellung werden alle aktuell in dieser '
                  'App gespeicherten Reisen und lokalen Dokumentdateien durch '
                  'genau diesen Sicherungsstand ersetzt.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF704B00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.fileName,
    required this.inspection,
    required this.sourceLabel,
    required this.sourceDetail,
  });

  final String fileName;
  final AppBackupInspectionResult inspection;
  final String sourceLabel;
  final String? sourceDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        sourceLabel,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Inhalt geprüft',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.sage,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                if (sourceDetail != null &&
                    sourceDetail!.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    sourceDetail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  fileName,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Erstellt: '
                  '${SettingsBackupFormatter.formatDateTime(inspection.backupCreatedAt.toLocal())}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  'App-Version: ${inspection.appVersion} · '
                  '${SettingsBackupFormatter.formatBytes(inspection.sizeBytes)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 250;

        if (stacked) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
