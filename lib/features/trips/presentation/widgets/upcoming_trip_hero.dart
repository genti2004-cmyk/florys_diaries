import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class UpcomingTripHero extends StatelessWidget {
  const UpcomingTripHero({
    required this.trip,
    required this.onTap,
    this.now,
    super.key,
  });

  final Trip trip;
  final VoidCallback onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final status = _statusText(now ?? DateTime.now());
    final palette = TravelVisuals.forText(
      '${trip.destination} ${trip.country} ${trip.title}',
    );

    return Semantics(
      button: true,
      label: 'Nächste Reise: ${trip.title}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.gradient,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F07111F),
                blurRadius: 26,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _GlassBadge(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(palette.icon, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            const Text(
                              'Nächste Reise',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    trip.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${trip.destination}, ${trip.country}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _GlassMetric(
                          title: 'Zeitraum',
                          value: TravelVisuals.formatDateRange(
                            trip.startDate,
                            trip.endDate,
                          ),
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GlassMetric(
                          title: 'Dauer',
                          value: '${trip.durationDays} Tage',
                          icon: Icons.timelapse_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.label,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${trip.documentCount} Dokumente · '
                              '${trip.photoCount} Fotos · '
                              '${trip.albumEntryCount} Erinnerungen',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      _GlassBadge(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Öffnen',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _TripStartStatus _statusText(DateTime current) {
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
      return const _TripStartStatus(label: 'Diese Reise läuft gerade');
    }

    final days = start.difference(today).inDays;
    if (days <= 0) {
      return const _TripStartStatus(label: 'Reisezeitraum erreicht');
    }
    if (days == 1) {
      return const _TripStartStatus(label: 'Startet morgen');
    }
    return _TripStartStatus(label: 'Startet in $days Tagen');
  }
}

class _GlassMetric extends StatelessWidget {
  const _GlassMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: child,
    );
  }
}

class _TripStartStatus {
  const _TripStartStatus({required this.label});

  final String label;
}
