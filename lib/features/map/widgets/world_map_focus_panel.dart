import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/map/domain/map_visit_models.dart';
import 'package:florys_diaries/features/map/widgets/world_map_panel.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class WorldMapTripFocusPanel extends StatelessWidget {
  const WorldMapTripFocusPanel({
    super.key,
    required this.trips,
    required this.routes,
    required this.focusedRouteId,
    required this.onRouteFocus,
  });

  final List<Trip> trips;
  final List<TravelRoute> routes;
  final String? focusedRouteId;
  final ValueChanged<String> onRouteFocus;

  @override
  Widget build(BuildContext context) {
    final routesByTrip = {for (final route in routes) route.tripId: route};
    final items = trips
        .where((trip) => routesByTrip.containsKey(trip.id))
        .take(5)
        .toList(growable: false);

    return WorldMapPanel(
      title: 'Reise fokussieren',
      child: items.isEmpty
          ? const Text(
              'Sobald mehrere Reiseziele vorhanden sind, kannst du einzelne Reisen auf der Karte hervorheben.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              children: items
                  .map((trip) {
                    final route = routesByTrip[trip.id]!;
                    return _TripFocusRow(
                      trip: trip,
                      route: route,
                      isFocused: route.id == focusedRouteId,
                      onTap: () => onRouteFocus(route.id),
                    );
                  })
                  .toList(growable: false),
            ),
    );
  }
}

class _TripFocusRow extends StatelessWidget {
  const _TripFocusRow({
    required this.trip,
    required this.route,
    required this.isFocused,
    required this.onTap,
  });

  final Trip trip;
  final TravelRoute route;
  final bool isFocused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFocused ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFocused ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.near_me_outlined,
              color: isFocused ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    route.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${trip.durationDays} Tage',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
