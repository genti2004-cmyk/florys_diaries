import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/assistant/domain/travel_assistant_models.dart';

class AssistantOverviewGrid extends StatelessWidget {
  const AssistantOverviewGrid({
    required this.snapshot,
    super.key,
  });

  final TravelAssistantSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _MetricTile(
          icon: Icons.flight_takeoff_rounded,
          label: 'Reisen',
          value: snapshot.tripCount.toString(),
        ),
        _MetricTile(
          icon: Icons.public_rounded,
          label: 'Länder',
          value: snapshot.countryCount.toString(),
        ),
        _MetricTile(
          icon: Icons.description_rounded,
          label: 'Dateien',
          value: '${snapshot.fileCount}/${snapshot.documentCount}',
        ),
        _MetricTile(
          icon: Icons.auto_awesome_rounded,
          label: 'Erinnerungen',
          value: snapshot.memoryCount.toString(),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
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
