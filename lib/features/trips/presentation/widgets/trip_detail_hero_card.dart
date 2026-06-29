import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripDetailHeroCard extends StatelessWidget {
  const TripDetailHeroCard({required this.trip, this.now, super.key});

  final Trip trip;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final status = _status(now ?? DateTime.now());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: trip.isPast
              ? const [Color(0xFF244B54), Color(0xFF17363D)]
              : const [AppColors.primary, Color(0xFF1D5965)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F4C5C),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 340;

          return Padding(
            padding: EdgeInsets.all(isNarrow ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Icon(
                        trip.isPast
                            ? Icons.luggage_rounded
                            : Icons.flight_takeoff_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusBadge(status: status),
                          const SizedBox(height: 9),
                          Text(
                            trip.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${trip.destination}, ${trip.country}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _TripDetailFacts(trip: trip, isNarrow: isNarrow),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          trip.notes.trim().isEmpty
                              ? 'Noch keine persönlichen Notizen gespeichert.'
                              : trip.notes,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

class _TripDetailFacts extends StatelessWidget {
  const _TripDetailFacts({required this.trip, required this.isNarrow});

  final Trip trip;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final facts = [
      _Fact(
        icon: Icons.calendar_today_outlined,
        label: '${_date(trip.startDate)} – ${_date(trip.endDate)}',
      ),
      _Fact(
        icon: Icons.timelapse_rounded,
        label: '${trip.durationDays} Reisetage',
      ),
      _Fact(
        icon: Icons.description_outlined,
        label: '${trip.documentCount} Dokumente',
      ),
      _Fact(
        icon: Icons.auto_stories_outlined,
        label: '${trip.albumEntryCount} Album',
      ),
    ];

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < facts.length; index++) ...[
            _FactChip(fact: facts[index], expand: true),
            if (index < facts.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: facts
          .map((fact) => _FactChip(fact: fact, expand: false))
          .toList(growable: false),
    );
  }

  static String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.fact, required this.expand});

  final _Fact fact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(fact.icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              fact.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _TripStatus status;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 15, color: const Color(0xFFD8F2DA)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.label,
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
      ),
    );
  }
}

class _Fact {
  const _Fact({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _TripStatus {
  const _TripStatus({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
