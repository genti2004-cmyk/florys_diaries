import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/assistant/domain/travel_assistant_models.dart';

class AssistantInsightCard extends StatelessWidget {
  const AssistantInsightCard({
    required this.insight,
    this.onTap,
    super.key,
  });

  final TravelAssistantInsight insight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_icon, color: _foregroundColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            insight.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PriorityBadge(priority: insight.priority),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      insight.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    return switch (insight.kind) {
      TravelAssistantInsightKind.preparation => Icons.checklist_rounded,
      TravelAssistantInsightKind.documents => Icons.folder_copy_rounded,
      TravelAssistantInsightKind.memories => Icons.photo_album_rounded,
      TravelAssistantInsightKind.highlights => Icons.star_rounded,
      TravelAssistantInsightKind.overview => Icons.insights_rounded,
    };
  }

  Color get _backgroundColor {
    return switch (insight.priority) {
      TravelAssistantPriority.high => const Color(0xFFFFE8E2),
      TravelAssistantPriority.medium => const Color(0xFFFFF1D6),
      TravelAssistantPriority.low => AppColors.primarySoft,
    };
  }

  Color get _foregroundColor {
    return switch (insight.priority) {
      TravelAssistantPriority.high => const Color(0xFFB5422E),
      TravelAssistantPriority.medium => const Color(0xFF9A6414),
      TravelAssistantPriority.low => AppColors.primary,
    };
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TravelAssistantPriority priority;

  @override
  Widget build(BuildContext context) {
    final label = switch (priority) {
      TravelAssistantPriority.high => 'Wichtig',
      TravelAssistantPriority.medium => 'Prüfen',
      TravelAssistantPriority.low => 'Tipp',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
