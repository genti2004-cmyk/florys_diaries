import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/replay/domain/replay_event.dart';

class ReplayMapMarker extends StatefulWidget {
  const ReplayMapMarker({
    required this.event,
    required this.isCurrent,
    required this.isPlaying,
    super.key,
  });

  final ReplayEvent event;
  final bool isCurrent;
  final bool isPlaying;

  @override
  State<ReplayMapMarker> createState() => _ReplayMapMarkerState();
}

class _ReplayMapMarkerState extends State<ReplayMapMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _updatePulse();
  }

  @override
  void didUpdateWidget(covariant ReplayMapMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCurrent != widget.isCurrent ||
        oldWidget.isPlaying != widget.isPlaying) {
      _updatePulse();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updatePulse() {
    if (widget.isCurrent && widget.isPlaying) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
      return;
    }
    _pulseController.stop();
    _pulseController.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = math.sin(_pulseController.value * math.pi).abs();
        final scale = widget.isCurrent ? 1 + (pulse * 0.09) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: widget.isCurrent ? 52 : 34,
            height: widget.isCurrent ? 52 : 34,
            decoration: BoxDecoration(
              color: widget.isCurrent
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: widget.isCurrent ? 42 : 30,
            height: widget.isCurrent ? 42 : 30,
            decoration: BoxDecoration(
              color: widget.isCurrent ? AppColors.primary : AppColors.sage,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: widget.isCurrent ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: widget.isCurrent ? 16 : 10,
                ),
              ],
            ),
            child: Icon(
              _iconFor(widget.event.type),
              color: Colors.white,
              size: widget.isCurrent ? 22 : 16,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(ReplayEventType type) {
    switch (type) {
      case ReplayEventType.destination:
        return Icons.place_rounded;
      case ReplayEventType.highlight:
        return Icons.star_rounded;
      case ReplayEventType.place:
        return Icons.location_city_rounded;
      case ReplayEventType.food:
        return Icons.restaurant_rounded;
      case ReplayEventType.memory:
        return Icons.favorite_rounded;
      case ReplayEventType.photo:
        return Icons.photo_rounded;
      case ReplayEventType.end:
        return Icons.flag_rounded;
      case ReplayEventType.start:
      case ReplayEventType.document:
      case ReplayEventType.note:
        return Icons.circle;
    }
  }
}
