import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

class BackupPanel extends StatelessWidget {
  const BackupPanel({
    required this.providerName,
    required this.isBusy,
    required this.statusText,
    required this.onCreateBackup,
    required this.onRestoreBackup,
    super.key,
  });

  final String providerName;
  final bool isBusy;
  final String? statusText;
  final VoidCallback onCreateBackup;
  final VoidCallback onRestoreBackup;

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
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.backup_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup & Wiederherstellung',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aktives Ziel: $providerName. Gesichert werden Reisen, Album-Einträge und lokale Dokumente.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (statusText != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  statusText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (isBusy)
              const LinearProgressIndicator()
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: onCreateBackup,
                    icon: const Icon(Icons.save_alt_outlined),
                    label: Text('Auf $providerName speichern'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onRestoreBackup,
                    icon: const Icon(Icons.restore),
                    label: Text('Von $providerName importieren'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
