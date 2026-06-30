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

    return SizedBox(
      width: double.infinity,
      height: 260,
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _GlassBadge(icon: status.icon, label: status.label),
                  const Spacer(),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Color(0x66000000), blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${trip.destination}, ${trip.country}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
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
                    icon: Icons.favorite_border_rounded,
                    label: '${trip.albumEntryCount} Momente',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStatus {
  const _TripStatus({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
