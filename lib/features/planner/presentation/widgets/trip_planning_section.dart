import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/budget/presentation/widgets/trip_budget_section.dart';
import 'package:florys_diaries/features/checklist/presentation/widgets/trip_checklist_section.dart';
import 'package:florys_diaries/features/planner/presentation/widgets/trip_day_planner_section.dart';
import 'package:florys_diaries/features/reminders/presentation/widgets/trip_reminders_section.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripPlanningSection extends StatelessWidget {
  const TripPlanningSection({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripRemindersSection(trip: trip),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 24),
        TripBudgetSection(trip: trip),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 24),
        TripDayPlannerSection(trip: trip),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vor der Reise',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TripChecklistSection(trip: trip),
      ],
    );
  }
}
