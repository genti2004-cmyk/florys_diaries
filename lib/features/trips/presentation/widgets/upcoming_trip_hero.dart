import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
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

    return Semantics(
      button: true,
      label: 'Nächste Reise: ${trip.title}',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF173F49)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x260F4C5C),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 340;

                return Padding(
                  padding: EdgeInsets.all(isNarrow ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroHeader(isNarrow: isNarrow),
                      const SizedBox(height: 18),
                      Text(
                        trip.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
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
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _TripFacts(
                        isNarrow: isNarrow,
                        dateRange: _dateRange(trip),
                        durationDays: trip.durationDays,
                      ),
                      const SizedBox(height: 18),
                      _HeroFooter(isNarrow: isNarrow, status: status),
                    ],
                  ),
                );
              },
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
      return const _TripStartStatus(
        icon: Icons.explore_rounded,
        label: 'Diese Reise läuft gerade',
      );
    }

    final days = start.difference(today).inDays;
    if (days <= 0) {
      return const _TripStartStatus(
        icon: Icons.check_circle_outline,
        label: 'Reisezeitraum erreicht',
      );
    }
    if (days == 1) {
      return const _TripStartStatus(
        icon: Icons.notifications_active_outlined,
        label: 'Startet morgen',
      );
    }
    return _TripStartStatus(
      icon: Icons.schedule_rounded,
      label: 'Startet in $days Tagen',
    );
  }

  static String _dateRange(Trip trip) {
    return '${_formatDate(trip.startDate)} – ${_formatDate(trip.endDate)}';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.isNarrow});

  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 9 : 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight_takeoff_rounded, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Nächste Reise',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    return Row(
      children: [
        if (isNarrow) Expanded(child: badge) else badge,
        const SizedBox(width: 12),
        const Icon(Icons.arrow_forward_rounded, color: Colors.white),
      ],
    );
  }
}

class _TripFacts extends StatelessWidget {
  const _TripFacts({
    required this.isNarrow,
    required this.dateRange,
    required this.durationDays,
  });

  final bool isNarrow;
  final String dateRange;
  final int durationDays;

  @override
  Widget build(BuildContext context) {
    final dateChip = _HeroChip(
      icon: Icons.calendar_today_outlined,
      label: dateRange,
      expand: isNarrow,
    );
    final durationChip = _HeroChip(
      icon: Icons.timelapse_rounded,
      label: '$durationDays Tage',
      expand: isNarrow,
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [dateChip, const SizedBox(height: 8), durationChip],
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: [dateChip, durationChip]);
  }
}

class _HeroFooter extends StatelessWidget {
  const _HeroFooter({required this.isNarrow, required this.status});

  final bool isNarrow;
  final _TripStartStatus status;

  @override
  Widget build(BuildContext context) {
    final statusWidget = Row(
      mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(status.icon, size: 19, color: const Color(0xFFD5F0D7)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            status.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );

    final openLabel = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Öffnen',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white),
      ],
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          statusWidget,
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: openLabel),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: statusWidget),
        const SizedBox(width: 12),
        openLabel,
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.expand,
  });

  final IconData icon;
  final String label;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
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

class _TripStartStatus {
  const _TripStartStatus({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
