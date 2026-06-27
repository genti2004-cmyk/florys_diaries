import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/replay/domain/replay_event.dart';

class ReplayMapHeader extends StatelessWidget {
  const ReplayMapHeader({
    required this.currentEvent,
    required this.isPlaying,
    super.key,
  });

  final ReplayEvent? currentEvent;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final location = currentEvent?.location.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPlaying ? Icons.near_me_rounded : Icons.map_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replay-Karte',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location.isEmpty
                      ? 'Noch kein präziser Ort erreicht'
                      : 'Aktuell: $location',
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
          if (isPlaying)
            const ReplayMapStatusBadge(
              icon: Icons.play_arrow_rounded,
              label: 'Live',
            ),
        ],
      ),
    );
  }
}

class ReplayMapFooter extends StatelessWidget {
  const ReplayMapFooter({
    required this.positionedCount,
    required this.totalCount,
    super.key,
  });

  final int positionedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          const Icon(
            Icons.route_outlined,
            color: AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$positionedCount von $totalCount bisherigen Ereignissen sind kartierbar.',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReplayNoPositionOverlay extends StatelessWidget {
  const ReplayNoPositionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface.withValues(alpha: 0.82),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_searching_rounded,
                color: AppColors.primary,
                size: 38,
              ),
              const SizedBox(height: 10),
              Text(
                'Die Karte folgt, sobald ein Ereignis mit bekanntem Ort erreicht wird.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReplayMapStatusBadge extends StatelessWidget {
  const ReplayMapStatusBadge({
    required this.icon,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
