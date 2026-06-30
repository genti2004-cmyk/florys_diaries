import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';

class ChecklistItemCard extends StatelessWidget {
  const ChecklistItemCard({
    required this.item,
    required this.onToggle,
    required this.onTap,
    super.key,
  });

  final TripChecklistItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final warning = item.isOverdue || item.isDueSoon;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: item.isCompleted,
                onChanged: (value) => onToggle(value ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: item.isCompleted
                            ? AppColors.textMuted
                            : AppColors.text,
                        fontWeight: FontWeight.w900,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _InfoChip(
                          icon: item.category.icon,
                          label: item.category.label,
                        ),
                        _InfoChip(
                          icon: Icons.flag_outlined,
                          label: item.priority.label,
                        ),
                        if (item.dueDate != null)
                          _InfoChip(
                            icon: item.isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.event_outlined,
                            label: item.isOverdue
                                ? 'Überfällig: ${_formatDate(item.dueDate!)}'
                                : 'Fällig: ${_formatDate(item.dueDate!)}',
                            emphasized: warning,
                          ),
                      ],
                    ),
                    if (item.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        item.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final foreground = emphasized ? AppColors.danger : AppColors.textMuted;
    final background = emphasized
        ? const Color(0xFFFFECEE)
        : AppColors.surfaceSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
