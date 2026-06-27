import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/app_section_title.dart';
import 'package:florys_diaries/features/map/data/world_geo_lookup.dart';
import 'package:florys_diaries/features/map/domain/map_visit_models.dart';
import 'package:florys_diaries/features/map/widgets/professional_world_map.dart';
import 'package:florys_diaries/features/map/widgets/world_summary_card.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  WorldMapLayer _layer = WorldMapLayer.all;
  WorldMapStyle _style = WorldMapStyle.light;
  int? _selectedYear;
  String? _focusedRouteId;

  @override
  Widget build(BuildContext context) {
    final allTrips = TripStoreScope.of(context).trips;
    final years = _travelYears(allTrips);
    final trips = _filterTripsByYear(allTrips, _selectedYear);
    final countries = _buildCountryVisits(trips);
    final cities = _buildCityVisits(trips, countries);
    final routes = _buildTravelRoutes(trips);
    final progress = _worldProgress(countries.length);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const AppSectionTitle(
            title: 'World Explorer',
            subtitle: 'Karte, Routen und Reiseziele gezielt steuern.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                WorldSummaryCard(
                  countryCount: countries.length,
                  cityCount: cities.length,
                  tripCount: trips.length,
                  travelDays: trips.fold<int>(
                    0,
                    (sum, trip) => sum + trip.durationDays,
                  ),
                  progressPercent: progress,
                ),
                const SizedBox(height: 14),
                _MapControls(
                  selectedLayer: _layer,
                  selectedStyle: _style,
                  selectedYear: _selectedYear,
                  years: years,
                  onLayerChanged: (layer) => setState(() {
                    _layer = layer;
                    _focusedRouteId = null;
                  }),
                  onStyleChanged: (style) => setState(() => _style = style),
                  onYearChanged: (year) => setState(() {
                    _selectedYear = year;
                    _focusedRouteId = null;
                  }),
                ),
                const SizedBox(height: 14),
                ProfessionalWorldMap(
                  countries: countries,
                  cities: cities,
                  routes: routes,
                  layer: _layer,
                  style: _style,
                  focusedRouteId: _focusedRouteId,
                  onRouteSelected: (routeId) =>
                      setState(() => _focusedRouteId = routeId),
                ),
                const SizedBox(height: 14),
                _TripFocusPanel(
                  trips: trips,
                  routes: routes,
                  focusedRouteId: _focusedRouteId,
                  onRouteFocus: (routeId) => setState(() {
                    _layer = WorldMapLayer.routes;
                    _focusedRouteId = routeId;
                  }),
                ),
                const SizedBox(height: 14),
                _TravelRoutesPanel(
                  routes: routes,
                  focusedRouteId: _focusedRouteId,
                ),
                const SizedBox(height: 14),
                _VisitedCountriesPanel(countries: countries),
                const SizedBox(height: 14),
                _ContinentOverview(continents: _continentStats(countries)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<Trip> _filterTripsByYear(List<Trip> trips, int? year) {
    if (year == null) return trips;
    return trips
        .where(
          (trip) => trip.startDate.year == year || trip.endDate.year == year,
        )
        .toList(growable: false);
  }

  static List<int> _travelYears(List<Trip> trips) {
    final years = <int>{};
    for (final trip in trips) {
      years.add(trip.startDate.year);
      years.add(trip.endDate.year);
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  static List<CountryVisit> _buildCountryVisits(List<Trip> trips) {
    final grouped = <String, List<Trip>>{};
    for (final trip in trips) {
      final country = trip.country.trim();
      if (country.isEmpty) continue;
      grouped.putIfAbsent(country, () => <Trip>[]).add(trip);
    }

    final visits = grouped.entries
        .map((entry) {
          final cities = _uniqueValues(
            entry.value.map((trip) => trip.destination),
          );
          return CountryVisit(
            country: entry.key,
            tripCount: entry.value.length,
            cityCount: cities.length,
            travelDays: entry.value.fold<int>(
              0,
              (sum, trip) => sum + trip.durationDays,
            ),
            documentCount: entry.value.fold<int>(
              0,
              (sum, trip) => sum + trip.documents.length,
            ),
            highlightCount: entry.value.fold<int>(
              0,
              (sum, trip) => sum + trip.highlightCount,
            ),
            cities: cities,
            position: countryPosition(entry.key),
            continent: continentForCountry(entry.key),
          );
        })
        .toList(growable: false);

    visits.sort((a, b) => b.tripCount.compareTo(a.tripCount));
    return visits;
  }

  static List<CityVisit> _buildCityVisits(
    List<Trip> trips,
    List<CountryVisit> countries,
  ) {
    final countryByName = {
      for (final country in countries)
        normalizeGeoName(country.country): country,
    };
    final grouped = <String, List<Trip>>{};

    for (final trip in trips) {
      final country = trip.country.trim();
      final city = trip.destination.trim();
      if (country.isEmpty || city.isEmpty) continue;
      grouped
          .putIfAbsent(
            '${normalizeGeoName(country)}|${normalizeGeoName(city)}',
            () => <Trip>[],
          )
          .add(trip);
    }

    final cities = <CityVisit>[];
    for (final entry in grouped.entries) {
      final firstTrip = entry.value.first;
      final country = firstTrip.country.trim();
      final city = firstTrip.destination.trim();
      final countryVisit = countryByName[normalizeGeoName(country)];
      cities.add(
        CityVisit(
          city: city,
          country: country,
          tripCount: entry.value.length,
          travelDays: entry.value.fold<int>(
            0,
            (sum, trip) => sum + trip.durationDays,
          ),
          documentCount: entry.value.fold<int>(
            0,
            (sum, trip) => sum + trip.documents.length,
          ),
          highlightCount: entry.value.fold<int>(
            0,
            (sum, trip) => sum + trip.highlightCount,
          ),
          position: cityPosition(country, city, countryVisit?.position),
        ),
      );
    }

    cities.sort((a, b) {
      final countryCompare = a.country.toLowerCase().compareTo(
        b.country.toLowerCase(),
      );
      if (countryCompare != 0) return countryCompare;
      return a.city.toLowerCase().compareTo(b.city.toLowerCase());
    });
    return cities;
  }

  static List<TravelRoute> _buildTravelRoutes(List<Trip> trips) {
    final sortedTrips =
        trips
            .where(
              (trip) =>
                  trip.country.trim().isNotEmpty &&
                  trip.destination.trim().isNotEmpty,
            )
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final routes = <TravelRoute>[];
    for (var index = 1; index < sortedTrips.length; index++) {
      final previous = sortedTrips[index - 1];
      final current = sortedTrips[index];
      if (_samePlace(previous, current)) continue;

      routes.add(
        TravelRoute(
          id: '${previous.id}_${current.id}_$index',
          tripId: current.id,
          tripTitle: current.title.trim().isEmpty
              ? '${current.destination}, ${current.country}'
              : current.title.trim(),
          fromCity: previous.destination.trim(),
          fromCountry: previous.country.trim(),
          toCity: current.destination.trim(),
          toCountry: current.country.trim(),
          fromPosition: cityPosition(
            previous.country,
            previous.destination,
            countryPosition(previous.country),
          ),
          toPosition: cityPosition(
            current.country,
            current.destination,
            countryPosition(current.country),
          ),
          date: current.startDate,
          travelDays: current.durationDays,
          documentCount: current.documents.length,
          highlightCount: current.highlightCount,
        ),
      );
    }
    return routes;
  }

  static bool _samePlace(Trip a, Trip b) {
    return normalizeGeoName(a.country) == normalizeGeoName(b.country) &&
        normalizeGeoName(a.destination) == normalizeGeoName(b.destination);
  }

  static List<String> _uniqueValues(Iterable<String> values) {
    final items = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    items.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return items;
  }

  static double _worldProgress(int countryCount) =>
      countryCount <= 0 ? 0 : countryCount / 195 * 100;

  static List<ContinentStat> _continentStats(List<CountryVisit> countries) {
    final stats = <String, int>{};
    for (final country in countries) {
      stats[country.continent] = (stats[country.continent] ?? 0) + 1;
    }
    final result = stats.entries
        .map((entry) => ContinentStat(name: entry.key, count: entry.value))
        .toList();
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.selectedLayer,
    required this.selectedStyle,
    required this.selectedYear,
    required this.years,
    required this.onLayerChanged,
    required this.onStyleChanged,
    required this.onYearChanged,
  });

  final WorldMapLayer selectedLayer;
  final WorldMapStyle selectedStyle;
  final int? selectedYear;
  final List<int> years;
  final ValueChanged<WorldMapLayer> onLayerChanged;
  final ValueChanged<WorldMapStyle> onStyleChanged;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Kartensteuerung',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WorldMapLayer.values
                .map((layer) {
                  return ChoiceChip(
                    label: Text(layer.label),
                    selected: selectedLayer == layer,
                    onSelected: (_) => onLayerChanged(layer),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(labelText: 'Jahr'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Alle Jahre'),
                    ),
                    ...years.map(
                      (year) => DropdownMenuItem<int?>(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    ),
                  ],
                  onChanged: onYearChanged,
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<WorldMapStyle>(
                segments: const [
                  ButtonSegment(
                    value: WorldMapStyle.light,
                    label: Text('Hell'),
                    icon: Icon(Icons.wb_sunny_outlined),
                  ),
                  ButtonSegment(
                    value: WorldMapStyle.dark,
                    label: Text('Dunkel'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {selectedStyle},
                onSelectionChanged: (value) => onStyleChanged(value.first),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripFocusPanel extends StatelessWidget {
  const _TripFocusPanel({
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
    return _Panel(
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
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    route.title,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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

class _TravelRoutesPanel extends StatelessWidget {
  const _TravelRoutesPanel({
    required this.routes,
    required this.focusedRouteId,
  });

  final List<TravelRoute> routes;
  final String? focusedRouteId;

  @override
  Widget build(BuildContext context) {
    return _Panel(
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
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${route.tripTitle} · ${route.travelDays} Tage',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isFocused ? Icons.my_location_rounded : Icons.route_outlined,
            color: AppColors.sage,
          ),
        ],
      ),
    );
  }
}

class _VisitedCountriesPanel extends StatelessWidget {
  const _VisitedCountriesPanel({required this.countries});

  final List<CountryVisit> countries;

  @override
  Widget build(BuildContext context) {
    return _Panel(
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
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${country.cityCount} Städte · ${country.travelDays} Tage · ${country.documentCount} Dokumente',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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

class _ContinentOverview extends StatelessWidget {
  const _ContinentOverview({required this.continents});

  final List<ContinentStat> continents;

  @override
  Widget build(BuildContext context) {
    return _Panel(
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

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
