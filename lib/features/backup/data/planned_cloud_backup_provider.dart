import 'dart:io';

import 'package:florys_diaries/features/backup/domain/backup_provider.dart';

class PlannedCloudBackupProvider implements BackupProvider {
  const PlannedCloudBackupProvider({
    required this.id,
    required this.displayName,
    required this.description,
  });

  @override
  final BackupProviderId id;

  @override
  final String displayName;

  @override
  final String description;

  @override
  bool get isAvailable => false;

  @override
  Future<BackupProviderSelection?> pickBackup() {
    throw UnsupportedError('$displayName ist noch nicht verbunden.');
  }

  @override
  Future<BackupProviderSaveResult?> saveBackup(File sourceFile) {
    throw UnsupportedError('$displayName ist noch nicht verbunden.');
  }
}
