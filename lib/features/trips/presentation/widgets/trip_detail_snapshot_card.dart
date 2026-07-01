import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripDetailSnapshotCard extends StatelessWidget {
  const TripDetailSnapshotCard({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final metrics = <_SnapshotMetric>[
      _SnapshotMetric(
        icon: Icons.event_available_rounded,
        value: trip.planItemCount == 0
            ? '0'
            : '${trip.planCompletedCount}/${trip.planItemCount}',
        label: 'Programmpunkte',
        detail: trip.planItemCount == 0
            ? 'Noch nicht geplant'
            : '${trip.plannedDayCount} Reisetage befüllt',
      ),
      _SnapshotMetric(
        icon: Icons.task_alt_rounded,
        value: trip.checklistItems.isEmpty
            ? '0'
            : '${trip.checklistCompletedCount}/${trip.checklistItems.length}',
        label: 'Checkliste',
        detail: trip.checklistItems.isEmpty
            ? 'Noch keine Aufgaben'
            : '${trip.checklistOpenCount} offen',
        accent: trip.checklistOverdueCount > 0
            ? AppColors.danger
            : AppColors.success,
      ),
      _budgetMetric(trip),
      _SnapshotMetric(
        icon: Icons.auto_awesome_rounded,
        value: '${trip.albumEntryCount}',
        label: 'Momente',
        detail: trip.highlightCount == 1
            ? '1 Highlight markiert'
            : '${trip.highlightCount} Highlights markiert',
        accent: AppColors.rose,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Semantics(
          container: true,
          label: 'Reiseübersicht mit Planung, Checkliste, Budget und Momenten',
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: width,
                  child: _SnapshotTile(metric: metric),
                ),
            ],
          ),
        );
      },
    );
  }

  static _SnapshotMetric _budgetMetric(Trip trip) {
    if (trip.budgetAmountCents <= 0) {
      return const _SnapshotMetric(
        icon: Icons.account_balance_wallet_outlined,
        value: 'Offen',
        label: 'Budget',
        detail: 'Noch nicht festgelegt',
        accent: AppColors.sand,
      );
    }

    final remaining = trip.forecastRemainingBudgetCents;
    return _SnapshotMetric(
      icon: remaining < 0
          ? Icons.warning_amber_rounded
          : Icons.account_balance_wallet_rounded,
      value: TripMoney.format(remaining, trip.budgetCurrency),
      label: remaining < 0 ? 'Über Budget' : 'Budget übrig',
      detail:
          '${TripMoney.format(trip.totalExpenseCents, trip.budgetCurrency)} '
          'verplant',
      accent: remaining < 0 ? AppColors.danger : AppColors.sand,
    );
  }
}

class _SnapshotMetric {
  const _SnapshotMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
    this.accent = AppColors.primary,
  });

  final IconData icon;
  final String value;
  final String label;
  final String detail;
  final Color accent;
}

class _SnapshotTile extends StatelessWidget {
  const _SnapshotTile({required this.metric});

  final _SnapshotMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: metric.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(metric.icon, size: 20, color: metric.accent),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
