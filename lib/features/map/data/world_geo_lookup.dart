import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

String normalizeGeoName(String value) => value.trim().toLowerCase();

LatLng? knownCountryPosition(String country) {
  return _countryPositions[normalizeGeoName(country)];
}

LatLng? knownCityPosition(String country, String city) {
  final key = '${normalizeGeoName(country)}|${normalizeGeoName(city)}';
  return _cityPositions[key];
}

LatLng countryPosition(String country) {
  return _countryPositions[normalizeGeoName(country)] ?? const LatLng(20, 10);
}

LatLng cityPosition(String country, String city, LatLng? countryFallback) {
  final key = '${normalizeGeoName(country)}|${normalizeGeoName(city)}';
  final known = _cityPositions[key];
  if (known != null) return known;

  final base = countryFallback ?? countryPosition(country);
  final seed = _stableSeed('$country|$city');
  final angle = (seed % 360) * math.pi / 180;
  final radius = 0.65 + ((seed % 25) / 20);
  return LatLng(
    (base.latitude + math.sin(angle) * radius).clamp(-65, 75).toDouble(),
    (base.longitude + math.cos(angle) * radius).clamp(-175, 175).toDouble(),
  );
}

String continentForCountry(String country) {
  final normalized = normalizeGeoName(country);

  const europe = {
    'albanien',
    'andorra',
    'belgien',
    'bosnien',
    'bosnien und herzegowina',
    'bulgarien',
    'dänemark',
    'deutschland',
    'england',
    'estland',
    'finnland',
    'frankreich',
    'griechenland',
    'irland',
    'island',
    'italien',
    'kroatien',
    'kosovo',
    'lettland',
    'litauen',
    'luxemburg',
    'malta',
    'montenegro',
    'niederlande',
    'norwegen',
    'österreich',
    'polen',
    'portugal',
    'rumänien',
    'schweden',
    'schweiz',
    'serbien',
    'slowakei',
    'slowenien',
    'spanien',
    'tschechien',
    'türkei',
    'ungarn',
    'vereinigtes königreich',
    'zypern',
    'uk',
    'great britain',
    'united kingdom',
    'germany',
    'italy',
    'spain',
    'france',
    'austria',
    'switzerland',
    'netherlands',
    'kosova',
  };
  const northAmerica = {
    'kanada',
    'mexiko',
    'usa',
    'vereinigte staaten',
    'vereinigte staaten von amerika',
    'canada',
    'mexico',
    'united states',
  };
  const southAmerica = {
    'argentinien',
    'bolivien',
    'brasilien',
    'chile',
    'ecuador',
    'kolumbien',
    'peru',
    'uruguay',
    'venezuela',
    'brazil',
    'argentina',
    'colombia',
  };
  const asia = {
    'china',
    'indien',
    'indonesien',
    'israel',
    'japan',
    'katar',
    'malaysia',
    'singapur',
    'südkorea',
    'thailand',
    'vereinigte arabische emirate',
    'vietnam',
    'india',
    'qatar',
    'singapore',
    'south korea',
  };
  const africa = {
    'ägypten',
    'marokko',
    'südafrika',
    'tunesien',
    'egypt',
    'morocco',
    'south africa',
    'tunisia',
  };
  const oceania = {'australien', 'neuseeland', 'australia', 'new zealand'};

  if (europe.contains(normalized)) return 'Europa';
  if (northAmerica.contains(normalized)) return 'Nordamerika';
  if (southAmerica.contains(normalized)) return 'Südamerika';
  if (asia.contains(normalized)) return 'Asien';
  if (africa.contains(normalized)) return 'Afrika';
  if (oceania.contains(normalized)) return 'Ozeanien';
  return 'Noch nicht zugeordnet';
}

int _stableSeed(String value) {
  var seed = 0;
  for (final codeUnit in value.codeUnits) {
    seed = (seed * 31 + codeUnit) & 0x7fffffff;
  }
  return seed;
}

