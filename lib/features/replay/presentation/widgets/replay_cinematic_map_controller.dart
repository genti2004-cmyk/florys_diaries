import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ReplayCinematicMapController extends ChangeNotifier {
  ReplayCinematicMapController({
    required TickerProvider vsync,
    required LatLng initialCenter,
    required double initialZoom,
  })  : mapController = MapController(),
        _cameraCenter = initialCenter,
        _cameraZoom = initialZoom,
        _animationCameraFrom = initialCenter,
        _animationTravelFrom = initialCenter,
        _animationTarget = initialCenter,
        _animationFromZoom = initialZoom,
        _animationTravelZoom = initialZoom,
        _animationTargetZoom = initialZoom {
    _animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 680),
    )..addListener(_handleFrame);
  }

  final MapController mapController;
  late final AnimationController _animationController;

  bool _mapReady = false;
  LatLng _cameraCenter;
  double _cameraZoom;
  LatLng _animationCameraFrom;
  LatLng _animationTravelFrom;
  LatLng _animationTarget;
  double _animationFromZoom;
  double _animationTravelZoom;
  double _animationTargetZoom;
  LatLng? _travelPosition;
  double _travelBearing = 0;

  bool get isAnimating => _animationController.isAnimating;

  LatLng? get travelPosition => _travelPosition;

  LatLng get animationTravelFrom => _animationTravelFrom;

  LatLng get animationTarget => _animationTarget;

  double get travelBearing => _travelBearing;

  void handleMapReady() {
    _mapReady = true;
    _cameraCenter = mapController.camera.center;
    _cameraZoom = mapController.camera.zoom;
  }

  void handlePositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture || isAnimating) {
      return;
    }
    _cameraCenter = camera.center;
    _cameraZoom = camera.zoom;
  }

  void setInitialTravelPosition(LatLng? position) {
    _travelPosition = position;
  }

  void reset({required LatLng center, required double zoom}) {
    _animationController.stop();
    _cameraCenter = center;
    _cameraZoom = zoom;
    _animationCameraFrom = center;
    _animationTravelFrom = center;
    _animationTarget = center;
    _animationFromZoom = zoom;
    _animationTravelZoom = zoom;
    _animationTargetZoom = zoom;
    _travelPosition = null;
    _travelBearing = 0;

    if (_mapReady) {
      mapController.move(center, zoom);
    }
  }

  void animateTo({required LatLng target, required LatLng previous}) {
    final currentTravelPosition = _travelPosition;
    if (isAnimating && _samePosition(_animationTarget, target)) {
      return;
    }
    if (currentTravelPosition != null &&
        _samePosition(currentTravelPosition, target)) {
      return;
    }

    _animationCameraFrom = _cameraCenter;
    _animationTravelFrom = currentTravelPosition ?? previous;
    _animationTarget = target;
    _animationFromZoom = _cameraZoom;

    final distanceKm = _distanceInKilometers(
      _animationTravelFrom,
      _animationTarget,
    );
    _animationTravelZoom = _travelZoomForDistance(distanceKm);
    _animationTargetZoom = _targetZoomForDistance(distanceKm);
    _travelBearing = _bearingDegrees(
      _animationTravelFrom,
      _animationTarget,
    );

    if (!_mapReady) {
      _cameraCenter = target;
      _cameraZoom = _animationTargetZoom;
      _travelPosition = target;
      return;
    }

    _animationController.forward(from: 0);
  }

  void _handleFrame() {
    if (!_mapReady) {
      return;
    }

    final eased = Curves.easeInOutCubic.transform(_animationController.value);
    final center = _lerpPosition(
      _animationCameraFrom,
      _animationTarget,
      eased,
    );
    final travel = _lerpPosition(
      _animationTravelFrom,
      _animationTarget,
      eased,
    );
    final zoom = _cinematicZoom(_animationController.value);

    _cameraCenter = center;
    _cameraZoom = zoom;
    _travelPosition = travel;
    mapController.move(center, zoom);
    notifyListeners();
  }

  double _cinematicZoom(double progress) {
    if (progress <= 0.55) {
      final phase = Curves.easeOutCubic.transform(progress / 0.55);
      return _lerpDouble(_animationFromZoom, _animationTravelZoom, phase);
    }

    final phase = Curves.easeInOutCubic.transform((progress - 0.55) / 0.45);
    return _lerpDouble(_animationTravelZoom, _animationTargetZoom, phase);
  }

  @override
  void dispose() {
    _animationController.dispose();
    mapController.dispose();
    super.dispose();
  }

  static bool samePosition(LatLng first, LatLng second) {
    return _samePosition(first, second);
  }

  static bool _samePosition(LatLng first, LatLng second) {
    return (first.latitude - second.latitude).abs() < 0.000001 &&
        (first.longitude - second.longitude).abs() < 0.000001;
  }

  static double _distanceInKilometers(LatLng from, LatLng to) {
    const earthRadiusKm = 6371.0;
    final latitudeDelta = _toRadians(to.latitude - from.latitude);
    final longitudeDelta = _toRadians(to.longitude - from.longitude);
    final firstLatitude = _toRadians(from.latitude);
    final secondLatitude = _toRadians(to.latitude);

    final a = math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(firstLatitude) *
            math.cos(secondLatitude) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    final normalizedA = a.clamp(0.0, 1.0).toDouble();
    final c = 2 * math.atan2(
      math.sqrt(normalizedA),
      math.sqrt(1 - normalizedA),
    );
    return earthRadiusKm * c;
  }

  static double _travelZoomForDistance(double distanceKm) {
    if (distanceKm < 10) {
      return 10.5;
    }
    if (distanceKm < 80) {
      return 8.6;
    }
    if (distanceKm < 350) {
      return 6.8;
    }
    if (distanceKm < 1200) {
      return 5.4;
    }
    return 3.8;
  }

  static double _targetZoomForDistance(double distanceKm) {
    if (distanceKm < 5) {
      return 11.5;
    }
    if (distanceKm < 40) {
      return 9.5;
    }
    if (distanceKm < 300) {
      return 8.0;
    }
    return 7.0;
  }

  static double _bearingDegrees(LatLng from, LatLng to) {
    final fromLatitude = _toRadians(from.latitude);
    final toLatitude = _toRadians(to.latitude);
    final longitudeDelta = _toRadians(to.longitude - from.longitude);

    final y = math.sin(longitudeDelta) * math.cos(toLatitude);
    final x = math.cos(fromLatitude) * math.sin(toLatitude) -
        math.sin(fromLatitude) *
            math.cos(toLatitude) *
            math.cos(longitudeDelta);
    return math.atan2(y, x) * 180 / math.pi;
  }

  static LatLng _lerpPosition(LatLng from, LatLng to, double progress) {
    return LatLng(
      _lerpDouble(from.latitude, to.latitude, progress),
      _lerpDouble(from.longitude, to.longitude, progress),
    );
  }

  static double _lerpDouble(double from, double to, double progress) {
    return from + ((to - from) * progress);
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
