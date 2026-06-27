import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

class WorldSummaryCard extends StatelessWidget {
  const WorldSummaryCard({
    super.key,
    required this.countryCount,
    required this.cityCount,
    required this.tripCount,
    required this.travelDays,
    required this.progressPercent,
  });

  final int countryCount;
  final int cityCount;
  final int tripCount;
  final int travelDays;
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.public,
                  color: AppColors.primary,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${progressPercent.toStringAsFixed(1)}% der Welt',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Automatisch aus deinen Reisen berechnet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ((progressPercent / 100).clamp(0, 1)).toDouble(),
              minHeight: 12,
              backgroundColor: AppColors.surfaceSoft,
              color: AppColors.sage,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Reisen', value: tripCount.toString()),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Länder',
                  value: countryCount.toString(),
                ),
              ),
              Expanded(
                child: _MiniStat(label: 'Städte', value: cityCount.toString()),
              ),
              Expanded(
                child: _MiniStat(label: 'Tage', value: travelDays.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
