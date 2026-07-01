import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_data_empty_state.dart';
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

enum _MapSection { map, routes, countries }

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key, this.analyzer = const WorldMapAnalyzer()});

  final WorldMapAnalyzer analyzer;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  WorldMapLayer _layer = WorldMapLayer.all;
  WorldMapStyle _style = WorldMapStyle.light;
  _MapSection _section = _MapSection.map;
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

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('world-map-v61'),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 156),
          children: [
            Text(
              'Weltkarte',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Deine Reisewelt mit klaren Ansichten für Karte, Routen und Länder.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            WorldSummaryCard(
              countryCount: snapshot.countryCount,
              cityCount: snapshot.cityCount,
              tripCount: snapshot.tripCount,
              travelDays: snapshot.travelDays,
              progressPercent: snapshot.progressPercent,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_MapSection>(
                segments: const [
                  ButtonSegment(
                    value: _MapSection.map,
                    icon: Icon(Icons.public_rounded),
                    label: Text('Karte'),
                  ),
                  ButtonSegment(
                    value: _MapSection.routes,
                    icon: Icon(Icons.route_rounded),
                    label: Text('Routen'),
                  ),
                  ButtonSegment(
                    value: _MapSection.countries,
                    icon: Icon(Icons.flag_outlined),
                    label: Text('Länder'),
                  ),
                ],
                selected: {_section},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    setState(() => _section = selection.first);
                  }
                },
              ),
            ),
            const SizedBox(height: 14),
            if (allTrips.isEmpty)
              const TravelDataEmptyState(
                icon: Icons.public_rounded,
                title: 'Deine Weltkarte wartet auf die erste Reise',
                description:
                    'Sobald du eine Reise mit Land und Reiseziel speicherst, erscheinen hier Länder, Städte und später auch Routen.',
                hint:
                    'Bereits vorhandene Reisen werden automatisch ausgewertet. Eine zusätzliche Eingabe für die Karte ist nicht nötig.',
              )
            else
              ..._sectionContent(
                snapshot: snapshot,
                selectedYear: selectedYear,
                focusedRouteId: focusedRouteId,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sectionContent({
    required WorldMapSnapshot snapshot,
    required int? selectedYear,
    required String? focusedRouteId,
  }) {
    switch (_section) {
      case _MapSection.map:
        return [
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
          RepaintBoundary(
            child: ProfessionalWorldMap(
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
        ];
      case _MapSection.routes:
        return [
          WorldMapTravelRoutesPanel(
            routes: snapshot.routes,
            focusedRouteId: focusedRouteId,
          ),
          const SizedBox(height: 14),
          WorldMapTripFocusPanel(
            trips: snapshot.trips,
            routes: snapshot.routes,
            focusedRouteId: focusedRouteId,
            onRouteFocus: (routeId) {
              setState(() {
                _focusedRouteId = routeId;
                _section = _MapSection.map;
                _layer = WorldMapLayer.routes;
              });
            },
          ),
        ];
      case _MapSection.countries:
        return [
          WorldMapVisitedCountriesPanel(countries: snapshot.countries),
          const SizedBox(height: 14),
          WorldMapContinentOverview(continents: snapshot.continents),
        ];
    }
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
