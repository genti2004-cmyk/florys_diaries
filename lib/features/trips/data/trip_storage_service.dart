import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/trip.dart';

class TripStorageService {
  const TripStorageService();

  static const String _fileName = 'florys_trips.json';

  Future<bool> hasSavedTrips() async {
    final file = await _tripsFile();
    return file.exists();
  }

  Future<List<Trip>> loadTrips() async {
    final file = await _tripsFile();
    if (!await file.exists()) {
      return const [];
    }

    try {
      final rawJson = await file.readAsString();
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Trip.fromJson)
          .where((trip) => trip.id.trim().isNotEmpty)
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on FileSystemException {
      return const [];
    }
  }

  Future<void> saveTrips(List<Trip> trips) async {
    final file = await _tripsFile();
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final encoder = const JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(
      trips.map((trip) => trip.toJson()).toList(),
    );
    await file.writeAsString(rawJson, flush: true);
  }

  Future<File> _tripsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }
}
