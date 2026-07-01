import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';

import 'package:florys_diaries/features/documents/data/travel_document_path_policy.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class BackupArchivePackage {
  const BackupArchivePackage({
    required this.createdAt,
    required this.appVersion,
    required this.trips,
    required this.fileEntries,
  });

  final DateTime createdAt;
  final String appVersion;
  final List<Trip> trips;
  final List<ArchiveFile> fileEntries;
}

class BackupArchiveReader {
  const BackupArchiveReader();

  static const String formatId = 'florys_diaries_backup';
  static const int schemaVersion = 1;
  static const int _maxArchiveEntries = 10000;
  static const int _maxUncompressedBytes = 2 * 1024 * 1024 * 1024;

  Future<BackupArchivePackage> read(File backupFile) async {
    if (!await backupFile.exists()) {
      throw const FormatException(
        'Die ausgewählte Backup-Datei wurde nicht gefunden.',
      );
    }

    final archive = await _decodeArchive(backupFile);
    if (archive.files.length > _maxArchiveEntries) {
      throw const FormatException(
        'Das Backup enthält ungewöhnlich viele Dateien.',
      );
    }

    ArchiveFile? manifestEntry;
    ArchiveFile? tripsEntry;
    final fileEntries = <ArchiveFile>[];
    final seenFilePaths = <String>{};
    var totalBytes = 0;

    for (final entry in archive.files) {
      final name = _validatedEntryName(entry);
      if (!entry.isFile) {
        continue;
      }

      final normalizedKey = name.toLowerCase();
      if (!seenFilePaths.add(normalizedKey)) {
        throw FormatException('Doppelter Inhalt im Backup: $name');
      }

      totalBytes += entry.size;
      if (totalBytes > _maxUncompressedBytes) {
        throw const FormatException('Das Backup ist für dieses Gerät zu groß.');
      }

      if (name == 'manifest.json') {
        manifestEntry = entry;
      } else if (name == 'trips.json') {
        tripsEntry = entry;
      } else if (name.startsWith('files/')) {
        fileEntries.add(entry);
      } else {
        throw FormatException('Unbekannter Inhalt im Backup: $name');
      }
    }

    if (manifestEntry == null || tripsEntry == null) {
      throw const FormatException('Das Backup ist unvollständig.');
    }

    final manifest = _decodeJsonMap(manifestEntry, 'manifest.json');
    if (manifest['format'] != formatId) {
      throw const FormatException('Die Datei ist kein FlorysDiaries-Backup.');
    }
    if ((manifest['schemaVersion'] as num?)?.toInt() != schemaVersion) {
      throw const FormatException(
        'Diese Backup-Version wird noch nicht unterstützt.',
      );
    }

    final createdAtValue = manifest['createdAt'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;
    if (createdAt == null) {
      throw const FormatException(
        'Das Erstellungsdatum des Backups ist ungültig.',
      );
    }

    final trips = _decodeTrips(tripsEntry);
    _validateManifestCounts(manifest, trips: trips, fileEntries: fileEntries);
    _validateDocumentPaths(trips, fileEntries: fileEntries);

    final appVersion = manifest['appVersion']?.toString().trim();

    return BackupArchivePackage(
      createdAt: createdAt,
      appVersion: appVersion == null || appVersion.isEmpty
          ? 'Unbekannt'
          : appVersion,
      trips: List<Trip>.unmodifiable(trips),
      fileEntries: List<ArchiveFile>.unmodifiable(fileEntries),
    );
  }

  Future<int> extractFiles(
    BackupArchivePackage package,
    Directory targetRoot,
  ) async {
    var count = 0;

    for (final entry in package.fileEntries) {
      final name = _normalizePath(entry.name);
      final relativePath = name.substring('files/'.length);
      if (!_isSafePath(relativePath)) {
        throw const FormatException('Ein Dateipfad im Backup ist ungültig.');
      }

      final target = File(
        _joinMany([targetRoot.path, ...relativePath.split('/')]),
      );
      await target.parent.create(recursive: true);
      await target.writeAsBytes(_entryBytes(entry), flush: true);
      count++;
    }

    return count;
  }

  static Future<Archive> _decodeArchive(File backupFile) async {
    try {
      final length = await backupFile.length();
      if (length <= 0) {
        throw const FormatException('Die Backup-Datei ist leer.');
      }

      final bytes = await backupFile.readAsBytes();
      return ZipDecoder().decodeBytes(bytes);
    } on FileSystemException {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'Die Backup-Datei ist beschädigt oder kein gültiges ZIP-Archiv.',
      );
    }
  }

