import 'package:florys_diaries/core/constants/app_metadata.dart';
import 'package:florys_diaries/features/backup/data/backup_archive_reader.dart';

class BackupManifest {
  const BackupManifest._();

  static Map<String, Object> create({
    required DateTime createdAt,
    required int tripCount,
    required int fileCount,
    required int contentBytes,
    required String tripsSha256,
    required Map<String, String> fileSha256ByPath,
    String appVersion = AppMetadata.version,
  }) {
    final orderedFileHashes = <String, String>{
      for (final key in (fileSha256ByPath.keys.toList()..sort()))
        key: fileSha256ByPath[key]!,
    };

    return {
      'format': BackupArchiveReader.formatId,
      'schemaVersion': BackupArchiveReader.schemaVersion,
      'appVersion': appVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'tripCount': tripCount,
      'fileCount': fileCount,
      'contentBytes': contentBytes,
      'integrity': {
        'algorithm': 'sha256',
        'trips': tripsSha256,
        'files': orderedFileHashes,
      },
    };
  }
}
