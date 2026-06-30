import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:florys_diaries/features/map/application/world_map_viewport.dart';
import 'package:florys_diaries/features/map/domain/map_visit_models.dart';

void main() {
  const berlin = LatLng(52.52, 13.405);
  const paris = LatLng(48.8566, 2.3522);
  const germany = LatLng(51.1657, 10.4515);

  final country = CountryVisit(
    country: 'Deutschland',
    tripCount: 1,
    cityCount: 1,
    travelDays: 3,
    documentCount: 0,
    highlightCount: 0,
    cities: const <String>['Berlin'],
    position: germany,
    continent: 'Europa',
  );

  final city = CityVisit(
    city: 'Berlin',
    country: 'Deutschland',
    tripCount: 1,
    travelDays: 3,
    documentCount: 0,
    highlightCount: 0,
    position: berlin,
  );

  final route = TravelRoute(
    id: 'berlin-paris',
    tripId: 'paris-trip',
    tripTitle: 'Paris',
    fromCity: 'Berlin',
    fromCountry: 'Deutschland',
    toCity: 'Paris',
    toCountry: 'Frankreich',
    fromPosition: berlin,
    toPosition: paris,
    date: DateTime(2026, 6, 1),
    travelDays: 4,
    documentCount: 0,
    highlightCount: 0,
  );

  test('returns only country positions for country layer', () {
    final points = WorldMapViewport.pointsFor(
      countries: <CountryVisit>[country],
      cities: <CityVisit>[city],
      routes: <TravelRoute>[route],
      layer: WorldMapLayer.countries,
    );

    expect(points, <LatLng>[germany]);
  });

  test('focused route overrides the active layer', () {
    final points = WorldMapViewport.pointsFor(
      countries: <CountryVisit>[country],
      cities: <CityVisit>[city],
      routes: <TravelRoute>[route],
      layer: WorldMapLayer.countries,
      focusedRouteId: route.id,
    );

    expect(points, <LatLng>[berlin, paris]);
  });

  test('all layer removes duplicate positions', () {
    final duplicateCity = CityVisit(
      city: 'Berlin Mitte',
      country: 'Deutschland',
      tripCount: 1,
      travelDays: 1,
      documentCount: 0,
      highlightCount: 0,
      position: berlin,
    );

    final points = WorldMapViewport.pointsFor(
      countries: const <CountryVisit>[],
      cities: <CityVisit>[city, duplicateCity],
      routes: <TravelRoute>[route],
      layer: WorldMapLayer.all,
    );

    expect(points, <LatLng>[berlin, paris]);
  });
}