  static List<Trip> _decodeTrips(ArchiveFile entry) {
    final decoded = jsonDecode(utf8.decode(_entryBytes(entry)));
    if (decoded is! List) {
      throw const FormatException('Die Reisedaten im Backup sind ungültig.');
    }

    final trips = <Trip>[];
    final ids = <String>{};
    final tripFolderKeys = <String>{};

    for (final value in decoded) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Ein Reiseeintrag im Backup ist ungültig.');
      }

      final id = value['id'];
      final startDate = value['startDate'];
      final endDate = value['endDate'];
      if (id is! String || id.trim().isEmpty || !ids.add(id)) {
        throw const FormatException(
          'Eine Reise-ID im Backup ist ungültig oder doppelt.',
        );
      }

      final folderKey = TravelDocumentPathPolicy.safeTripFolderName(
        id,
      ).toLowerCase();
      if (!tripFolderKeys.add(folderKey)) {
        throw const FormatException(
          'Zwei Reisen im Backup würden denselben Dateiordner verwenden.',
        );
      }

      if (startDate is! String || DateTime.tryParse(startDate) == null) {
        throw const FormatException('Ein Startdatum im Backup ist ungültig.');
      }
      if (endDate is! String || DateTime.tryParse(endDate) == null) {
        throw const FormatException('Ein Enddatum im Backup ist ungültig.');
      }

      final parsedStartDate = DateTime.parse(startDate);
      final parsedEndDate = DateTime.parse(endDate);
      _validateNestedEntries(
        value,
        startDate: parsedStartDate,
        endDate: parsedEndDate,
      );

