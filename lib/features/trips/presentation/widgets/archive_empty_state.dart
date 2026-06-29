import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

class ArchiveEmptyState extends StatelessWidget {
  const ArchiveEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(23),
            ),
            child: const Icon(
              Icons.history_edu_rounded,
              size: 35,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dein Reisearchiv wächst automatisch',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sobald eine Reise beendet ist, erscheint sie hier mit '
            'Dokumenten, Checkliste, Album und Erinnerungen.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
