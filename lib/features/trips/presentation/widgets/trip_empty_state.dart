import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

class TripEmptyState extends StatelessWidget {
  const TripEmptyState({required this.onCreateTrip, super.key});

  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              size: 34,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Deine nächste Reise beginnt hier',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Lege Ziel und Zeitraum an. Dokumente, Checkliste und '
            'Erinnerungen ergänzt du anschließend direkt in der Reise.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreateTrip,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Erste Reise planen'),
          ),
        ],
      ),
    );
  }
}
