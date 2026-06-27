import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/replay/domain/replay_speed.dart';

class ReplaySpeedSelector extends StatelessWidget {
  const ReplaySpeedSelector({
    required this.selectedSpeed,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final ReplaySpeed selectedSpeed;
  final ValueChanged<ReplaySpeed> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.speed_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'Geschwindigkeit',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<ReplaySpeed>(
          segments: [
            for (final speed in ReplaySpeed.values)
              ButtonSegment<ReplaySpeed>(
                value: speed,
                label: Text(speed.label),
              ),
          ],
          selected: {selectedSpeed},
          showSelectedIcon: false,
          onSelectionChanged: enabled
              ? (selection) {
                  if (selection.isNotEmpty) {
                    onChanged(selection.first);
                  }
                }
              : null,
        ),
      ],
    );
  }
}
