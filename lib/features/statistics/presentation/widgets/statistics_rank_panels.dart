import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/statistics/domain/travel_statistics.dart';
import 'package:florys_diaries/features/statistics/presentation/widgets/statistics_panel.dart';

class StatisticsRankPanel extends StatelessWidget {
  const StatisticsRankPanel({
    super.key,
    required this.title,
    required this.emptyText,
    required this.items,
  });

  final String title;
  final String emptyText;
  final List<StatisticsRankItem> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.isEmpty
        ? 1
        : items.map((item) => item.value).reduce((a, b) => a > b ? a : b);

    return StatisticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(emptyText, style: const TextStyle(color: AppColors.textMuted))
          else
            ...items
                .take(5)
                .map((item) => _RankRow(item: item, maxValue: maxValue)),
        ],
      ),
    );
  }
}

class StatisticsContinentPanel extends StatelessWidget {
  const StatisticsContinentPanel({super.key, required this.items});

  final List<StatisticsRankItem> items;

  @override
  Widget build(BuildContext context) {
    return StatisticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatisticsPanelHeader(
            icon: Icons.map_rounded,
            title: 'Kontinente',
            subtitle: 'Verteilung deiner bereisten Länder.',
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Noch keine Kontinente aus Reisen berechnet.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...items.map(
              (item) =>
                  StatisticsInfoRow(label: item.label, value: item.valueLabel),
            ),
        ],
      ),
    );
  }
}

class StatisticsYearPanel extends StatelessWidget {
  const StatisticsYearPanel({super.key, required this.items});

  final List<YearStatistics> items;

  @override
  Widget build(BuildContext context) {
    return StatisticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatisticsPanelHeader(
            icon: Icons.timeline_rounded,
            title: 'Jahresübersicht',
            subtitle:
                'Welche Jahre deine Reisegeschichte besonders geprägt haben.',
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Noch keine Jahresdaten vorhanden.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...items.take(6).map((item) => _YearRow(item: item)),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.item, required this.maxValue});

  final StatisticsRankItem item;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue <= 0 ? 0.0 : item.value / maxValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                item.valueLabel,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (item.subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              item.subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: AppColors.surfaceSoft,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _YearRow extends StatelessWidget {
  const _YearRow({required this.item});

  final YearStatistics item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              item.year.toString(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.tripCount} Reisen · ${item.travelDays} Tage',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.countryCount} Länder · ${item.cityCount} Städte',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
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