const Map<String, LatLng> _countryPositions = {
  'deutschland': LatLng(51.1657, 10.4515),
  'germany': LatLng(51.1657, 10.4515),
  'italien': LatLng(41.8719, 12.5674),
  'italy': LatLng(41.8719, 12.5674),
  'spanien': LatLng(40.4637, -3.7492),
  'spain': LatLng(40.4637, -3.7492),
  'frankreich': LatLng(46.2276, 2.2137),
  'france': LatLng(46.2276, 2.2137),
  'österreich': LatLng(47.5162, 14.5501),
  'austria': LatLng(47.5162, 14.5501),
  'schweiz': LatLng(46.8182, 8.2275),
  'switzerland': LatLng(46.8182, 8.2275),
  'niederlande': LatLng(52.1326, 5.2913),
  'netherlands': LatLng(52.1326, 5.2913),
  'belgien': LatLng(50.5039, 4.4699),
  'belgium': LatLng(50.5039, 4.4699),
  'portugal': LatLng(39.3999, -8.2245),
  'griechenland': LatLng(39.0742, 21.8243),
  'greece': LatLng(39.0742, 21.8243),
  'türkei': LatLng(38.9637, 35.2433),
  'turkey': LatLng(38.9637, 35.2433),
  'kosovo': LatLng(42.6026, 20.9030),
  'kosova': LatLng(42.6026, 20.9030),
  'albanien': LatLng(41.1533, 20.1683),
  'albania': LatLng(41.1533, 20.1683),
  'kroatien': LatLng(45.1000, 15.2000),
  'croatia': LatLng(45.1000, 15.2000),
  'usa': LatLng(37.0902, -95.7129),
  'vereinigte staaten': LatLng(37.0902, -95.7129),
  'united states': LatLng(37.0902, -95.7129),
  'kanada': LatLng(56.1304, -106.3468),
  'canada': LatLng(56.1304, -106.3468),
  'mexiko': LatLng(23.6345, -102.5528),
  'mexico': LatLng(23.6345, -102.5528),
  'japan': LatLng(36.2048, 138.2529),
  'china': LatLng(35.8617, 104.1954),
  'thailand': LatLng(15.8700, 100.9925),
  'singapur': LatLng(1.3521, 103.8198),
  'singapore': LatLng(1.3521, 103.8198),
  'australien': LatLng(-25.2744, 133.7751),
  'australia': LatLng(-25.2744, 133.7751),
  'brasilien': LatLng(-14.2350, -51.9253),
  'brazil': LatLng(-14.2350, -51.9253),
  'südafrika': LatLng(-30.5595, 22.9375),
  'south africa': LatLng(-30.5595, 22.9375),
  'ägypten': LatLng(26.8206, 30.8025),
  'egypt': LatLng(26.8206, 30.8025),
};

const Map<String, LatLng> _cityPositions = {
  'deutschland|essen': LatLng(51.4556, 7.0116),
  'deutschland|berlin': LatLng(52.5200, 13.4050),
  'deutschland|münchen': LatLng(48.1351, 11.5820),
  'deutschland|munich': LatLng(48.1351, 11.5820),
  'deutschland|hamburg': LatLng(53.5511, 9.9937),
  'deutschland|frankfurt': LatLng(50.1109, 8.6821),
  'italien|rom': LatLng(41.9028, 12.4964),
  'italien|rome': LatLng(41.9028, 12.4964),
  'italien|mailand': LatLng(45.4642, 9.1900),
  'italien|milan': LatLng(45.4642, 9.1900),
  'italien|venedig': LatLng(45.4408, 12.3155),
  'italien|florenz': LatLng(43.7696, 11.2558),
  'spanien|madrid': LatLng(40.4168, -3.7038),
  'spanien|barcelona': LatLng(41.3874, 2.1686),
  'frankreich|paris': LatLng(48.8566, 2.3522),
  'österreich|wien': LatLng(48.2082, 16.3738),
  'austria|vienna': LatLng(48.2082, 16.3738),
  'schweiz|zürich': LatLng(47.3769, 8.5417),
  'netherlands|amsterdam': LatLng(52.3676, 4.9041),
  'niederlande|amsterdam': LatLng(52.3676, 4.9041),
  'kosovo|prishtina': LatLng(42.6629, 21.1655),
  'kosovo|pristina': LatLng(42.6629, 21.1655),
  'albanien|tirana': LatLng(41.3275, 19.8187),
  'usa|new york': LatLng(40.7128, -74.0060),
  'usa|los angeles': LatLng(34.0522, -118.2437),
  'usa|miami': LatLng(25.7617, -80.1918),
  'japan|tokio': LatLng(35.6762, 139.6503),
  'japan|tokyo': LatLng(35.6762, 139.6503),
  'thailand|bangkok': LatLng(13.7563, 100.5018),
  'australien|sydney': LatLng(-33.8688, 151.2093),
};
