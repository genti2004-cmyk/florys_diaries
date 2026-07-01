import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/core/widgets/trip_cover_image.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripCard extends StatelessWidget {
  const TripCard({required this.trip, required this.onTap, super.key});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TravelVisuals.forText(
      '${trip.destination} ${trip.country} ${trip.title}',
    );

    return Semantics(
      button: true,
      label: '${trip.title}, ${trip.destination}, ${trip.country}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 22,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 198,
                  child: TripCoverImage(
                    trip: trip,
                    borderRadius: BorderRadius.zero,
                    overlay: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x16000000),
                        Color(0x38000000),
                        Color(0xBF07111F),
                      ],
                      stops: [0, 0.42, 1],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _HeroPill(
                                icon: trip.isPast
                                    ? Icons.check_circle_rounded
                                    : Icons.flight_takeoff_rounded,
                                label: trip.isPast ? 'Erlebt' : 'Geplant',
                              ),
                              const Spacer(),
                              _HeroIconChip(
                                icon: palette.icon,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.14,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            trip.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x66000000),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.place_rounded,
                                size: 16,
                                color: palette.highlight,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${trip.destination}, ${trip.country}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: AppColors.surfaceGradient,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _TripMeta(
                              icon: Icons.calendar_today_outlined,
                              label: TravelVisuals.formatDateRange(
                                trip.startDate,
                                trip.endDate,
                              ),
                            ),
                            _TripMeta(
                              icon: Icons.timelapse_rounded,
                              label: '${trip.durationDays} Tage',
                            ),
                            _TripMeta(
                              icon: Icons.description_outlined,
                              label: '${trip.documentCount} Dokumente',
                            ),
                            _TripMeta(
                              icon: Icons.photo_library_outlined,
                              label: '${trip.photoCount} Fotos',
                            ),
                            if (trip.albumEntryCount > 0)
                              _TripMeta(
                                icon: Icons.auto_awesome_rounded,
                                label: '${trip.albumEntryCount} Momente',
                                highlighted: true,
                              ),
                          ],
                        ),
                        if (trip.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: 0.34),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.notes_rounded,
                                  size: 18,
                                  color: palette.gradient.last,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    trip.notes,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.text,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconChip extends StatelessWidget {
  const _HeroIconChip({required this.icon, required this.backgroundColor});

  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, size: 19, color: Colors.white),
    );
  }
}

class _TripMeta extends StatelessWidget {
  const _TripMeta({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final background = highlighted ? AppColors.primarySoft : AppColors.surfaceSoft;
    final foreground = highlighted ? AppColors.primary : AppColors.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
