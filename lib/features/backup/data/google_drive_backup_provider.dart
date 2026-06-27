import 'dart:io';

import 'package:florys_diaries/features/backup/data/google_drive_app_data_service.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';

class GoogleDriveBackupProvider implements BackupProvider {
  const GoogleDriveBackupProvider();

  static final GoogleDriveAppDataService _service = GoogleDriveAppDataService();

  @override
  BackupProviderId get id => BackupProviderId.googleDrive;

  @override
  String get displayName => 'Google Drive';

  @override
  String get description =>
      'Privater App-Datenordner mit getrennten Sicherungsständen.';

  @override
  bool get isAvailable => true;

  @override
  Future<BackupProviderSaveResult?> saveBackup(File sourceFile) async {
    final result = await _service.uploadBackup(sourceFile);
    if (result == null) {
      return null;
    }

    return BackupProviderSaveResult(
      displayName: result.backup.name,
      location: 'Google Drive · ${result.accountEmail}',
    );
  }

  @override
  Future<BackupProviderSelection?> pickBackup() async {
    final result = await _service.downloadLatestBackup();
    if (result == null) {
      return null;
    }

    return BackupProviderSelection(
      file: result.file,
      displayName: '${result.backup.name} · ${result.accountEmail}',
      deleteAfterUse: true,
    );
  }
}
