import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

class WorldSummaryCard extends StatelessWidget {
  const WorldSummaryCard({
    super.key,
    required this.countryCount,
    required this.cityCount,
    required this.tripCount,
    required this.travelDays,
    required this.progressPercent,
  });

  final int countryCount;
  final int cityCount;
  final int tripCount;
  final int travelDays;
  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1D5965)],
        ),
        borderRadius: BorderRadius.circular(26),
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
          final narrow = constraints.maxWidth < 340;
          final metricWidth = narrow
              ? (constraints.maxWidth - 8) / 2
              : (constraints.maxWidth - 24) / 4;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${progressPercent.toStringAsFixed(1)} % der Welt',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Automatisch aus deinen gespeicherten Reisen.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ((progressPercent / 100).clamp(0, 1)).toDouble(),
                  minHeight: 11,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  color: const Color(0xFFB8D9BA),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: metricWidth,
                    child: _WorldMetric(
                      icon: Icons.flight_takeoff_rounded,
                      label: 'Reisen',
                      value: tripCount.toString(),
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _WorldMetric(
                      icon: Icons.flag_outlined,
                      label: 'Länder',
                      value: countryCount.toString(),
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _WorldMetric(
                      icon: Icons.location_city_rounded,
                      label: 'Städte',
                      value: cityCount.toString(),
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _WorldMetric(
                      icon: Icons.calendar_month_outlined,
                      label: 'Tage',
                      value: travelDays.toString(),
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

class _WorldMetric extends StatelessWidget {
  const _WorldMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(height: 4),
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
