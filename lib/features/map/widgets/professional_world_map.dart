import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/map/domain/map_visit_models.dart';

class ProfessionalWorldMap extends StatefulWidget {
  const ProfessionalWorldMap({
    super.key,
    required this.countries,
    required this.cities,
    required this.routes,
    required this.layer,
    required this.style,
    this.focusedRouteId,
    this.onRouteSelected,
  });

  final List<CountryVisit> countries;
  final List<CityVisit> cities;
  final List<TravelRoute> routes;
  final WorldMapLayer layer;
  final WorldMapStyle style;
  final String? focusedRouteId;
  final ValueChanged<String?>? onRouteSelected;

  @override
  State<ProfessionalWorldMap> createState() => _ProfessionalWorldMapState();
}

class _ProfessionalWorldMapState extends State<ProfessionalWorldMap> {
  static const String _germanTileUrl =
      'https://tile.openstreetmap.de/{z}/{x}/{y}.png';
  static const String _userAgentPackageName = 'com.florysdiaries.app';

  CountryVisit? _selectedCountry;
  CityVisit? _selectedCity;
  TravelRoute? _selectedRoute;

  @override
  void didUpdateWidget(covariant ProfessionalWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusedRouteId != oldWidget.focusedRouteId) {
      _selectedRoute = _findRoute(widget.focusedRouteId);
      if (_selectedRoute != null) {
        _selectedCity = null;
        _selectedCountry = null;
      }
    }

    if (widget.layer != oldWidget.layer) {
      _selectedCountry = null;
      _selectedCity = null;
      _selectedRoute = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.style == WorldMapStyle.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.18) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MapHeader(layer: widget.layer, style: widget.style),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 390,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: widget.cities.isEmpty ? 2.0 : 3.0,
                  minZoom: 2,
                  maxZoom: 12,
                  interactionOptions: const InteractionOptions(
                    flags:
                        InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _germanTileUrl,
                    userAgentPackageName: _userAgentPackageName,
                    tileBuilder: _tileBuilder,
                  ),
                  if (_showRoutes) PolylineLayer(polylines: _routeLines()),
                  if (_showRoutes) MarkerLayer(markers: _routeMarkers()),
                  if (_showCountries) MarkerLayer(markers: _countryMarkers()),
                  if (_showCities) MarkerLayer(markers: _cityMarkers()),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© OpenStreetMap-Mitwirkende · deutscher Kartenstil',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _activeInfo,
          ),
        ],
      ),
    );
  }

  bool get _showCountries =>
      widget.layer == WorldMapLayer.all ||
      widget.layer == WorldMapLayer.countries;
  bool get _showCities =>
      widget.layer == WorldMapLayer.all || widget.layer == WorldMapLayer.cities;
  bool get _showRoutes =>
      widget.layer == WorldMapLayer.all || widget.layer == WorldMapLayer.routes;

  Widget get _activeInfo {
    if (_selectedRoute != null) {
      return _SelectedRouteCard(route: _selectedRoute!);
    }
    if (_selectedCity != null) {
      return _SelectedCityCard(city: _selectedCity!);
    }
    if (_selectedCountry != null) {
      return _SelectedCountryCard(country: _selectedCountry!);
    }
    return _MapHintBar(layer: widget.layer);
  }

  static final LatLng _initialCenter = const LatLng(35, 12);

  Widget _tileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    if (widget.style == WorldMapStyle.dark) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -0.72,
          0,
          0,
          0,
          230,
          0,
          -0.72,
          0,
          0,
          236,
          0,
          0,
          -0.68,
          0,
          244,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: tileWidget,
      );
    }

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        AppColors.primary.withValues(alpha: 0.07),
        BlendMode.srcATop,
      ),
      child: tileWidget,
    );
  }

  TravelRoute? _findRoute(String? routeId) {
    if (routeId == null) return null;
    for (final route in widget.routes) {
      if (route.id == routeId) return route;
    }
    return null;
  }

  List<Polyline> _routeLines() {
    return widget.routes
        .map((route) {
          final isSelected =
              _selectedRoute?.id == route.id ||
              widget.focusedRouteId == route.id;
          final dark = widget.style == WorldMapStyle.dark;
          return Polyline(
            points: [route.fromPosition, route.toPosition],
            color: isSelected
                ? AppColors.sand
                : dark
                ? const Color(0xFF8BDCE3)
                : AppColors.primary.withValues(alpha: 0.55),
            strokeWidth: isSelected ? 5.0 : 2.8,
            borderColor: dark
                ? const Color(0xFF102A36).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.86),
            borderStrokeWidth: 1.4,
          );
        })
        .toList(growable: false);
  }

  List<Marker> _routeMarkers() {
    return widget.routes
        .map((route) {
          final selected =
              _selectedRoute?.id == route.id ||
              widget.focusedRouteId == route.id;
          return Marker(
            point: route.midpoint,
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedRoute = route;
                _selectedCity = null;
                _selectedCountry = null;
                widget.onRouteSelected?.call(route.id);
              }),
              child: _RouteMarker(
                isSelected: selected,
                dark: widget.style == WorldMapStyle.dark,
              ),
            ),
          );
        })
        .toList(growable: false);
  }

  List<Marker> _countryMarkers() {
    return widget.countries
        .map((country) {
          return Marker(
            point: country.position,
            width: 52,
            height: 52,
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedCountry = country;
                _selectedCity = null;
                _selectedRoute = null;
                widget.onRouteSelected?.call(null);
              }),
              child: _CountryMarker(
                country: country,
                dark: widget.style == WorldMapStyle.dark,
              ),
            ),
          );
        })
        .toList(growable: false);
  }

  List<Marker> _cityMarkers() {
    return widget.cities
        .map((city) {
          return Marker(
            point: city.position,
            width: 42,
            height: 42,
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedCity = city;
                _selectedCountry = null;
                _selectedRoute = null;
                widget.onRouteSelected?.call(null);
              }),
              child: _CityMarker(
                city: city,
                dark: widget.style == WorldMapStyle.dark,
              ),
            ),
          );
        })
        .toList(growable: false);
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.layer, required this.style});

  final WorldMapLayer layer;
  final WorldMapStyle style;

  @override
  Widget build(BuildContext context) {
    final dark = style == WorldMapStyle.dark;
    final textColor = dark ? Colors.white : AppColors.text;
    final mutedColor = dark ? Colors.white70 : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Professional World Map',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(Icons.layers_outlined, color: mutedColor, size: 18),
          const SizedBox(width: 6),
          Text(
            '${layer.label} · ${style.label}',
            style: TextStyle(color: mutedColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CountryMarker extends StatelessWidget {
  const _CountryMarker({required this.country, required this.dark});

  final CountryVisit country;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.20)
            : AppColors.sage.withValues(alpha: 0.28),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF9DD7A1) : AppColors.sage,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            country.tripCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CityMarker extends StatelessWidget {
  const _CityMarker({required this.city, required this.dark});

  final CityVisit city;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_on,
      color: dark ? AppColors.sand : AppColors.primary,
      size: 34,
      shadows: dark
          ? const [Shadow(color: Color(0xCC102A36), blurRadius: 5)]
          : null,
    );
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({required this.isSelected, required this.dark});

  final bool isSelected;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.sand
            : dark
            ? const Color(0xFF234957)
            : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(
        Icons.flight_takeoff_rounded,
        color: isSelected
            ? AppColors.text
            : dark
            ? Colors.white
            : AppColors.primary,
        size: 21,
      ),
    );
  }
}

