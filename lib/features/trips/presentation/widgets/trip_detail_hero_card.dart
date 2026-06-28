import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripDetailHeroCard extends StatelessWidget {
  const TripDetailHeroCard({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_formatDate(trip.startDate)} – ${_formatDate(trip.endDate)}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    trip.isPast
                        ? Icons.luggage_rounded
                        : Icons.flight_takeoff_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.destination}, ${trip.country}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DetailChip(
                  icon: Icons.calendar_today_outlined,
                  label: dateText,
                ),
                _DetailChip(
                  icon: Icons.timelapse_rounded,
                  label: '${trip.durationDays} Reisetage',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              trip.notes.trim().isEmpty
                  ? 'Keine Notizen gespeichert.'
                  : trip.notes,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
