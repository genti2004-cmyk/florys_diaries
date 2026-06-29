import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:florys_diaries/features/documents/data/travel_document_path_policy.dart';

import '../domain/trip.dart';

typedef TripDocumentsDirectoryProvider = Future<Directory> Function();

class TripStorageException implements Exception {
  const TripStorageException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class TripStorageService {
  const TripStorageService({this.documentsDirectoryProvider});

  static const String _fileName = 'florys_trips.json';
  static const String _recoverySuffix = '.bak';
  static const String _rollbackSuffix = '.rollback';
  static const String _temporarySuffix = '.tmp';

  final TripDocumentsDirectoryProvider? documentsDirectoryProvider;

  Future<bool> hasSavedTrips() async {
    final file = await _tripsFile();
    return await file.exists() ||
        await File('${file.path}$_recoverySuffix').exists() ||
        await File('${file.path}$_rollbackSuffix').exists();
  }

  Future<List<Trip>> loadTrips() async {
    final primary = await _tripsFile();
    final rollback = File('${primary.path}$_rollbackSuffix');
    final recovery = File('${primary.path}$_recoverySuffix');

    if (await primary.exists()) {
      try {
        final trips = await _readTrips(primary);
        await _refreshRecoveryBestEffort(primary, recovery);
        await _deleteBestEffort(rollback);
        return trips;
      } catch (primaryError) {
        return _recoverOrThrow(
          primary: primary,
          rollback: rollback,
          recovery: recovery,
          primaryError: primaryError,
        );
      }
    }

    final fallbackExists = await rollback.exists() || await recovery.exists();
    if (!fallbackExists) {
      return const [];
    }

    return _recoverOrThrow(
      primary: primary,
      rollback: rollback,
      recovery: recovery,
      primaryError: const FileSystemException(
        'Die primäre lokale Reisedatei fehlt.',
      ),
    );
  }

  Future<void> saveTrips(List<Trip> trips) async {
    final primary = await _tripsFile();
    final directory = primary.parent;
    final temporary = File('${primary.path}$_temporarySuffix');
    final rollback = File('${primary.path}$_rollbackSuffix');
    final recovery = File('${primary.path}$_recoverySuffix');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final encoder = const JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(
      trips.map((trip) => trip.toJson()).toList(growable: false),
    );

    await _deleteIfExists(temporary);
    await temporary.writeAsString(rawJson, flush: true);

    try {
      await _readTrips(temporary);
    } catch (error, stackTrace) {
      await _deleteBestEffort(temporary);
      Error.throwWithStackTrace(error, stackTrace);
    }

    try {
      await _deleteIfExists(rollback);
      if (await primary.exists()) {
        await primary.copy(rollback.path);
      }

      if (await primary.exists()) {
        await primary.delete();
      }
      await temporary.rename(primary.path);
    } catch (error, stackTrace) {
      await _restoreRollbackBestEffort(primary, rollback);
      await _deleteIfExists(temporary);
      Error.throwWithStackTrace(error, stackTrace);
    }

    await _refreshRecoveryBestEffort(primary, recovery);
    await _deleteBestEffort(rollback);
    await _deleteBestEffort(temporary);
  }

  Future<List<Trip>> _recoverOrThrow({
    required File primary,
    required File rollback,
    required File recovery,
    required Object primaryError,
  }) async {
    final candidates = <File>[rollback, recovery];
    Object? lastFallbackError;

    for (final candidate in candidates) {
      if (!await candidate.exists()) {
        continue;
      }

      try {
        final trips = await _readTrips(candidate);
        await _restorePrimary(candidate, primary);
        await _refreshRecoveryBestEffort(primary, recovery);
        await _deleteBestEffort(rollback);
        return trips;
      } catch (error) {
        lastFallbackError = error;
      }
    }

    throw TripStorageException(
      'Die lokalen Reisedaten konnten nicht sicher gelesen werden. '
      'Die vorhandenen Dateien wurden nicht überschrieben. Öffne die '
      'Backups in den Einstellungen oder versuche es erneut.',
      cause: lastFallbackError ?? primaryError,
    );
  }

  Future<List<Trip>> _readTrips(File file) async {
    final rawJson = await file.readAsString();
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      throw const FormatException(
        'Die lokale Reisedatei enthält keine gültige Reiseliste.',
      );
    }

    final trips = <Trip>[];
    final tripIds = <String>{};
    final tripFolderKeys = <String>{};
    final documentPathKeys = <String>{};

    for (final rawTrip in decoded) {
      if (rawTrip is! Map<String, dynamic>) {
        throw const FormatException(
          'Ein Eintrag in der lokalen Reisedatei ist ungültig.',
        );
      }

      final id = rawTrip['id'];
      final startDateValue = rawTrip['startDate'];
      final endDateValue = rawTrip['endDate'];
      final startDate = startDateValue is String
          ? DateTime.tryParse(startDateValue)
          : null;
      final endDate = endDateValue is String
          ? DateTime.tryParse(endDateValue)
          : null;

      if (id is! String || id.trim().isEmpty || !tripIds.add(id)) {
        throw const FormatException(
          'Eine lokale Reise-ID ist ungültig oder doppelt.',
        );
      }

      final folderKey = TravelDocumentPathPolicy.safeTripFolderName(
        id,
      ).toLowerCase();
      if (!tripFolderKeys.add(folderKey)) {
        throw const FormatException(
          'Zwei lokale Reisen würden denselben Dateiordner verwenden.',
        );
      }

      if (startDate == null || endDate == null || endDate.isBefore(startDate)) {
        throw const FormatException('Ein lokaler Reisezeitraum ist ungültig.');
      }

      _validateNestedEntries(
        rawTrip,
        tripId: id,
        documentPathKeys: documentPathKeys,
      );

      final photoCount = rawTrip['photoCount'];
      if (photoCount != null &&
          (photoCount is! num || photoCount.toInt() < 0)) {
        throw const FormatException(
          'Die lokale Fotoanzahl einer Reise ist ungültig.',
        );
      }

      trips.add(Trip.fromJson(rawTrip));
    }

    return List<Trip>.unmodifiable(trips);
  }

