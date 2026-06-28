import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/map/domain/map_visit_models.dart';
import 'package:florys_diaries/features/map/widgets/world_map_panel.dart';

class WorldMapTravelRoutesPanel extends StatelessWidget {
  const WorldMapTravelRoutesPanel({
    super.key,
    required this.routes,
    required this.focusedRouteId,
  });

  final List<TravelRoute> routes;
  final String? focusedRouteId;

  @override
  Widget build(BuildContext context) {
    return WorldMapPanel(
      title: 'Reiserouten',
      child: routes.isEmpty
          ? const Text(
              'Reiserouten erscheinen, sobald mindestens zwei verschiedene Reiseziele vorhanden sind.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              children: routes
                  .take(6)
                  .map(
                    (route) => _RouteRow(
                      route: route,
                      isFocused: route.id == focusedRouteId,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class WorldMapVisitedCountriesPanel extends StatelessWidget {
  const WorldMapVisitedCountriesPanel({super.key, required this.countries});

  final List<CountryVisit> countries;

  @override
  Widget build(BuildContext context) {
    return WorldMapPanel(
      title: 'Bereiste Länder',
      child: countries.isEmpty
          ? const Text(
              'Noch keine Länder erfasst. Lege eine Reise mit Land und Stadt an.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              children: countries
                  .take(8)
                  .map((country) => _CountryRow(country: country))
                  .toList(growable: false),
            ),
    );
  }
}

class WorldMapContinentOverview extends StatelessWidget {
  const WorldMapContinentOverview({super.key, required this.continents});

  final List<ContinentStat> continents;

  @override
  Widget build(BuildContext context) {
    return WorldMapPanel(
      title: 'Kontinente',
      child: continents.isEmpty
          ? const Text(
              'Kontinent-Statistik erscheint, sobald Reisen vorhanden sind.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              children: continents
                  .map((continent) => _ContinentRow(continent: continent))
                  .toList(growable: false),
            ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.route, required this.isFocused});

  final TravelRoute route;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isFocused
                  ? AppColors.sand.withValues(alpha: 0.45)
                  : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${route.tripTitle} · ${route.travelDays} Tage',
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
          Icon(
            isFocused ? Icons.my_location_rounded : Icons.route_outlined,
            color: AppColors.sage,
          ),
        ],
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({required this.country});

  final CountryVisit country;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.flag_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  country.country,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${country.cityCount} Städte · ${country.travelDays} Tage · ${country.documentCount} Dokumente',
                  maxLines: 2,
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
            '${country.tripCount}x',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinentRow extends StatelessWidget {
  const _ContinentRow({required this.continent});

  final ContinentStat continent;

  @override
  Widget build(BuildContext context) {
    final progress = (continent.count / 54).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  continent.name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${continent.count} Länder',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: AppColors.surfaceSoft,
              color: AppColors.sage,
            ),
          ),
        ],
      ),
    );
  }
}
