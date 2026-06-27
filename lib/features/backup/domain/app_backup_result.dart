import 'dart:io';

class AppBackupCreateResult {
  const AppBackupCreateResult({
    required this.file,
    required this.createdAt,
    required this.tripCount,
    required this.fileCount,
    required this.sizeBytes,
  });

  final File file;
  final DateTime createdAt;
  final int tripCount;
  final int fileCount;
  final int sizeBytes;
}

class AppBackupInspectionResult {
  const AppBackupInspectionResult({
    required this.backupCreatedAt,
    required this.tripCount,
    required this.fileCount,
    required this.sizeBytes,
  });

  final DateTime backupCreatedAt;
  final int tripCount;
  final int fileCount;
  final int sizeBytes;
}

class AppBackupRestoreResult {
  const AppBackupRestoreResult({
    required this.backupCreatedAt,
    required this.tripCount,
    required this.fileCount,
  });

  final DateTime backupCreatedAt;
  final int tripCount;
  final int fileCount;
}
