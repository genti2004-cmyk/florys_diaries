import 'package:florys_diaries/features/map/domain/map_visit_models.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class WorldMapSnapshot {
  const WorldMapSnapshot({
    required this.years,
    required this.trips,
    required this.countries,
    required this.cities,
    required this.routes,
    required this.continents,
    required this.travelDays,
    required this.progressPercent,
  });

  final List<int> years;
  final List<Trip> trips;
  final List<CountryVisit> countries;
  final List<CityVisit> cities;
  final List<TravelRoute> routes;
  final List<ContinentStat> continents;
  final int travelDays;
  final double progressPercent;

  int get tripCount => trips.length;

  int get countryCount => countries.length;

  int get cityCount => cities.length;
}
