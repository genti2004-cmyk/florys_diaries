import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/constants/app_metadata.dart';
import 'package:florys_diaries/features/map/application/world_map_viewport.dart';
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
  static const String _userAgentPackageName =
      AppMetadata.mapUserAgentPackageName;
  static const LatLng _worldCenter = LatLng(24, 12);

  final MapController _mapController = MapController();

  bool _mapReady = false;
  CountryVisit? _selectedCountry;
  CityVisit? _selectedCity;
  TravelRoute? _selectedRoute;

  @override
  void didUpdateWidget(covariant ProfessionalWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final focusChanged = widget.focusedRouteId != oldWidget.focusedRouteId;
    final contentChanged =
        !identical(widget.countries, oldWidget.countries) ||
        !identical(widget.cities, oldWidget.cities) ||
        !identical(widget.routes, oldWidget.routes);
    final layerChanged = widget.layer != oldWidget.layer;

    if (focusChanged) {
      _selectedRoute = _findRoute(widget.focusedRouteId);
      if (_selectedRoute != null) {
        _selectedCity = null;
        _selectedCountry = null;
      }
    }

    if (layerChanged) {
      _selectedCountry = null;
      _selectedCity = null;
      _selectedRoute = null;
    }

    if (focusChanged || contentChanged || layerChanged) {
      _scheduleFitVisibleContent();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.style == WorldMapStyle.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF102F39), Color(0xFF0B2028)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF0F7F6)],
              ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.16) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: dark ? 0.20 : 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MapHeader(
            layer: widget.layer,
            style: widget.style,
            countryCount: widget.countries.length,
            cityCount: widget.cities.length,
            routeCount: widget.routes.length,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 420,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: dark
                          ? const Color(0xFF193844)
                          : const Color(0xFFEAF3F2),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _initialCenter,
                          initialZoom: _initialZoom,
                          minZoom: 2,
                          maxZoom: 12,
                          onMapReady: _handleMapReady,
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
                          if (_showRoutes)
                            PolylineLayer(polylines: _routeLines()),
                          if (_showRoutes)
                            MarkerLayer(markers: _routeMarkers()),
                          if (_showCountries)
                            MarkerLayer(markers: _countryMarkers()),
                          if (_showCities) MarkerLayer(markers: _cityMarkers()),
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                '© OpenStreetMap-Mitwirkende',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _MapStatsPill(
                      countryCount: widget.countries.length,
                      cityCount: widget.cities.length,
                      dark: dark,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _MapCameraControls(
                      dark: dark,
                      onZoomIn: () => _zoomBy(1),
                      onZoomOut: () => _zoomBy(-1),
                      onFit: _fitVisibleContent,
                    ),
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

  List<LatLng> get _visiblePoints {
    return WorldMapViewport.pointsFor(
      countries: widget.countries,
      cities: widget.cities,
      routes: widget.routes,
      layer: widget.layer,
      focusedRouteId: widget.focusedRouteId,
    );
  }

  LatLng get _initialCenter {
    final points = _visiblePoints;
    return points.length == 1 ? points.single : _worldCenter;
  }

  double get _initialZoom {
    final count = _visiblePoints.length;
    if (count == 1) {
      return widget.layer == WorldMapLayer.countries ? 5.4 : 7.4;
    }
    return 2.2;
  }

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

  void _handleMapReady() {
    _mapReady = true;
    _scheduleFitVisibleContent();
  }

  void _scheduleFitVisibleContent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _fitVisibleContent();
    });
  }

  void _fitVisibleContent() {
    if (!_mapReady) {
      return;
    }

    final points = _visiblePoints;
    if (points.isEmpty) {
      _mapController.move(_worldCenter, 2.2);
      return;
    }

    if (points.length == 1) {
      final zoom = widget.layer == WorldMapLayer.countries ? 5.4 : 7.4;
      _mapController.move(points.single, zoom);
      return;
    }

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(44, 72, 44, 54),
        minZoom: 2,
        maxZoom: widget.focusedRouteId == null ? 7.2 : 8.4,
      ),
    );
  }

  void _focusPoint(LatLng point, double zoom) {
    if (!_mapReady) {
      return;
    }
    _mapController.move(point, zoom);
  }

  void _focusRoute(TravelRoute route) {
    if (!_mapReady) {
      return;
    }

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: <LatLng>[route.fromPosition, route.toPosition],
        padding: const EdgeInsets.fromLTRB(52, 82, 52, 62),
        minZoom: 2,
        maxZoom: 8.4,
      ),
    );
  }

  void _zoomBy(double delta) {
    if (!_mapReady) {
      return;
    }

    final camera = _mapController.camera;
    final zoom = (camera.zoom + delta).clamp(2.0, 12.0).toDouble();
    _mapController.move(camera.center, zoom);
  }

  Widget _tileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    if (widget.style == WorldMapStyle.dark) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -0.64,
          0,
          0,
          0,
          216,
          0,
          -0.64,
          0,
          0,
          224,
          0,
          0,
          -0.60,
          0,
          232,
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
        const Color(0xFFDCF0EE).withValues(alpha: 0.16),
        BlendMode.srcATop,
      ),
      child: tileWidget,
    );
  }

  TravelRoute? _findRoute(String? routeId) {
    if (routeId == null) {
      return null;
    }
    for (final route in widget.routes) {
      if (route.id == routeId) {
        return route;
      }
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
            points: <LatLng>[route.fromPosition, route.toPosition],
            color: isSelected
                ? AppColors.sand
                : dark
                ? const Color(0xFF8BDCE3)
                : AppColors.primary.withValues(alpha: 0.62),
            strokeWidth: isSelected ? 5.2 : 3.0,
            borderColor: dark
                ? const Color(0xFF102A36).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.92),
            borderStrokeWidth: 1.5,
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
              onTap: () {
                setState(() {
                  _selectedRoute = route;
                  _selectedCity = null;
                  _selectedCountry = null;
                });
                widget.onRouteSelected?.call(route.id);
                _focusRoute(route);
              },
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
            width: 54,
            height: 54,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCountry = country;
                  _selectedCity = null;
                  _selectedRoute = null;
                });
                widget.onRouteSelected?.call(null);
                _focusPoint(country.position, 5.8);
              },
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
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCity = city;
                  _selectedCountry = null;
                  _selectedRoute = null;
                });
                widget.onRouteSelected?.call(null);
                _focusPoint(city.position, 8.6);
              },
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
  const _MapHeader({
    required this.layer,
    required this.style,
    required this.countryCount,
    required this.cityCount,
    required this.routeCount,
  });

  final WorldMapLayer layer;
  final WorldMapStyle style;
  final int countryCount;
  final int cityCount;
  final int routeCount;

  @override
  Widget build(BuildContext context) {
    final dark = style == WorldMapStyle.dark;
    final textColor = dark ? Colors.white : AppColors.text;
    final mutedColor = dark ? Colors.white70 : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.travel_explore_rounded,
              color: dark ? Colors.white : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interaktive Reisekarte',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$countryCount Länder · $cityCount Städte · '
                  '$routeCount Routen',
                  style: TextStyle(
                    color: mutedColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${layer.label} · ${style.label}',
            style: TextStyle(
              color: mutedColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCameraControls extends StatelessWidget {
  const _MapCameraControls({
    required this.dark,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
  });

  final bool dark;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark
          ? const Color(0xE61B3E49)
          : Colors.white.withValues(alpha: 0.94),
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapControlButton(
            tooltip: 'Vergrößern',
            icon: Icons.add_rounded,
            onPressed: onZoomIn,
          ),
          _ControlDivider(dark: dark),
          _MapControlButton(
            tooltip: 'Verkleinern',
            icon: Icons.remove_rounded,
            onPressed: onZoomOut,
          ),
          _ControlDivider(dark: dark),
          _MapControlButton(
            tooltip: 'Alle Reiseziele anzeigen',
            icon: Icons.center_focus_strong_rounded,
            onPressed: onFit,
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: Icon(icon, size: 21),
    );
  }
}

class _ControlDivider extends StatelessWidget {
  const _ControlDivider({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 1,
      color: dark ? Colors.white.withValues(alpha: 0.16) : AppColors.border,
    );
  }
}

class _MapStatsPill extends StatelessWidget {
  const _MapStatsPill({
    required this.countryCount,
    required this.cityCount,
    required this.dark,
  });

  final int countryCount;
  final int cityCount;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('world-map-visible-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xE61B3E49)
            : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: 0.15) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.public_rounded,
            size: 16,
            color: dark ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$countryCount Länder · $cityCount Städte',
            style: TextStyle(
              color: dark ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
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
