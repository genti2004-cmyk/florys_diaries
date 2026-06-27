import 'dart:convert';
import 'dart:io';

import 'package:florys_diaries/features/backup/data/backup_file_manager.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class BackupContentFingerprintService {
  const BackupContentFingerprintService({
    this.fileManager = const BackupFileManager(),
  });

  final BackupFileManager fileManager;

  static const int _offsetBasis = 0xcbf29ce484222325;
  static const int _prime = 0x100000001b3;
  static const int _mask = 0xffffffffffffffff;

  Future<String> calculate(List<Trip> trips) async {
    var hash = _offsetBasis;
    hash = _addString(hash, 'florys-diaries-backup-content-v1');
    hash = _addString(
      hash,
      jsonEncode(
        _normalizeJson(
          trips.map((trip) => trip.toJson()).toList(growable: false),
        ),
      ),
    );

    final root = await fileManager.fileService.rootDirectory();
    if (await root.exists()) {
      final files = <File>[];
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          files.add(entity);
        }
      }

      files.sort(
        (left, right) => _relativePath(
          root,
          left.path,
        ).compareTo(_relativePath(root, right.path)),
      );

      for (final file in files) {
        final stat = await file.stat();
        hash = _addString(hash, _relativePath(root, file.path));
        hash = _addString(hash, stat.size.toString());
        hash = _addString(
          hash,
          stat.modified.toUtc().microsecondsSinceEpoch.toString(),
        );
      }
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }

  static Object? _normalizeJson(Object? value) {
    if (value is Map) {
      final entries =
          value.entries
              .map(
                (entry) =>
                    MapEntry(entry.key.toString(), _normalizeJson(entry.value)),
              )
              .toList()
            ..sort((left, right) => left.key.compareTo(right.key));
      return <String, Object?>{
        for (final entry in entries) entry.key: entry.value,
      };
    }

    if (value is Iterable) {
      return value.map(_normalizeJson).toList(growable: false);
    }

    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    return value;
  }

  static int _addString(int hash, String value) {
    final bytes = utf8.encode(value);
    var current = _addBytes(hash, utf8.encode('${bytes.length}:'));
    current = _addBytes(current, bytes);
    return _addBytes(current, const [10]);
  }

  static int _addBytes(int hash, List<int> bytes) {
    var current = hash;
    for (final byte in bytes) {
      current ^= byte;
      current = (current * _prime) & _mask;
    }
    return current;
  }

  static String _relativePath(Directory root, String filePath) {
    final separator = Platform.pathSeparator;
    final rootPrefix = root.path.endsWith(separator)
        ? root.path
        : '${root.path}$separator';
    final relative = filePath.startsWith(rootPrefix)
        ? filePath.substring(rootPrefix.length)
        : filePath;
    return relative.replaceAll('\\', '/');
  }
}
