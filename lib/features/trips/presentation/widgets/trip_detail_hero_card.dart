import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/travel_visuals.dart';
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradient,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0B1526),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _GlassBadge(
                  icon: status.icon,
                  label: status.label,
                ),
                const Spacer(),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Icon(palette.icon, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              trip.title,
              maxLines: 3,
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
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    icon: Icons.calendar_today_outlined,
                    title: 'Zeitraum',
                    value: TravelVisuals.formatDateRange(
                      trip.startDate,
                      trip.endDate,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroMetric(
                    icon: Icons.timelapse_rounded,
                    title: 'Dauer',
                    value: '${trip.durationDays} Tage',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    icon: Icons.description_outlined,
                    title: 'Dokumente',
                    value: '${trip.documentCount}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeroMetric(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Erinnerungen',
                    value: '${trip.albumEntryCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      trip.notes.trim().isEmpty
                          ? 'Noch keine persönlichen Notizen gespeichert.'
                          : trip.notes,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
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

class _TripStatus {
  const _TripStatus({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
