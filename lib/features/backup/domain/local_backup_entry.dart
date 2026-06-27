import 'dart:io';

class LocalBackupEntry {
  const LocalBackupEntry({
    required this.file,
    required this.createdAt,
    required this.sizeBytes,
    required this.isAutomatic,
  });

  final File file;
  final DateTime createdAt;
  final int sizeBytes;
  final bool isAutomatic;

  String get fileName {
    final normalized = file.path.replaceAll('\\', '/');
    final parts = normalized
        .split('/')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? 'FlorysDiaries_Backup.zip' : parts.last;
  }
}
