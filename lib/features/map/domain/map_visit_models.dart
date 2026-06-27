import 'package:latlong2/latlong.dart';

class CountryVisit {
  const CountryVisit({
    required this.country,
    required this.tripCount,
    required this.cityCount,
    required this.travelDays,
    required this.documentCount,
    required this.highlightCount,
    required this.cities,
    required this.position,
    required this.continent,
  });

  final String country;
  final int tripCount;
  final int cityCount;
  final int travelDays;
  final int documentCount;
  final int highlightCount;
  final List<String> cities;
  final LatLng position;
  final String continent;
}

class CityVisit {
  const CityVisit({
    required this.city,
    required this.country,
    required this.tripCount,
    required this.travelDays,
    required this.documentCount,
    required this.highlightCount,
    required this.position,
  });

  final String city;
  final String country;
  final int tripCount;
  final int travelDays;
  final int documentCount;
  final int highlightCount;
  final LatLng position;
}

class TravelRoute {
  const TravelRoute({
    required this.id,
    required this.tripId,
    required this.tripTitle,
    required this.fromCity,
    required this.fromCountry,
    required this.toCity,
    required this.toCountry,
    required this.fromPosition,
    required this.toPosition,
    required this.date,
    required this.travelDays,
    required this.documentCount,
    required this.highlightCount,
  });

  final String id;
  final String tripId;
  final String tripTitle;
  final String fromCity;
  final String fromCountry;
  final String toCity;
  final String toCountry;
  final LatLng fromPosition;
  final LatLng toPosition;
  final DateTime date;
  final int travelDays;
  final int documentCount;
  final int highlightCount;

  String get title => '$fromCity → $toCity';

  LatLng get midpoint {
    return LatLng(
      (fromPosition.latitude + toPosition.latitude) / 2,
      (fromPosition.longitude + toPosition.longitude) / 2,
    );
  }
}

class ContinentStat {
  const ContinentStat({required this.name, required this.count});

  final String name;
  final int count;
}

enum WorldMapLayer {
  all('Alle'),
  countries('Länder'),
  cities('Städte'),
  routes('Routen');

  const WorldMapLayer(this.label);

  final String label;
}

enum WorldMapStyle {
  light('Hell'),
  dark('Dunkel');

  const WorldMapStyle(this.label);

  final String label;
}