      final trip = Trip.fromJson(value);
      if (trip.endDate.isBefore(trip.startDate)) {
        throw const FormatException(
          'Eine Reise im Backup hat einen ungültigen Zeitraum.',
        );
      }
      trips.add(trip);
    }

    return trips;
  }

  static void _validateNestedEntries(
    Map<String, dynamic> tripJson, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    _validateNestedList(
      tripJson['documents'],
      label: 'Dokument',
      validate: (entry, ids) {
        _requireUniqueId(entry, ids, label: 'Dokument');

        final title = entry['title'];
        if (title is! String || title.trim().isEmpty) {
          throw const FormatException(
            'Ein Dokumenttitel im Backup ist ungültig.',
          );
        }

        _requireValidDate(entry['createdAt'], label: 'Dokumentdatum');

        final sizeValue = entry['fileSizeBytes'];
        if (sizeValue != null && (sizeValue is! num || sizeValue.toInt() < 0)) {
          throw const FormatException(
            'Eine Dokumentgröße im Backup ist ungültig.',
          );
        }

        final pathValue = entry['relativePath'];
        if (pathValue != null && pathValue is! String) {
          throw const FormatException(
            'Ein Dokumentpfad im Backup ist ungültig.',
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
            'Ein Checklisten-Titel im Backup ist ungültig.',
          );
        }
        _requireValidDate(entry['createdAt'], label: 'Checklisten-Datum');

        final dueDate = entry['dueDate'];
        if (dueDate != null) {
          _requireValidDate(dueDate, label: 'Fälligkeitsdatum');
        }
      },
    );
    _validateNestedList(
      tripJson['planItems'],
      label: 'Tagesplan-Eintrag',
      validate: (entry, ids) {
        _requireUniqueId(entry, ids, label: 'Tagesplan-Eintrag');
        final title = entry['title'];
        if (title is! String || title.trim().isEmpty) {
          throw const FormatException(
            'Ein Tagesplan-Titel im Backup ist ungültig.',
          );
        }
        final dateValue = entry['date'];
        _requireValidDate(dateValue, label: 'Tagesplan-Datum');
        final date = DateTime.parse(dateValue as String);
        final dateOnly = DateTime(date.year, date.month, date.day);
        final startOnly = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
        if (dateOnly.isBefore(startOnly) || dateOnly.isAfter(endOnly)) {
          throw const FormatException(
            'Ein Tagesplan-Eintrag im Backup liegt außerhalb der Reise.',
          );
        }
        _requireValidMinutes(
          entry['startMinutes'],
          label: 'Startzeit des Tagesplans',
        );
        final endMinutes = entry['endMinutes'];
        if (endMinutes != null) {
          _requireValidMinutes(
            endMinutes,
            label: 'Endzeit des Tagesplans',
          );
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
      throw FormatException('$label-Daten im Backup sind ungültig.');
    }

    final ids = <String>{};
    for (final rawEntry in value) {
      if (rawEntry is! Map<String, dynamic>) {
        throw FormatException('Ein $label im Backup ist ungültig.');
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
      throw FormatException(
        'Eine $label-ID im Backup ist ungültig oder doppelt.',
      );
    }
  }

  static void _requireValidDate(Object? value, {required String label}) {
    if (value is! String || DateTime.tryParse(value) == null) {
      throw FormatException('$label im Backup ist ungültig.');
    }
  }

  static void _requireValidMinutes(Object? value, {required String label}) {
    if (value is! num || value.toInt() < 0 || value.toInt() > 1439) {
      throw FormatException('$label im Backup ist ungültig.');
    }
  }

  static void _validateManifestCounts(
    Map<String, dynamic> manifest, {
    required List<Trip> trips,
    required List<ArchiveFile> fileEntries,
  }) {
    final declaredTripCount = (manifest['tripCount'] as num?)?.toInt();
    if (declaredTripCount == null || declaredTripCount != trips.length) {
      throw const FormatException(
        'Die Reiseanzahl im Backup ist widersprüchlich.',
      );
    }

    final declaredFileCount = (manifest['fileCount'] as num?)?.toInt();
    if (declaredFileCount == null || declaredFileCount != fileEntries.length) {
      throw const FormatException(
        'Die Dateianzahl im Backup ist widersprüchlich.',
      );
    }

    final actualContentBytes = fileEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.size,
    );
    final declaredContentBytes = (manifest['contentBytes'] as num?)?.toInt();
    if (declaredContentBytes == null ||
        declaredContentBytes != actualContentBytes) {
      throw const FormatException(
        'Die Dateigröße im Backup ist widersprüchlich.',
      );
    }
  }

  static void _validateDocumentPaths(
    List<Trip> trips, {
    required List<ArchiveFile> fileEntries,
  }) {
    final archivedEntries = <String, ArchiveFile>{
      for (final entry in fileEntries)
        _normalizePath(entry.name).substring('files/'.length): entry,
    };
    final referencedPathKeys = <String>{};

    for (final trip in trips) {
      for (final document in trip.documents) {
        final path = TravelDocumentPathPolicy.normalize(document.relativePath);
        if (path.isEmpty) {
          continue;
        }

        if (!TravelDocumentPathPolicy.isDocumentPathForTrip(path, trip.id)) {
          throw const FormatException(
            'Ein Dokumentpfad im Backup gehört nicht zur angegebenen Reise.',
          );
        }

        if (!referencedPathKeys.add(path.toLowerCase())) {
          throw const FormatException(
            'Eine Dokumentdatei im Backup wird mehrfach referenziert.',
          );
        }

        final archivedEntry = archivedEntries[path];
        if (archivedEntry == null) {
          throw const FormatException(
            'Eine im Backup referenzierte Dokumentdatei fehlt.',
          );
        }

        if (document.fileSizeBytes > 0 &&
            document.fileSizeBytes != archivedEntry.size) {
          throw const FormatException(
            'Die Dateigröße eines Dokuments im Backup ist widersprüchlich.',
          );
        }
      }
    }
  }

  static String _validatedEntryName(ArchiveFile entry) {
    var name = _normalizePath(entry.name);
    if (!entry.isFile) {
      name = name.replaceAll(RegExp(r'/+$'), '');
    }
    if (!_isSafePath(name)) {
      throw const FormatException(
        'Das Backup enthält einen unsicheren Dateipfad.',
      );
    }
    if (!entry.isFile && name != 'files' && !name.startsWith('files/')) {
      throw FormatException('Unbekannter Ordner im Backup: $name');
    }
    return name;
  }

  static Map<String, dynamic> _decodeJsonMap(
    ArchiveFile entry,
    String fileName,
  ) {
    final decoded = jsonDecode(utf8.decode(_entryBytes(entry)));
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('$fileName ist ungültig.');
    }
    return decoded;
  }

  static Uint8List _entryBytes(ArchiveFile entry) {
    final content = entry.content;
    if (content is Uint8List) {
      return content;
    }
    if (content is List<int>) {
      return Uint8List.fromList(content);
    }
    throw const FormatException(
      'Eine Datei im Backup konnte nicht gelesen werden.',
    );
  }

  static bool _isSafePath(String path) {
    if (path.isEmpty ||
        path.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:').hasMatch(path)) {
      return false;
    }
    return !path
        .split('/')
        .any((segment) => segment == '..' || segment.isEmpty);
  }

  static String _normalizePath(String path) {
    return path.replaceAll('\\', '/').replaceAll(RegExp(r'^\./+'), '');
  }

  static String _joinMany(List<String> parts) {
    return parts
        .where((part) => part.trim().isNotEmpty)
        .join(Platform.pathSeparator);
  }
}
