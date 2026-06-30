import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

class TripDetailQuickActions extends StatelessWidget {
  const TripDetailQuickActions({
    required this.onReplay,
    required this.onEdit,
    required this.onExport,
    super.key,
  });

  final VoidCallback onReplay;
  final VoidCallback onEdit;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.play_circle_outline_rounded,
        label: 'Replay',
        subtitle: 'Reise abspielen',
        onTap: onReplay,
      ),
      _QuickActionData(
        icon: Icons.edit_outlined,
        label: 'Bearbeiten',
        subtitle: 'Reisedaten ändern',
        onTap: onEdit,
      ),
      _QuickActionData(
        icon: Icons.ios_share_rounded,
        label: 'Export',
        subtitle: 'ZIP weitergeben',
        onTap: onExport,
      ),
    ];

    return Row(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          Expanded(child: _QuickActionCard(action: actions[index])),
          if (index < actions.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickActionData action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(height: 11),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  action.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
}
