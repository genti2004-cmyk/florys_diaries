import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';

class ChecklistProgressCard extends StatelessWidget {
  const ChecklistProgressCard({required this.items, super.key});

  final List<TripChecklistItem> items;

  @override
  Widget build(BuildContext context) {
    final completed = items.where((item) => item.isCompleted).length;
    final open = items.length - completed;
    final overdue = items.where((item) => item.isOverdue).length;
    final progress = items.isEmpty ? 0.0 : completed / items.length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.fact_check_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items.isEmpty
                            ? 'Noch keine Aufgaben'
                            : '$completed von ${items.length} erledigt',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        overdue > 0
                            ? '$overdue überfällig · $open offen'
                            : '$open Aufgaben offen',
                        style: TextStyle(
                          color: overdue > 0
                              ? const Color(0xFFB5422E)
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  items.isEmpty ? '0 %' : '${(progress * 100).round()} %',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.surfaceSoft,
                color: AppColors.sage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
