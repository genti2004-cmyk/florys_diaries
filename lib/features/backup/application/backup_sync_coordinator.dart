import 'dart:async';

import 'package:florys_diaries/features/backup/domain/backup_sync_status.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

typedef BackupSyncOperation = Future<void> Function(List<Trip> trips);
typedef BackupSyncEventHandler = void Function();
typedef BackupSyncErrorHandler =
    void Function(BackupSyncTarget target, Object error, StackTrace stackTrace);

class BackupSyncCoordinator {
  BackupSyncCoordinator({
    required this.localBackupOperation,
    required this.cloudBackupOperation,
    this.debounceDuration = const Duration(seconds: 2),
    this.onScheduled,
    this.onRunStarted,
    this.onRunCompleted,
    this.onError,
  });

  final BackupSyncOperation localBackupOperation;
  final BackupSyncOperation cloudBackupOperation;
  final Duration debounceDuration;
  final BackupSyncEventHandler? onScheduled;
  final BackupSyncEventHandler? onRunStarted;
  final BackupSyncEventHandler? onRunCompleted;
  final BackupSyncErrorHandler? onError;

  Timer? _debounceTimer;
  List<Trip> _latestTrips = const <Trip>[];
  Future<void>? _activeRun;
  bool _hasPendingWork = false;
  bool _isDisposed = false;

  void schedule(Iterable<Trip> trips) {
    if (_isDisposed) {
      return;
    }

    _latestTrips = List<Trip>.unmodifiable(trips);
    _hasPendingWork = true;
    onScheduled?.call();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      _debounceTimer = null;
      unawaited(_drain());
    });
  }

  Future<void> flush(Iterable<Trip> trips) {
    if (_isDisposed) {
      return Future<void>.value();
    }

    _latestTrips = List<Trip>.unmodifiable(trips);
    _hasPendingWork = true;
    onScheduled?.call();
    _debounceTimer?.cancel();
    _debounceTimer = null;
    return _drain();
  }

  void dispose() {
    _isDisposed = true;
    _hasPendingWork = false;
    _latestTrips = const <Trip>[];
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> _drain() {
    final running = _activeRun;
    if (running != null) {
      return running;
    }

    final run = _runPendingChecks();
    _activeRun = run;

    return run.whenComplete(() {
      _activeRun = null;
      if (_hasPendingWork && !_isDisposed) {
        unawaited(_drain());
      }
    });
  }

  Future<void> _runPendingChecks() async {
    while (_hasPendingWork && !_isDisposed) {
      _hasPendingWork = false;
      final snapshot = List<Trip>.unmodifiable(_latestTrips);
      onRunStarted?.call();

      await _runOperation(
        BackupSyncTarget.local,
        localBackupOperation,
        snapshot,
      );
      await _runOperation(
        BackupSyncTarget.cloud,
        cloudBackupOperation,
        snapshot,
      );

      onRunCompleted?.call();
    }
  }

  Future<void> _runOperation(
    BackupSyncTarget target,
    BackupSyncOperation operation,
    List<Trip> trips,
  ) async {
    try {
      await operation(trips);
    } catch (error, stackTrace) {
      onError?.call(target, error, stackTrace);
    }
  }
}
