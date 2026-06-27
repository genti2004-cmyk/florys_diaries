import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripCard extends StatelessWidget {
  const TripCard({required this.trip, required this.onTap, super.key});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${trip.destination}, ${trip.country}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(isPast: trip.isPast),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TripChip(
                    icon: Icons.calendar_today_outlined,
                    label: _dateRange(trip),
                  ),
                  _TripChip(
                    icon: Icons.timelapse,
                    label: '${trip.durationDays} Tage',
                  ),
                  _TripChip(
                    icon: Icons.description_outlined,
                    label: '${trip.documentCount} Dokumente',
                  ),
                  _TripChip(
                    icon: Icons.photo_library_outlined,
                    label: '${trip.photoCount} Fotos',
                  ),
                ],
              ),
              if (trip.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  trip.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPast});

  final bool isPast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isPast ? AppColors.surfaceSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        isPast ? 'Archiv' : 'Geplant',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TripChip extends StatelessWidget {
  const _TripChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
