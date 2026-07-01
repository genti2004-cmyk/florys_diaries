import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/statistics/presentation/widgets/statistics_panel.dart';

class StatisticsPeriodFilter extends StatelessWidget {
  const StatisticsPeriodFilter({
    super.key,
    required this.selectedYear,
    required this.years,
    required this.onChanged,
  });

  final int? selectedYear;
  final List<int> years;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return StatisticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatisticsPanelHeader(
            icon: Icons.tune_rounded,
            title: 'Zeitraum',
            subtitle: 'Karte und Reisebilanz lassen sich nach Jahr auswerten.',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int?>(
            key: ValueKey<String>(
              'statistics-year-filter-${selectedYear ?? 'all'}',
            ),
            initialValue: selectedYear,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Reisejahr',
              prefixIcon: Icon(Icons.calendar_month_outlined),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Alle Jahre'),
              ),
              ...years.map(
                (year) => DropdownMenuItem<int?>(
                  value: year,
                  child: Text(year.toString()),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
          const SizedBox(height: 9),
          Text(
            selectedYear == null
                ? 'Alle gespeicherten Reisen werden gemeinsam betrachtet.'
                : 'Es zählen alle Reisen, die $selectedYear mindestens an einem Tag berühren.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
