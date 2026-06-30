import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class ArchiveOverviewCard extends StatelessWidget {
  const ArchiveOverviewCard({required this.trips, super.key});

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    final countries = trips
        .map((trip) => trip.country.trim().toLowerCase())
        .where((country) => country.isNotEmpty)
        .toSet()
        .length;
    final totalDays = trips.fold<int>(
      0,
      (sum, trip) => sum + trip.durationDays,
    );
    final memories = trips.fold<int>(
      0,
      (sum, trip) =>
          sum + trip.documentCount + trip.albumEntryCount + trip.photoCount,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1D5965)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F4C5C),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metricWidth = constraints.maxWidth < 360
              ? (constraints.maxWidth - 8) / 2
              : (constraints.maxWidth - 16) / 3;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Deine Reisegeschichte',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                trips.length == 1
                    ? 'Eine abgeschlossene Reise bleibt hier sicher bewahrt.'
                    : '${trips.length} abgeschlossene Reisen bleiben hier '
                          'sicher bewahrt.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: metricWidth,
                    child: _ArchiveMetric(
                      icon: Icons.luggage_rounded,
                      value: trips.length.toString(),
                      label: trips.length == 1 ? 'Reise' : 'Reisen',
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _ArchiveMetric(
                      icon: Icons.public_rounded,
                      value: countries.toString(),
                      label: countries == 1 ? 'Land' : 'Länder',
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _ArchiveMetric(
                      icon: Icons.calendar_month_outlined,
                      value: totalDays.toString(),
                      label: 'Reisetage',
                    ),
                  ),
                  if (constraints.maxWidth < 360)
                    SizedBox(
                      width: metricWidth,
                      child: _ArchiveMetric(
                        icon: Icons.collections_bookmark_outlined,
                        value: memories.toString(),
                        label: 'Momente',
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ArchiveMetric extends StatelessWidget {
  const _ArchiveMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
