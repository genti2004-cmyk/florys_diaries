import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/budget/presentation/screens/budget_expense_editor_screen.dart';
import 'package:florys_diaries/features/budget/presentation/screens/trip_budget_settings_screen.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripBudgetSection extends StatefulWidget {
  const TripBudgetSection({required this.trip, super.key});

  final Trip trip;

  @override
  State<TripBudgetSection> createState() => _TripBudgetSectionState();
}

class _TripBudgetSectionState extends State<TripBudgetSection> {
  Future<void> _openBudgetSettings() async {
    final result = await Navigator.of(context).push<TripBudgetSettingsResult>(
      MaterialPageRoute<TripBudgetSettingsResult>(
        builder: (_) => TripBudgetSettingsScreen(
          amountCents: widget.trip.budgetAmountCents,
          currency: widget.trip.budgetCurrency,
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    final store = TripStoreScope.of(context);
    await store.updateTrip(
      widget.trip.copyWith(
        budgetAmountCents: result.amountCents,
        budgetCurrency: result.currency,
      ),
    );
  }

  Future<void> _openExpenseEditor({TripBudgetExpense? expense}) async {
    final result = await Navigator.of(context).push<BudgetExpenseEditorResult>(
      MaterialPageRoute<BudgetExpenseEditorResult>(
        builder: (_) => BudgetExpenseEditorScreen(
          trip: widget.trip,
          expense: expense,
          initialDate: _initialExpenseDate(widget.trip),
        ),
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    final expenses = List<TripBudgetExpense>.from(widget.trip.budgetExpenses);
    if (result.delete) {
      expenses.removeWhere((item) => item.id == result.expense.id);
    } else {
      final index = expenses.indexWhere(
        (item) => item.id == result.expense.id,
      );
      if (index == -1) {
        final plannedMatch = result.expense.status == TripExpenseStatus.paid
            ? expenses.indexWhere(
                (item) => _isMatchingPlannedExpense(
                  planned: item,
                  paid: result.expense,
                ),
              )
            : -1;
        if (plannedMatch >= 0) {
          expenses[plannedMatch] = result.expense.copyWith(
            id: expenses[plannedMatch].id,
          );
        } else {
          expenses.add(result.expense);
        }
      } else {
        expenses[index] = result.expense;
      }
    }
    expenses.sort(_compareExpenses);

    final store = TripStoreScope.of(context);
    await store.updateTrip(widget.trip.copyWith(budgetExpenses: expenses));
  }

  Future<void> _toggleExpenseStatus(TripBudgetExpense expense) async {
    final expenses = widget.trip.budgetExpenses.map((item) {
      if (item.id != expense.id) {
        return item;
      }
      final nextStatus = item.status == TripExpenseStatus.paid
          ? TripExpenseStatus.planned
          : TripExpenseStatus.paid;
      return item.copyWith(status: nextStatus);
    }).toList(growable: false)
      ..sort(_compareExpenses);

    final store = TripStoreScope.of(context);
    await store.updateTrip(widget.trip.copyWith(budgetExpenses: expenses));
  }

  Future<void> _removeCoveredPlannedExpenses() async {
    final coveredIds = widget.trip.coveredPlannedExpenseIds;
    if (coveredIds.isEmpty) {
      return;
    }

    final expenses = widget.trip.budgetExpenses
        .where((expense) => !coveredIds.contains(expense.id))
        .toList(growable: false)
      ..sort(_compareExpenses);

    final store = TripStoreScope.of(context);
    await store.updateTrip(widget.trip.copyWith(budgetExpenses: expenses));
  }

  @override
  Widget build(BuildContext context) {
    final expenses = List<TripBudgetExpense>.from(widget.trip.budgetExpenses)
      ..sort(_compareExpenses);
    final coveredPlannedIds = widget.trip.coveredPlannedExpenseIds;
    final effectiveExpenses = expenses
        .where((expense) => !coveredPlannedIds.contains(expense.id))
        .toList(growable: false);
    final categoryTotals = _categoryTotals(effectiveExpenses);
    final dayTotals = _dayTotals(effectiveExpenses);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reisekosten & Budget',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Geplante und bezahlte Kosten im Blick behalten.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _BudgetOverviewCard(
          trip: widget.trip,
          onEditBudget: _openBudgetSettings,
          onAddExpense: () => _openExpenseEditor(),
        ),
        if (coveredPlannedIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CoveredPlanningNotice(
            count: coveredPlannedIds.length,
            onClean: _removeCoveredPlannedExpenses,
          ),
        ],
        if (expenses.isEmpty) ...[
          const SizedBox(height: 12),
          _EmptyBudgetCard(onAddExpense: () => _openExpenseEditor()),
        ] else ...[
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Nach Kategorie',
            subtitle: '${categoryTotals.length} Kostenbereiche',
          ),
          const SizedBox(height: 10),
          _CategorySummary(
            totals: categoryTotals,
            totalCents: widget.trip.totalExpenseCents,
            currency: widget.trip.budgetCurrency,
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Nach Reisetag',
            subtitle: '${dayTotals.length} Tage mit Ausgaben',
          ),
          const SizedBox(height: 10),
          _DaySummary(
            totals: dayTotals,
            currency: widget.trip.budgetCurrency,
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Alle Ausgaben',
            subtitle: '${expenses.length} Einträge',
            trailing: TextButton.icon(
              onPressed: () => _openExpenseEditor(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Neu'),
            ),
          ),
          const SizedBox(height: 10),
          ...expenses.map(
            (expense) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpenseCard(
                expense: expense,
                currency: widget.trip.budgetCurrency,
                onTap: () => _openExpenseEditor(expense: expense),
                onStatusToggle: () => _toggleExpenseStatus(expense),
                coveredByPaid: coveredPlannedIds.contains(expense.id),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static bool _isMatchingPlannedExpense({
    required TripBudgetExpense planned,
    required TripBudgetExpense paid,
  }) {
    return planned.status == TripExpenseStatus.planned &&
        planned.title.trim().toLowerCase() == paid.title.trim().toLowerCase() &&
        planned.dateOnly == paid.dateOnly &&
        planned.amountCents == paid.amountCents &&
        planned.category == paid.category;
  }

  static DateTime _initialExpenseDate(Trip trip) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final end = DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
    if (today.isBefore(start)) {
      return start;
    }
    if (today.isAfter(end)) {
      return end;
    }
    return today;
  }

  static int _compareExpenses(
    TripBudgetExpense left,
    TripBudgetExpense right,
  ) {
    final dateComparison = right.dateOnly.compareTo(left.dateOnly);
    if (dateComparison != 0) {
      return dateComparison;
    }
    return left.title.compareTo(right.title);
  }

  static Map<TripExpenseCategory, int> _categoryTotals(
    List<TripBudgetExpense> expenses,
  ) {
    final totals = <TripExpenseCategory, int>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amountCents,
        ifAbsent: () => expense.amountCents,
      );
    }
    final entries = totals.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return Map<TripExpenseCategory, int>.fromEntries(entries);
  }

  static Map<DateTime, int> _dayTotals(List<TripBudgetExpense> expenses) {
    final totals = <DateTime, int>{};
    for (final expense in expenses) {
      totals.update(
        expense.dateOnly,
        (value) => value + expense.amountCents,
        ifAbsent: () => expense.amountCents,
      );
    }
    final entries = totals.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return Map<DateTime, int>.fromEntries(entries);
  }
}

class _BudgetOverviewCard extends StatelessWidget {
  const _BudgetOverviewCard({
    required this.trip,
    required this.onEditBudget,
    required this.onAddExpense,
  });

  final Trip trip;
  final VoidCallback onEditBudget;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    final hasBudget = trip.budgetAmountCents > 0;
    final actualOverBudget = hasBudget && trip.actualRemainingBudgetCents < 0;
    final forecastOverBudget =
        hasBudget && trip.forecastRemainingBudgetCents < 0;
    final accent = actualOverBudget ? AppColors.danger : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102548), Color(0xFF285FD5)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A162745),
            blurRadius: 22,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasBudget ? 'Gesamtes Reisebudget' : 'Budget planen',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hasBudget
                            ? TripMoney.format(
                                trip.budgetAmountCents,
                                trip.budgetCurrency,
                              )
                            : 'Noch nicht festgelegt',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: hasBudget ? 'Budget bearbeiten' : 'Budget festlegen',
                  onPressed: onEditBudget,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                    hasBudget ? Icons.edit_rounded : Icons.add_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final metrics = [
                  _BudgetMetric(
                    label: 'Bezahlt',
                    value: TripMoney.format(
                      trip.paidExpenseCents,
                      trip.budgetCurrency,
                    ),
                    icon: Icons.check_circle_rounded,
                    danger: actualOverBudget,
                  ),
                  _BudgetMetric(
                    label: actualOverBudget
                        ? 'Tatsächlich über Budget'
                        : 'Aktuell verfügbar',
                    value: hasBudget
                        ? TripMoney.format(
                            trip.actualRemainingBudgetCents.abs(),
                            trip.budgetCurrency,
                          )
                        : '–',
                    icon: actualOverBudget
                        ? Icons.warning_amber_rounded
                        : Icons.account_balance_wallet_rounded,
                    danger: actualOverBudget,
                  ),
                  _BudgetMetric(
                    label: 'Noch geplant',
                    value: TripMoney.format(
                      trip.plannedExpenseCents,
                      trip.budgetCurrency,
                    ),
                    icon: Icons.schedule_rounded,
                  ),
                  _BudgetMetric(
                    label: forecastOverBudget
                        ? 'Voraussichtlich darüber'
                        : 'Voraussichtlich übrig',
                    value: hasBudget
                        ? TripMoney.format(
                            trip.forecastRemainingBudgetCents.abs(),
                            trip.budgetCurrency,
                          )
                        : '–',
                    icon: forecastOverBudget
                        ? Icons.trending_up_rounded
                        : Icons.savings_rounded,
                    danger: forecastOverBudget,
                  ),
                ];

                if (constraints.maxWidth < 330) {
                  return Column(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        SizedBox(width: double.infinity, child: metrics[index]),
                        if (index != metrics.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  );
                }

                final width = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: metrics
                      .map((metric) => SizedBox(width: width, child: metric))
                      .toList(growable: false),
                );
              },
            ),
            if (hasBudget) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: trip.paidBudgetProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    actualOverBudget ? AppColors.danger : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '${(trip.paidBudgetProgress * 100).round()} % tatsächlich ausgegeben · '
                '${(trip.forecastBudgetProgress * 100).round()} % inklusive Planung',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  'Geplante Kosten werden nur beim voraussichtlichen Restbudget berücksichtigt. '
                  '„Aktuell verfügbar“ zieht ausschließlich bereits bezahlte Ausgaben ab.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey<String>('budget-add-expense'),
                onPressed: onAddExpense,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: accent,
                ),
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Ausgabe hinzufügen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.danger = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: danger
            ? AppColors.danger.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoveredPlanningNotice extends StatelessWidget {
  const _CoveredPlanningNotice({
    required this.count,
    required this.onClean,
  });

  final int count;
  final VoidCallback onClean;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.content_copy_rounded,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 1
                        ? '1 doppelte Planung erkannt'
                        : '$count doppelte Planungen erkannt',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diese geplanten Einträge sind bereits durch identische bezahlte Ausgaben abgedeckt und werden im Budget nicht erneut berechnet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const ValueKey<String>('budget-clean-duplicates'),
                    onPressed: onClean,
                    icon: const Icon(Icons.cleaning_services_rounded, size: 17),
                    label: const Text('Doppelte Planung entfernen'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBudgetCard extends StatelessWidget {
  const _EmptyBudgetCard({required this.onAddExpense});

  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Noch keine Ausgaben',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Erfasse Hotel, Transport, Essen und Aktivitäten als geplant oder bereits bezahlt.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onAddExpense,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Erste Ausgabe anlegen'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _CategorySummary extends StatelessWidget {
  const _CategorySummary({
    required this.totals,
    required this.totalCents,
    required this.currency,
  });

  final Map<TripExpenseCategory, int> totals;
  final int totalCents;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: totals.entries.map((entry) {
            final progress = totalCents <= 0 ? 0.0 : entry.value / totalCents;
            final color = _categoryColor(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(entry.key.icon, size: 18, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key.label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        TripMoney.format(entry.value, currency),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: progress.clamp(0, 1).toDouble(),
                      backgroundColor: AppColors.surfaceSoft,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.totals, required this.currency});

  final Map<DateTime, int> totals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: totals.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 17,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _formatDate(entry.key),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    TripMoney.format(entry.value, currency),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.currency,
    required this.onTap,
    required this.onStatusToggle,
    this.coveredByPaid = false,
  });

  final TripBudgetExpense expense;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onStatusToggle;
  final bool coveredByPaid;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(expense.category);
    final paid = expense.status == TripExpenseStatus.paid;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(expense.category.icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            expense.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          TripMoney.format(expense.amountCents, currency),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _ExpenseChip(
                          icon: expense.status.icon,
                          label: expense.status.label,
                          color: paid ? AppColors.success : AppColors.warning,
                        ),
                        if (coveredByPaid)
                          const _ExpenseChip(
                            icon: Icons.link_rounded,
                            label: 'Bereits abgedeckt',
                            color: AppColors.success,
                          ),
                        _ExpenseChip(
                          icon: Icons.calendar_today_outlined,
                          label: _formatDate(expense.date),
                          color: AppColors.primary,
                        ),
                        _ExpenseChip(
                          icon: expense.category.icon,
                          label: expense.category.label,
                          color: color,
                        ),
                      ],
                    ),
                    if (expense.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        expense.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: ValueKey<String>(
                          'expense-status-toggle-${expense.id}',
                        ),
                        onPressed: onStatusToggle,
                        icon: Icon(
                          paid
                              ? Icons.undo_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 17,
                        ),
                        label: Text(
                          paid ? 'Wieder als geplant' : 'Als bezahlt markieren',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseChip extends StatelessWidget {
  const _ExpenseChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Color _categoryColor(TripExpenseCategory category) {
  return switch (category) {
    TripExpenseCategory.accommodation => const Color(0xFF6C63A8),
    TripExpenseCategory.transport => AppColors.primary,
    TripExpenseCategory.food => const Color(0xFFD58A42),
    TripExpenseCategory.activities => AppColors.sage,
    TripExpenseCategory.shopping => AppColors.rose,
    TripExpenseCategory.health => AppColors.success,
    TripExpenseCategory.other => AppColors.textMuted,
  };
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