  static void _validateNestedEntries(
    Map<String, dynamic> tripJson, {
    required String tripId,
    required Set<String> documentPathKeys,
  }) {
    _validateNestedList(
      tripJson['documents'],
      label: 'Dokument',
      validate: (entry, ids) {
        _requireUniqueId(entry, ids, label: 'Dokument');

        final title = entry['title'];
        if (title is! String || title.trim().isEmpty) {
          throw const FormatException(
            'Ein lokaler Dokumenttitel ist ungültig.',
          );
        }

        _requireValidDate(entry['createdAt'], label: 'Dokumentdatum');

        final sizeValue = entry['fileSizeBytes'];
        if (sizeValue != null && (sizeValue is! num || sizeValue.toInt() < 0)) {
          throw const FormatException(
            'Eine lokale Dokumentgröße ist ungültig.',
          );
        }

        final pathValue = entry['relativePath'];
        if (pathValue != null && pathValue is! String) {
          throw const FormatException('Ein lokaler Dokumentpfad ist ungültig.');
        }

        final path = TravelDocumentPathPolicy.normalize(
          pathValue is String ? pathValue : '',
        );
        if (path.isEmpty) {
          return;
        }

        if (!TravelDocumentPathPolicy.isDocumentPathForTrip(path, tripId)) {
          throw const FormatException(
            'Ein lokaler Dokumentpfad gehört nicht zur angegebenen Reise.',
          );
        }

        if (!documentPathKeys.add(path.toLowerCase())) {
          throw const FormatException(
            'Eine lokale Dokumentdatei wird mehrfach referenziert.',
          );
        }
      },
    );
    _validateNestedList(
      tripJson['albumEntries'],
      label: 'Album-Eintrag',
      validate: (entry, ids) {
        _requireUniqueId(entry, ids, label: 'Album-Eintrag');
        _requireValidDate(entry['date'], label: 'Albumdatum');
      },
    );
    _validateNestedList(
      tripJson['checklistItems'],
      label: 'Checklisten-Eintrag',
      validate: (entry, ids) {
        _requireUniqueId(entry, ids, label: 'Checklisten-Eintrag');
        final title = entry['title'];
        if (title is! String || title.trim().isEmpty) {
          throw const FormatException(
            'Ein lokaler Checklisten-Titel ist ungültig.',
          );
        }
        _requireValidDate(entry['createdAt'], label: 'Checklisten-Datum');
        final dueDate = entry['dueDate'];
        if (dueDate != null) {
          _requireValidDate(dueDate, label: 'Fälligkeitsdatum');
        }
      },
    );
  }

  static void _validateNestedList(
    Object? value, {
    required String label,
    required void Function(Map<String, dynamic> entry, Set<String> ids)
    validate,
  }) {
    if (value == null) {
      return;
    }
    if (value is! List) {
      throw FormatException('Lokale $label-Daten sind ungültig.');
    }

    final ids = <String>{};
    for (final rawEntry in value) {
      if (rawEntry is! Map<String, dynamic>) {
        throw FormatException('Ein lokaler $label-Eintrag ist ungültig.');
      }
      validate(rawEntry, ids);
    }
  }

  static void _requireUniqueId(
    Map<String, dynamic> entry,
    Set<String> ids, {
    required String label,
  }) {
    final id = entry['id'];
    if (id is! String || id.trim().isEmpty || !ids.add(id)) {
      throw FormatException('Eine lokale $label-ID ist ungültig oder doppelt.');
    }
  }

  static void _requireValidDate(Object? value, {required String label}) {
    if (value is! String || DateTime.tryParse(value) == null) {
      throw FormatException('Das lokale $label ist ungültig.');
    }
  }

  Future<void> _restorePrimary(File source, File primary) async {
    final restoreTemporary = File('${primary.path}.restore$_temporarySuffix');
    await _deleteIfExists(restoreTemporary);
    await source.copy(restoreTemporary.path);
    await _readTrips(restoreTemporary);
    if (await primary.exists()) {
      await primary.delete();
    }
    await restoreTemporary.rename(primary.path);
  }

  Future<void> _refreshRecoveryBestEffort(File primary, File recovery) async {
    final recoveryTemporary = File('${recovery.path}$_temporarySuffix');
    try {
      await _deleteIfExists(recoveryTemporary);
      await primary.copy(recoveryTemporary.path);
      await _readTrips(recoveryTemporary);
      if (await recovery.exists()) {
        await recovery.delete();
      }
      await recoveryTemporary.rename(recovery.path);
    } catch (_) {
      await _deleteBestEffort(recoveryTemporary);
    }
  }

  Future<void> _restoreRollbackBestEffort(File primary, File rollback) async {
    try {
      if (!await primary.exists() && await rollback.exists()) {
        await rollback.copy(primary.path);
      }
    } catch (_) {
      // Der ursprüngliche Fehler wird weitergereicht. Die Rollback-Datei
      // bleibt für einen späteren automatischen Wiederherstellungsversuch da.
    }
  }

  static Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> _deleteBestEffort(File file) async {
    try {
      await _deleteIfExists(file);
    } catch (_) {
      // Temporäre Sicherheitsdateien werden beim nächsten Laden erneut geprüft.
    }
  }

  Future<File> _tripsFile() async {
    final provider = documentsDirectoryProvider;
    final directory = provider == null
        ? await getApplicationDocumentsDirectory()
        : await provider();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }
}
