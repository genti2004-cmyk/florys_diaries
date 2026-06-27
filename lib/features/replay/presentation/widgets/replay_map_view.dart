import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/replay/domain/replay_event.dart';
import 'package:florys_diaries/features/replay/domain/replay_geo_point.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_cinematic_map_controller.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_map_chrome.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_map_marker.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_travel_marker.dart';

class ReplayMapView extends StatefulWidget {
  const ReplayMapView({
    required this.events,
    required this.currentIndex,
    required this.isPlaying,
    super.key,
  });

  final List<ReplayEvent> events;
  final int currentIndex;
  final bool isPlaying;

  @override
  State<ReplayMapView> createState() => _ReplayMapViewState();
}

class _ReplayMapViewState extends State<ReplayMapView>
    with SingleTickerProviderStateMixin {
  late final ReplayCinematicMapController _cinematicController;

  @override
  void initState() {
    super.initState();
    _cinematicController = ReplayCinematicMapController(
      vsync: this,
      initialCenter: _initialCenter,
      initialZoom: _initialZoom,
    );
    final currentPosition = _currentPositionedEvent?.position;
    _cinematicController.setInitialTravelPosition(
      currentPosition == null ? null : _toLatLng(currentPosition),
    );
  }

  @override
  void didUpdateWidget(covariant ReplayMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _moveToCurrentLocation(oldWidget.currentIndex);
    }
  }

  @override
  void dispose() {
    _cinematicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cinematicController,
      builder: (context, _) {
        final visibleEvents = _visiblePositionedEvents;
        final routePoints = _animatedRoutePoints(visibleEvents);
        final currentPositionedEvent = _currentPositionedEvent;

        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReplayMapHeader(
                currentEvent: currentPositionedEvent,
                isPlaying: widget.isPlaying,
              ),
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _cinematicController.mapController,
                      options: MapOptions(
                        initialCenter: _initialCenter,
                        initialZoom: _initialZoom,
                        minZoom: 2,
                        maxZoom: 13,
                        onMapReady: _cinematicController.handleMapReady,
                        onPositionChanged:
                            _cinematicController.handlePositionChanged,
                        interactionOptions: const InteractionOptions(
                          flags:
                              InteractiveFlag.drag |
                              InteractiveFlag.pinchZoom |
                              InteractiveFlag.doubleTapZoom,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.florysdiaries.travel',
                          tileBuilder: _tileBuilder,
                        ),
                        if (routePoints.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                color: AppColors.primary,
                                strokeWidth: 4.2,
                                borderColor: Colors.white.withValues(
                                  alpha: 0.88,
                                ),
                                borderStrokeWidth: 1.5,
                              ),
                            ],
                          ),
                        if (visibleEvents.isNotEmpty ||
                            _cinematicController.travelPosition != null)
                          MarkerLayer(markers: _markers(visibleEvents)),
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              'OpenStreetMap',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (currentPositionedEvent == null)
                      const Positioned.fill(child: ReplayNoPositionOverlay()),
                  ],
                ),
              ),
              ReplayMapFooter(
                positionedCount: visibleEvents.length,
                totalCount: widget.currentIndex + 1,
              ),
            ],
          ),
        );
      },
    );
  }

  ReplayEvent? get _currentPositionedEvent {
    if (widget.events.isEmpty) {
      return null;
    }
    return _positionedEventAtOrBefore(widget.currentIndex);
  }

  ReplayEvent? _positionedEventAtOrBefore(int index) {
    if (widget.events.isEmpty) {
      return null;
    }

    final maxIndex = index.clamp(0, widget.events.length - 1);
    for (var current = maxIndex; current >= 0; current--) {
      final event = widget.events[current];
      if (event.hasPosition) {
        return event;
      }
    }
    return null;
  }

  List<ReplayEvent> get _visiblePositionedEvents {
    if (widget.events.isEmpty) {
      return const [];
    }

    final maxIndex = widget.currentIndex.clamp(0, widget.events.length - 1);
    return widget.events
        .take(maxIndex + 1)
        .where((event) => event.hasPosition)
        .toList(growable: false);
  }

  LatLng get _initialCenter {
    for (final event in widget.events) {
      final position = event.position;
      if (position != null && position.isValid) {
        return _toLatLng(position);
      }
    }
    return const LatLng(35, 12);
  }

  double get _initialZoom {
    return widget.events.any((event) => event.hasPosition) ? 5.2 : 2.4;
  }

  void _moveToCurrentLocation(int oldIndex) {
    final targetPosition = _currentPositionedEvent?.position;
    if (targetPosition == null || !targetPosition.isValid) {
      _cinematicController.reset(center: _initialCenter, zoom: _initialZoom);
      return;
    }

    final target = _toLatLng(targetPosition);
    final previousPosition = _positionedEventAtOrBefore(oldIndex)?.position;
    final previous = previousPosition == null || !previousPosition.isValid
        ? target
        : _toLatLng(previousPosition);

    _cinematicController.animateTo(target: target, previous: previous);
  }

  List<LatLng> _animatedRoutePoints(List<ReplayEvent> events) {
    final points = _routePoints(events).toList();
    final travelPosition = _cinematicController.travelPosition;

    if (!_cinematicController.isAnimating || travelPosition == null) {
      return points;
    }

    if (points.isNotEmpty &&
        ReplayCinematicMapController.samePosition(
          points.last,
          _cinematicController.animationTarget,
        )) {
      points.removeLast();
    }
    if (points.isEmpty ||
        !ReplayCinematicMapController.samePosition(
          points.last,
          _cinematicController.animationTravelFrom,
        )) {
      points.add(_cinematicController.animationTravelFrom);
    }
    if (!ReplayCinematicMapController.samePosition(
      points.last,
      travelPosition,
    )) {
      points.add(travelPosition);
    }
    return points;
  }

  List<LatLng> _routePoints(List<ReplayEvent> events) {
    final points = <LatLng>[];
    ReplayGeoPoint? previous;

    for (final event in events) {
      final position = event.position;
      if (position == null || !position.isValid) {
        continue;
      }
      if (previous != null && previous.isSameAs(position)) {
        continue;
      }
      points.add(_toLatLng(position));
      previous = position;
    }
    return points;
  }

  List<Marker> _markers(List<ReplayEvent> events) {
    final eventsByPosition = <String, ReplayEvent>{};
    for (final event in events) {
      final position = event.position!;
      eventsByPosition[_positionKey(position)] = event;
    }

    final currentPosition = _currentPositionedEvent?.position;
    final markers = eventsByPosition.values.map((event) {
      final position = event.position!;
      final isCurrent = currentPosition?.isSameAs(position) ?? false;
      return Marker(
        point: _toLatLng(position),
        width: isCurrent ? 58 : 40,
        height: isCurrent ? 58 : 40,
        child: ReplayMapMarker(
          event: event,
          isCurrent: isCurrent,
          isPlaying: widget.isPlaying,
        ),
      );
    }).toList();

    final travelPosition = _cinematicController.travelPosition;
    if (travelPosition != null) {
      markers.add(
        Marker(
          point: travelPosition,
          width: 56,
          height: 56,
          child: ReplayTravelMarker(
            bearingDegrees: _cinematicController.travelBearing,
            isPlaying: widget.isPlaying || _cinematicController.isAnimating,
          ),
        ),
      );
    }

    return markers;
  }

  Widget _tileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        AppColors.primary.withValues(alpha: 0.06),
        BlendMode.srcATop,
      ),
      child: tileWidget,
    );
  }

  static String _positionKey(ReplayGeoPoint position) {
    return '${position.latitude.toStringAsFixed(6)}|${position.longitude.toStringAsFixed(6)}';
  }

  static LatLng _toLatLng(ReplayGeoPoint point) {
    return LatLng(point.latitude, point.longitude);
  }
}
