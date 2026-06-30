import 'dart:convert';
import 'dart:io';

import 'package:florys_diaries/features/backup/data/backup_file_manager.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class BackupContentFingerprintService {
  const BackupContentFingerprintService({
    this.fileManager = const BackupFileManager(),
  });

  final BackupFileManager fileManager;

  static final BigInt _offsetBasis = BigInt.parse(
    'cbf29ce484222325',
    radix: 16,
  );
  static final BigInt _prime = BigInt.parse('100000001b3', radix: 16);
  static final BigInt _unsigned64Modulus = BigInt.one << 64;
  static final BigInt _mask = _unsigned64Modulus - BigInt.one;

  static final RegExp _canonicalPattern = RegExp(r'^[0-9a-f]{16,64}$');
  static final RegExp _legacySigned64Pattern = RegExp(r'^-[0-9a-f]{1,16}$');

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

  static String normalize(String value) {
    final normalized = value.trim().toLowerCase();

    if (_canonicalPattern.hasMatch(normalized)) {
      return normalized;
    }

    if (_legacySigned64Pattern.hasMatch(normalized)) {
      final signed = BigInt.parse(normalized, radix: 16);
      final unsigned = signed + _unsigned64Modulus;

      if (unsigned >= BigInt.zero && unsigned <= _mask) {
        return unsigned.toRadixString(16).padLeft(16, '0');
      }
    }

    throw const FormatException('Der Backup-Fingerabdruck ist ungültig.');
  }

  static String? tryNormalize(String value) {
    try {
      return normalize(value);
    } on FormatException {
      return null;
    }
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

  static BigInt _addString(BigInt hash, String value) {
    final bytes = utf8.encode(value);
    var current = _addBytes(hash, utf8.encode('${bytes.length}:'));
    current = _addBytes(current, bytes);
    return _addBytes(current, const [10]);
  }

  static BigInt _addBytes(BigInt hash, List<int> bytes) {
    var current = hash;
    for (final byte in bytes) {
      current = (current ^ BigInt.from(byte)) * _prime & _mask;
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
