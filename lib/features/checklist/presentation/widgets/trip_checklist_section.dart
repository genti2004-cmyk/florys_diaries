import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/features/checklist/presentation/screens/trip_checklist_screen.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripChecklistSection extends StatelessWidget {
  const TripChecklistSection({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final total = trip.checklistItems.length;
    final completed = trip.checklistCompletedCount;
    final open = total - completed;
    final progress = total == 0 ? 0.0 : completed / total;

    return AppSectionCard(
      icon: Icons.fact_check_outlined,
      title: total == 0 ? 'Reise-Checkliste' : '$completed von $total erledigt',
      subtitle: total == 0
          ? 'Aufgaben, Fälligkeiten und intelligente Vorbereitung.'
          : open == 0
          ? 'Alles vorbereitet.'
          : '$open Aufgaben sind noch offen.',
      trailing: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: AppColors.surfaceSoft,
              color: AppColors.sage,
            ),
            Text(
              total == 0 ? '0' : '${(progress * 100).round()}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TripChecklistScreen(trip: trip),
          ),
        );
      },
    );
  }
}
