import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

class ReplayTravelMarker extends StatelessWidget {
  const ReplayTravelMarker({
    required this.bearingDegrees,
    required this.isPlaying,
    super.key,
  });

  final double bearingDegrees;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          width: isPlaying ? 50 : 42,
          height: isPlaying ? 50 : 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 12,
              ),
            ],
          ),
          child: Transform.rotate(
            angle: bearingDegrees * math.pi / 180,
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
        ),
      ],
    );
  }
}
