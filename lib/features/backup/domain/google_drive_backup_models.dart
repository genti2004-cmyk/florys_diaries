import 'dart:io';

class GoogleDriveStoredBackup {
  const GoogleDriveStoredBackup({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
    required this.isAutomatic,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;
  final bool isAutomatic;

  factory GoogleDriveStoredBackup.fromJson(Map<String, dynamic> json) {
    final backup = tryFromJson(json);
    if (backup == null) {
      throw const FileSystemException(
        'Google Drive hat unvollständige Dateiinformationen zurückgegeben.',
      );
    }
    return backup;
  }

  static GoogleDriveStoredBackup? tryFromJson(
    Map<String, dynamic> json,
  ) {
    final id = json['id']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    if (id.isEmpty || name.isEmpty) {
      return null;
    }

    final createdAt =
        DateTime.tryParse(json['createdTime']?.toString() ?? '') ??
        DateTime.tryParse(json['modifiedTime']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    final rawProperties = json['appProperties'];
    final properties = rawProperties is Map
        ? rawProperties.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          )
        : const <String, String>{};

    return GoogleDriveStoredBackup(
      id: id,
      name: name,
      createdAt: createdAt,
      sizeBytes: int.tryParse(json['size']?.toString() ?? '') ?? 0,
      isAutomatic: properties['backupKind'] == 'automatic' ||
          name.contains('_Cloud_Auto_'),
    );
  }
}

class GoogleDriveUploadResult {
  const GoogleDriveUploadResult({
    required this.backup,
    required this.accountEmail,
  });

  final GoogleDriveStoredBackup backup;
  final String accountEmail;
}

class GoogleDriveBackupHistoryResult {
  const GoogleDriveBackupHistoryResult({
    required this.backups,
    required this.accountEmail,
  });

  final List<GoogleDriveStoredBackup> backups;
  final String accountEmail;
}

class GoogleDriveDownloadResult {
  const GoogleDriveDownloadResult({
    required this.file,
    required this.backup,
    required this.accountEmail,
  });

  final File file;
  final GoogleDriveStoredBackup backup;
  final String accountEmail;
}
