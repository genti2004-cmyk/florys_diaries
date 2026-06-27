import 'dart:io';

import 'package:florys_diaries/features/backup/data/google_drive_auth_service.dart';
import 'package:florys_diaries/features/backup/data/google_drive_rest_client.dart';
import 'package:florys_diaries/features/backup/domain/google_drive_backup_models.dart';

class GoogleDriveAppDataService {
  GoogleDriveAppDataService({
    GoogleDriveAuthService? authService,
    GoogleDriveRestClient? restClient,
  })  : authService = authService ?? GoogleDriveAuthService.instance,
        restClient = restClient ?? GoogleDriveRestClient();

  final GoogleDriveAuthService authService;
  final GoogleDriveRestClient restClient;

  Future<GoogleDriveUploadResult?> uploadBackup(File sourceFile) async {
    final session = await authService.connect();
    if (session == null) {
      return null;
    }

    final stored = await restClient.upload(session, sourceFile);
    return GoogleDriveUploadResult(
      backup: stored,
      accountEmail: session.email,
    );
  }

  Future<GoogleDriveBackupHistoryResult?> loadBackupHistory() async {
    final session = await authService.connect();
    if (session == null) {
      return null;
    }

    final backups = await restClient.listBackups(session);
    return GoogleDriveBackupHistoryResult(
      backups: List.unmodifiable(backups),
      accountEmail: session.email,
    );
  }

  Future<GoogleDriveDownloadResult?> downloadLatestBackup() async {
    final session = await authService.connect();
    if (session == null) {
      return null;
    }

    final backups = await restClient.listBackups(session);
    if (backups.isEmpty) {
      throw const FileSystemException(
        'In Google Drive wurde noch kein FlorysDiaries-Backup gefunden.',
      );
    }

    final latest = backups.first;
    final file = await restClient.download(session, latest);
    return GoogleDriveDownloadResult(
      file: file,
      backup: latest,
      accountEmail: session.email,
    );
  }

  Future<GoogleDriveDownloadResult?> downloadBackup(
    GoogleDriveStoredBackup backup,
  ) async {
    final session = await authService.connect();
    if (session == null) {
      return null;
    }

    final file = await restClient.download(session, backup);
    return GoogleDriveDownloadResult(
      file: file,
      backup: backup,
      accountEmail: session.email,
    );
  }

  Future<bool> deleteBackup(GoogleDriveStoredBackup backup) async {
    final session = await authService.connect();
    if (session == null) {
      return false;
    }

    await restClient.deleteBackup(session, backup);
    return true;
  }
}
