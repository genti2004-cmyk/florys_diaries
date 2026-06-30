import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/core/widgets/trip_cover_image.dart';
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
    final photoCount = TripCoverImage.photoDocuments(trip).length;

    return Semantics(
      button: true,
      label: 'Nächste Reise: ${trip.title}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 330,
            child: TripCoverImage(
              trip: trip,
              borderRadius: BorderRadius.circular(30),
              showFallbackIcon: false,
              overlay: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x33000000),
                  Color(0xD907111F),
                ],
                stops: [0, 0.42, 1],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
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
                        _GlassBadge(
                          child: Text(
                            status.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: Color(0x66000000), blurRadius: 12),
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
                        _GlassFact(
                          icon: Icons.calendar_today_outlined,
                          value: TravelVisuals.formatDateRange(
                            trip.startDate,
                            trip.endDate,
                          ),
                        ),
                        _GlassFact(
                          icon: Icons.timelapse_rounded,
                          value: '${trip.durationDays} Tage',
                        ),
                        _GlassFact(
                          icon: Icons.photo_library_outlined,
                          value: '$photoCount Fotos',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${trip.documentCount} Dokumente · '
                            '${trip.albumEntryCount} Momente',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const _GlassBadge(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Öffnen',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
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
      return const _TripStartStatus(label: 'Reise läuft');
    }

    final days = start.difference(today).inDays;
    if (days <= 0) {
      return const _TripStartStatus(label: 'Zeitraum erreicht');
    }
    if (days == 1) {
      return const _TripStartStatus(label: 'Morgen');
    }
    return _TripStartStatus(label: 'In $days Tagen');
  }
}

class _GlassFact extends StatelessWidget {
  const _GlassFact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            value,
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

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

class _TripStartStatus {
  const _TripStartStatus({required this.label});

  final String label;
}
