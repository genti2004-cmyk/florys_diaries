import 'package:latlong2/latlong.dart';

import 'package:florys_diaries/features/map/domain/map_visit_models.dart';

class WorldMapViewport {
  const WorldMapViewport._();

  static List<LatLng> pointsFor({
    required List<CountryVisit> countries,
    required List<CityVisit> cities,
    required List<TravelRoute> routes,
    required WorldMapLayer layer,
    String? focusedRouteId,
  }) {
    final focusedRoute = _routeById(routes, focusedRouteId);
    if (focusedRoute != null) {
      return _unique(<LatLng>[
        focusedRoute.fromPosition,
        focusedRoute.toPosition,
      ]);
    }

    final points = switch (layer) {
      WorldMapLayer.countries =>
        countries.map((country) => country.position).toList(growable: false),
      WorldMapLayer.cities =>
        cities.map((city) => city.position).toList(growable: false),
      WorldMapLayer.routes =>
        routes
            .expand((route) => <LatLng>[route.fromPosition, route.toPosition])
            .toList(growable: false),
      WorldMapLayer.all => <LatLng>[
        ...countries.map((country) => country.position),
        ...cities.map((city) => city.position),
        ...routes.expand(
          (route) => <LatLng>[route.fromPosition, route.toPosition],
        ),
      ],
    };

    return _unique(points);
  }

  static TravelRoute? _routeById(List<TravelRoute> routes, String? routeId) {
    if (routeId == null) {
      return null;
    }

    for (final route in routes) {
      if (route.id == routeId) {
        return route;
      }
    }
    return null;
  }

  static List<LatLng> _unique(Iterable<LatLng> source) {
    final keys = <String>{};
    final points = <LatLng>[];

    for (final point in source) {
      final key =
          '${point.latitude.toStringAsFixed(6)}|'
          '${point.longitude.toStringAsFixed(6)}';
      if (keys.add(key)) {
        points.add(point);
      }
    }

    return List<LatLng>.unmodifiable(points);
  }
}
