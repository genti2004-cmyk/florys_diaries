import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class ArchiveYearHeader extends StatelessWidget {
  const ArchiveYearHeader({required this.year, required this.trips, super.key});

  final int year;
  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    final days = trips.fold<int>(0, (sum, trip) => sum + trip.durationDays);

    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 11),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              year.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              trips.length == 1
                  ? '1 Reise · $days Tage'
                  : '${trips.length} Reisen · $days Tage',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.history_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
