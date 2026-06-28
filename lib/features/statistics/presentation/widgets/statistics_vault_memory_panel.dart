import 'package:flutter/material.dart';

import 'package:florys_diaries/features/statistics/domain/travel_statistics.dart';
import 'package:florys_diaries/features/statistics/presentation/widgets/statistics_panel.dart';

class StatisticsVaultMemoryPanel extends StatelessWidget {
  const StatisticsVaultMemoryPanel({super.key, required this.statistics});

  final TravelStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return StatisticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatisticsPanelHeader(
            icon: Icons.auto_stories_rounded,
            title: 'Vault & Erinnerungen',
            subtitle: 'Dokumente, Fotos, Highlights und Lieblingsmomente.',
          ),
          const SizedBox(height: 12),
          StatisticsInfoRow(
            label: 'Dokumente gesamt',
            value: statistics.documentCount.toString(),
          ),
          StatisticsInfoRow(
            label: 'PDFs',
            value: statistics.pdfCount.toString(),
          ),
          StatisticsInfoRow(
            label: 'Bilder / Screenshots',
            value: statistics.imageCount.toString(),
          ),
          StatisticsInfoRow(
            label: 'Favorisierte Dokumente',
            value: statistics.favoriteDocumentCount.toString(),
          ),
          StatisticsInfoRow(
            label: 'Album-Einträge',
            value: statistics.albumEntryCount.toString(),
          ),
          StatisticsInfoRow(
            label: 'Highlights',
            value: statistics.highlightCount.toString(),
          ),
          StatisticsInfoRow(
            label: 'Lieblingsmomente',
            value: statistics.favoriteMomentCount.toString(),
          ),
        ],
      ),
    );
  }
}