class _MapHintBar extends StatelessWidget {
  const _MapHintBar({required this.layer});

  final WorldMapLayer layer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 2),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aktive Ansicht: ${layer.label}. Tippe auf Marker oder Routen für Details.',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedCountryCard extends StatelessWidget {
  const _SelectedCountryCard({required this.country});

  final CountryVisit country;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: country.country,
      subtitle: '${country.continent} · ${country.cities.join(', ')}',
      values: [
        _InfoValue('Reisen', country.tripCount.toString()),
        _InfoValue('Städte', country.cityCount.toString()),
        _InfoValue('Tage', country.travelDays.toString()),
        _InfoValue('Dok.', country.documentCount.toString()),
      ],
    );
  }
}

class _SelectedCityCard extends StatelessWidget {
  const _SelectedCityCard({required this.city});

  final CityVisit city;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: city.city,
      subtitle: city.country,
      values: [
        _InfoValue('Reisen', city.tripCount.toString()),
        _InfoValue('Tage', city.travelDays.toString()),
        _InfoValue('Dok.', city.documentCount.toString()),
        _InfoValue('Highlights', city.highlightCount.toString()),
      ],
    );
  }
}

class _SelectedRouteCard extends StatelessWidget {
  const _SelectedRouteCard({required this.route});

  final TravelRoute route;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: route.title,
      subtitle: '${route.tripTitle} · ${_formatDate(route.date)}',
      values: [
        _InfoValue('Tage', route.travelDays.toString()),
        _InfoValue('Dok.', route.documentCount.toString()),
        _InfoValue('Highlights', route.highlightCount.toString()),
        _InfoValue('Route', '1'),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.values,
  });

  final String title;
  final String subtitle;
  final List<_InfoValue> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('$title$subtitle'),
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: values
                .map((value) => Expanded(child: _InfoStat(value: value)))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  const _InfoStat({required this.value});

  final _InfoValue value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.value,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        Text(
          value.label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _InfoValue {
  const _InfoValue(this.label, this.value);

  final String label;
  final String value;
}
