import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

class ReplayProgress extends StatelessWidget {
  const ReplayProgress({
    required this.progress,
    required this.currentIndex,
    required this.totalCount,
    required this.remainingDuration,
    required this.statusLabel,
    required this.speedLabel,
    required this.onIndexChanged,
    super.key,
  });

  final double progress;
  final int currentIndex;
  final int totalCount;
  final Duration remainingDuration;
  final String statusLabel;
  final String speedLabel;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final hasMultipleEvents = totalCount > 1;
    final safeIndex = totalCount == 0 ? 0 : currentIndex.clamp(0, totalCount - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Replay-Fortschritt',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                totalCount == 0
                    ? 'Keine Ereignisse'
                    : 'Ereignis ${safeIndex + 1} von $totalCount',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Noch ca. ${_formatDuration(remainingDuration)} · $speedLabel',
                maxLines: 2,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (hasMultipleEvents)
          Slider(
            value: safeIndex.toDouble(),
            min: 0,
            max: (totalCount - 1).toDouble(),
            divisions: totalCount - 1,
            label: 'Ereignis ${safeIndex + 1}',
            onChanged: (value) => onIndexChanged(value.round()),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: AppColors.surfaceSoft,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }

  static String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 359999);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
