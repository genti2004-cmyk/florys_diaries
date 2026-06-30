import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/core/widgets/trip_cover_image.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripDetailHeroCard extends StatelessWidget {
  const TripDetailHeroCard({required this.trip, this.now, super.key});

  final Trip trip;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final status = _status(now ?? DateTime.now());
    final palette = TravelVisuals.forText(
      '${trip.title} ${trip.destination} ${trip.country}',
    );
    final storedPhotoCount = trip.photoCount;
    final documentPhotoCount = TripCoverImage.photoDocuments(trip).length;
    final photoCount = storedPhotoCount > documentPhotoCount
        ? storedPhotoCount
        : documentPhotoCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final isNarrow = constraints.maxWidth < 340;
        final extraTextHeight = ((textScale - 1).clamp(0, 1) * 120).round();
        final cardHeight = isNarrow ? 400.0 + extraTextHeight : 280.0;

        return SizedBox(
          width: double.infinity,
          height: cardHeight,
          child: TripCoverImage(
            trip: trip,
            borderRadius: BorderRadius.circular(30),
            showFallbackIcon: false,
            overlay: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x18000000), Color(0xD607111F)],
            ),
            child: Padding(
              padding: EdgeInsets.all(isNarrow ? 16 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _GlassBadge(
                          icon: status.icon,
                          label: status.label,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(palette.icon, color: Colors.white),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    trip.title,
                    maxLines: isNarrow ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: isNarrow ? 25 : 29,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(color: Color(0x66000000), blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${trip.destination}, ${trip.country}',
                    maxLines: isNarrow ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isNarrow)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroChip(
                          icon: Icons.calendar_today_outlined,
                          label: TravelVisuals.formatDateRange(
                            trip.startDate,
                            trip.endDate,
                          ),
                          expand: true,
                        ),
                        const SizedBox(height: 8),
                        _HeroChip(
                          icon: Icons.timelapse_rounded,
                          label: '${trip.durationDays} Tage',
                          expand: true,
                        ),
                        const SizedBox(height: 8),
                        _HeroChip(
                          icon: Icons.photo_library_outlined,
                          label: '$photoCount Fotos',
                          expand: true,
                        ),
                      ],
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroChip(
                          icon: Icons.calendar_today_outlined,
                          label: TravelVisuals.formatDateRange(
                            trip.startDate,
                            trip.endDate,
                          ),
                        ),
                        _HeroChip(
                          icon: Icons.timelapse_rounded,
                          label: '${trip.durationDays} Tage',
                        ),
                        _HeroChip(
                          icon: Icons.photo_library_outlined,
                          label: '$photoCount Fotos',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _TripStatus _status(DateTime current) {
    if (trip.isPast) {
      return const _TripStatus(
        icon: Icons.check_circle_outline_rounded,
        label: 'Abgeschlossen',
      );
    }

    final today = DateTime(current.year, current.month, current.day);
    final start = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final end = DateTime(
      trip.endDate.year,
      trip.endDate.month,
      trip.endDate.day,
    );

    if (!today.isBefore(start) && !today.isAfter(end)) {
      return const _TripStatus(
        icon: Icons.explore_rounded,
        label: 'Reise läuft',
      );
    }

    final days = start.difference(today).inDays;
    if (days == 1) {
      return const _TripStatus(
        icon: Icons.notifications_active_outlined,
        label: 'Startet morgen',
      );
    }
    if (days > 1) {
      return _TripStatus(icon: Icons.schedule_rounded, label: 'In $days Tagen');
    }

    return const _TripStatus(
      icon: Icons.calendar_today_outlined,
      label: 'Geplant',
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    this.expand = false,
  });

  final IconData icon;
  final String label;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: expand ? double.infinity : null,
      constraints: expand ? null : const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: content) : content;
  }
}

class _TripStatus {
  const _TripStatus({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
