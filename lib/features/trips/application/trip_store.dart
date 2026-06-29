import 'package:flutter/foundation.dart';

import '../data/trip_storage_service.dart';
import '../domain/trip.dart';

typedef TripStoreClock = DateTime Function();

class TripStore extends ChangeNotifier {
  TripStore({
    TripStorageService storageService = const TripStorageService(),
    TripStoreClock? now,
  }) : _storageService = storageService,
       _now = now ?? DateTime.now;

  final TripStorageService _storageService;
  final TripStoreClock _now;
  final List<Trip> _trips = [];

  List<Trip> _sortedTrips = const <Trip>[];
  List<Trip> _upcomingTrips = const <Trip>[];
  List<Trip> _pastTrips = const <Trip>[];
  DateTime? _partitionDate;
  String? _loadErrorMessage;
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  bool get hasLoadError => _loadErrorMessage != null;

  String? get loadErrorMessage => _loadErrorMessage;

  List<Trip> get trips => _sortedTrips;

  List<Trip> get upcomingTrips {
    _refreshDatePartitionsIfNeeded();
    return _upcomingTrips;
  }

  List<Trip> get pastTrips {
    _refreshDatePartitionsIfNeeded();
    return _pastTrips;
  }

  Future<void> load() {
    return _loadFromStorage();
  }

  Future<void> reloadFromStorage() {
    return _loadFromStorage();
  }

  Future<void> addTrip(Trip trip) {
    _ensureWritable();
    return _persistMutation(() {
      _trips.add(trip);
    });
  }

  Future<void> updateTrip(Trip trip) async {
    _ensureWritable();
    final index = _trips.indexWhere((item) => item.id == trip.id);
    if (index == -1) {
      return;
    }

    await _persistMutation(() {
      _trips[index] = trip;
    });
  }

  Future<void> deleteTrip(String id) async {
    _ensureWritable();
    final index = _trips.indexWhere((trip) => trip.id == id);
    if (index == -1) {
      return;
    }

    await _persistMutation(() {
      _trips.removeAt(index);
    });
  }

  String createId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _loadFromStorage() async {
    _isLoading = true;
    _loadErrorMessage = null;
    notifyListeners();

    try {
      final savedTrips = await _storageService.loadTrips();
      _replaceTrips(savedTrips);
    } on TripStorageException catch (error) {
      _loadErrorMessage = error.message;
    } catch (error) {
      debugPrint('Lokale Reisedaten konnten nicht geladen werden: $error');
      _loadErrorMessage =
          'Die lokalen Reisedaten konnten nicht geladen werden. '
          'Die vorhandenen Dateien wurden nicht überschrieben.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persistMutation(void Function() mutation) async {
    final previousTrips = List<Trip>.from(_trips);
    mutation();
    _rebuildViews();

    try {
      await _save();
    } catch (_) {
      _replaceTrips(previousTrips);
      rethrow;
    }

    notifyListeners();
  }

  Future<void> _save() {
    return _storageService.saveTrips(_sortedTrips);
  }

  void _ensureWritable() {
    if (_isLoading) {
      throw StateError('Die Reisedaten werden noch geladen.');
    }
    if (hasLoadError) {
      throw StateError(
        'Änderungen sind gesperrt, bis die lokalen Reisedaten sicher '
        'geladen oder aus einem Backup wiederhergestellt wurden.',
      );
    }
  }

  void _replaceTrips(Iterable<Trip> trips) {
    _trips
      ..clear()
      ..addAll(trips);
    _rebuildViews();
  }

  void _rebuildViews() {
    _trips.sort((a, b) => a.startDate.compareTo(b.startDate));
    _sortedTrips = List<Trip>.unmodifiable(_trips);
    _rebuildDatePartitions(_dateOnly(_now()));
  }

  void _refreshDatePartitionsIfNeeded() {
    final today = _dateOnly(_now());
    if (_partitionDate == today) {
      return;
    }
    _rebuildDatePartitions(today);
  }

  void _rebuildDatePartitions(DateTime today) {
    final upcoming = <Trip>[];
    final past = <Trip>[];

    for (final trip in _sortedTrips) {
      if (_dateOnly(trip.endDate).isBefore(today)) {
        past.add(trip);
      } else {
        upcoming.add(trip);
      }
    }

    _upcomingTrips = List<Trip>.unmodifiable(upcoming);
    _pastTrips = List<Trip>.unmodifiable(past);
    _partitionDate = today;
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
