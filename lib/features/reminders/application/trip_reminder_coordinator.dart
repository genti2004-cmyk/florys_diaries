import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:florys_diaries/features/reminders/data/trip_reminder_notification_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripReminderCoordinator {
  TripReminderCoordinator({
    TripReminderNotificationService? service,
    this.debounce = const Duration(milliseconds: 350),
  }) : _service = service ?? TripReminderNotificationService.instance;

  final TripReminderNotificationService _service;
  final Duration debounce;

  Timer? _timer;
  List<Trip> _pendingTrips = const [];
  bool _disposed = false;
  bool _isRunning = false;
  bool _runAgain = false;

  void schedule(Iterable<Trip> trips) {
    if (_disposed) {
      return;
    }
    _pendingTrips = List<Trip>.unmodifiable(trips);
    _timer?.cancel();
    _timer = Timer(debounce, () {
      unawaited(flush(_pendingTrips));
    });
  }

  Future<void> flush(Iterable<Trip> trips) async {
    if (_disposed) {
      return;
    }
    _pendingTrips = List<Trip>.unmodifiable(trips);
    _timer?.cancel();
    _timer = null;

    if (_isRunning) {
      _runAgain = true;
      return;
    }

    _isRunning = true;
    try {
      do {
        _runAgain = false;
        final snapshot = _pendingTrips;
        try {
          await _service.syncAll(snapshot);
        } catch (error, stackTrace) {
          debugPrint(
            'Reiseerinnerungen konnten nicht aktualisiert werden: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
      } while (_runAgain && !_disposed);
    } finally {
      _isRunning = false;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
