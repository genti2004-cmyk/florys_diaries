import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/app_section_title.dart';
import 'package:florys_diaries/features/map/application/world_map_analyzer.dart';
import 'package:florys_diaries/features/map/domain/map_visit_models.dart';
import 'package:florys_diaries/features/map/domain/world_map_snapshot.dart';
import 'package:florys_diaries/features/map/widgets/professional_world_map.dart';
import 'package:florys_diaries/features/map/widgets/world_map_controls.dart';
import 'package:florys_diaries/features/map/widgets/world_map_focus_panel.dart';
import 'package:florys_diaries/features/map/widgets/world_map_overview_panels.dart';
import 'package:florys_diaries/features/map/widgets/world_summary_card.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key, this.analyzer = const WorldMapAnalyzer()});

  final WorldMapAnalyzer analyzer;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  WorldMapLayer _layer = WorldMapLayer.all;
  WorldMapStyle _style = WorldMapStyle.light;
  int? _selectedYear;
  String? _focusedRouteId;

  List<Trip>? _analyzedTrips;
  int? _analyzedYear;
  WorldMapSnapshot? _snapshot;

  @override
  void didUpdateWidget(covariant WorldMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.analyzer, oldWidget.analyzer)) {
      _clearAnalysisCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTrips = TripStoreScope.of(context).trips;
    final snapshot = _snapshotFor(allTrips, _selectedYear);
    final selectedYear = snapshot.years.contains(_selectedYear)
        ? _selectedYear
        : null;
    final focusedRouteId =
        snapshot.routes.any((route) => route.id == _focusedRouteId)
        ? _focusedRouteId
        : null;

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
                  countryCount: snapshot.countryCount,
                  cityCount: snapshot.cityCount,
                  tripCount: snapshot.tripCount,
                  travelDays: snapshot.travelDays,
                  progressPercent: snapshot.progressPercent,
                ),
                const SizedBox(height: 14),
                WorldMapControls(
                  selectedLayer: _layer,
                  selectedStyle: _style,
                  selectedYear: selectedYear,
                  years: snapshot.years,
                  onLayerChanged: (layer) {
                    setState(() {
                      _layer = layer;
                      _focusedRouteId = null;
                    });
                  },
                  onStyleChanged: (style) {
                    setState(() => _style = style);
                  },
                  onYearChanged: (year) {
                    setState(() {
                      _selectedYear = year;
                      _focusedRouteId = null;
                    });
                  },
                ),
                const SizedBox(height: 14),
                ProfessionalWorldMap(
                  countries: snapshot.countries,
                  cities: snapshot.cities,
                  routes: snapshot.routes,
                  layer: _layer,
                  style: _style,
                  focusedRouteId: focusedRouteId,
                  onRouteSelected: (routeId) {
                    setState(() => _focusedRouteId = routeId);
                  },
                ),
                const SizedBox(height: 14),
                WorldMapTripFocusPanel(
                  trips: snapshot.trips,
                  routes: snapshot.routes,
                  focusedRouteId: focusedRouteId,
                  onRouteFocus: (routeId) {
                    setState(() {
                      _layer = WorldMapLayer.routes;
                      _focusedRouteId = routeId;
                    });
                  },
                ),
                const SizedBox(height: 14),
                WorldMapTravelRoutesPanel(
                  routes: snapshot.routes,
                  focusedRouteId: focusedRouteId,
                ),
                const SizedBox(height: 14),
                WorldMapVisitedCountriesPanel(countries: snapshot.countries),
                const SizedBox(height: 14),
                WorldMapContinentOverview(continents: snapshot.continents),
              ],
            ),
          ),
        ],
      ),
    );
  }

  WorldMapSnapshot _snapshotFor(List<Trip> trips, int? year) {
    if (!identical(_analyzedTrips, trips) ||
        _analyzedYear != year ||
        _snapshot == null) {
      _analyzedTrips = trips;
      _analyzedYear = year;
      _snapshot = widget.analyzer.analyze(trips, year: year);
    }

    return _snapshot!;
  }

  void _clearAnalysisCache() {
    _analyzedTrips = null;
    _analyzedYear = null;
    _snapshot = null;
  }
}
