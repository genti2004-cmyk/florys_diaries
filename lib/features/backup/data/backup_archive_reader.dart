import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';

import 'package:florys_diaries/features/trips/domain/trip.dart';

class BackupArchivePackage {
  const BackupArchivePackage({
    required this.createdAt,
    required this.trips,
    required this.fileEntries,
  });

  final DateTime createdAt;
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

    final archive = ZipDecoder().decodeBytes(await backupFile.readAsBytes());
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

      if (!seenFilePaths.add(name)) {
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
    _validateDocumentPaths(trips);

    return BackupArchivePackage(
      createdAt: createdAt,
      trips: trips,
      fileEntries: fileEntries,
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

  static List<Trip> _decodeTrips(ArchiveFile entry) {
    final decoded = jsonDecode(utf8.decode(_entryBytes(entry)));
    if (decoded is! List) {
      throw const FormatException('Die Reisedaten im Backup sind ungültig.');
    }

    final trips = <Trip>[];
    final ids = <String>{};

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
      if (startDate is! String || DateTime.tryParse(startDate) == null) {
        throw const FormatException('Ein Startdatum im Backup ist ungültig.');
      }
      if (endDate is! String || DateTime.tryParse(endDate) == null) {
        throw const FormatException('Ein Enddatum im Backup ist ungültig.');
      }

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

  static void _validateDocumentPaths(List<Trip> trips) {
    for (final trip in trips) {
      for (final document in trip.documents) {
        final path = _normalizePath(document.relativePath.trim());
        if (path.isEmpty) {
          continue;
        }
        if (!_isSafePath(path) || !path.startsWith('Reisen/')) {
          throw const FormatException(
            'Ein Dokumentpfad im Backup ist ungültig.',
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
