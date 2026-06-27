import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class ReplayCompletionSummary extends StatelessWidget {
  const ReplayCompletionSummary({
    required this.trip,
    required this.eventCount,
    required this.onReplayAgain,
    required this.onClose,
    super.key,
  });

  final Trip trip;
  final int eventCount;
  final VoidCallback onReplayAgain;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primarySoft,
              AppColors.surface,
              AppColors.surfaceSoft,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Reise noch einmal erlebt',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '${trip.destination}, ${trip.country}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.75,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SummaryMetric(
                  icon: Icons.calendar_month_outlined,
                  value: '${trip.durationDays}',
                  label: 'Reisetage',
                ),
                _SummaryMetric(
                  icon: Icons.playlist_play_rounded,
                  value: '$eventCount',
                  label: 'Replay-Momente',
                ),
                _SummaryMetric(
                  icon: Icons.photo_library_outlined,
                  value: '${trip.photoCount}',
                  label: 'Fotos',
                ),
                _SummaryMetric(
                  icon: Icons.star_outline_rounded,
                  value: '${trip.highlightCount}',
                  label: 'Highlights',
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final closeButton = OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Zur Reise'),
                );
                final replayButton = FilledButton.icon(
                  onPressed: onReplayAgain,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Noch einmal'),
                );

                if (constraints.maxWidth < 340) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      replayButton,
                      const SizedBox(height: 10),
                      closeButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: closeButton),
                    const SizedBox(width: 10),
                    Expanded(child: replayButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
