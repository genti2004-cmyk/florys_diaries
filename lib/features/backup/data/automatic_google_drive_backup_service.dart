import 'dart:io';

import 'package:florys_diaries/features/backup/data/app_backup_service.dart';
import 'package:florys_diaries/features/backup/data/automatic_cloud_backup_settings_service.dart';
import 'package:florys_diaries/features/backup/data/backup_content_fingerprint_service.dart';
import 'package:florys_diaries/features/backup/data/google_drive_auth_service.dart';
import 'package:florys_diaries/features/backup/data/google_drive_rest_client.dart';
import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';
import 'package:florys_diaries/features/backup/domain/google_drive_backup_models.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class AutomaticGoogleDriveBackupService {
  AutomaticGoogleDriveBackupService({
    AppBackupService? backupService,
    AutomaticCloudBackupSettingsService? settingsService,
    BackupContentFingerprintService? fingerprintService,
    GoogleDriveAuthService? authService,
    GoogleDriveRestClient? restClient,
  })  : backupService = backupService ?? const AppBackupService(),
        settingsService =
            settingsService ?? const AutomaticCloudBackupSettingsService(),
        fingerprintService =
            fingerprintService ?? const BackupContentFingerprintService(),
        authService = authService ?? GoogleDriveAuthService.instance,
        restClient = restClient ?? GoogleDriveRestClient();

  final AppBackupService backupService;
  final AutomaticCloudBackupSettingsService settingsService;
  final BackupContentFingerprintService fingerprintService;
  final GoogleDriveAuthService authService;
  final GoogleDriveRestClient restClient;

  Future<AutomaticGoogleDriveBackupResult> runIfDue(
    List<Trip> trips,
  ) async {
    final settings = await settingsService.load();
    if (!settings.enabled) {
      return AutomaticGoogleDriveBackupResult.disabled(settings);
    }
    if (!settings.isDueAt(DateTime.now())) {
      return AutomaticGoogleDriveBackupResult.notDue(settings);
    }

    return _run(
      trips,
      settings: settings,
      interactiveAuthentication: false,
    );
  }

  Future<AutomaticGoogleDriveBackupResult> runNow(
    List<Trip> trips,
  ) async {
    final settings = await settingsService.load();
    return _run(
      trips,
      settings: settings,
      interactiveAuthentication: true,
    );
  }

  Future<AutomaticGoogleDriveBackupResult> _run(
    List<Trip> trips, {
    required AutomaticCloudBackupSettings settings,
    required bool interactiveAuthentication,
  }) async {
    final checkedAt = DateTime.now();
    final contentFingerprint = await fingerprintService.calculate(trips);
    if (settings.lastContentFingerprint == contentFingerprint) {
      final updatedSettings = settings.copyWith(lastCheckedAt: checkedAt);
      await settingsService.save(updatedSettings);
      return AutomaticGoogleDriveBackupResult.noChanges(updatedSettings);
    }

    final session = interactiveAuthentication
        ? await authService.connect()
        : await authService.connectSilently();
    if (session == null) {
      return AutomaticGoogleDriveBackupResult.signInRequired(settings);
    }

    final created = await backupService.createBackup(
      trips,
      fileNamePrefix: 'FlorysDiaries_Cloud_Auto',
    );

    try {
      final uploaded = await restClient.upload(
        session,
        created.file,
        automatic: true,
      );

      final completedAt = DateTime.now();
      final updatedSettings = settings.copyWith(
        lastSuccessfulBackupAt: completedAt,
        lastCheckedAt: completedAt,
        lastContentFingerprint: contentFingerprint,
      );
      await settingsService.save(updatedSettings);

      final deletedCount = await _pruneAutomaticBackups(
        session,
        retentionLimit: settings.retentionLimit,
      );

      return AutomaticGoogleDriveBackupResult.uploaded(
        settings: updatedSettings,
        backup: uploaded,
        accountEmail: session.email,
        deletedCount: deletedCount,
      );
    } finally {
      if (await created.file.exists()) {
        try {
          await created.file.delete();
        } on FileSystemException {
          // Das temporäre Arbeitsbackup wird später vom System bereinigt.
        }
      }
    }
  }

  Future<int> _pruneAutomaticBackups(
    GoogleDriveSession session, {
    required int retentionLimit,
  }) async {
    late final List<GoogleDriveStoredBackup> backups;
    try {
      backups = await restClient.listBackups(session);
    } on FileSystemException {
      return 0;
    }

    final automaticBackups = backups
        .where((backup) => backup.isAutomatic)
        .toList(growable: false);
    if (automaticBackups.length <= retentionLimit) {
      return 0;
    }

    var deletedCount = 0;
    for (final backup in automaticBackups.skip(retentionLimit)) {
      try {
        await restClient.deleteBackup(session, backup);
        deletedCount++;
      } on FileSystemException {
        // Ein späterer Lauf versucht die verbleibenden alten Backups erneut.
        break;
      }
    }
    return deletedCount;
  }
}

enum AutomaticGoogleDriveBackupStatus {
  disabled,
  notDue,
  signInRequired,
  noChanges,
  uploaded,
}

class AutomaticGoogleDriveBackupResult {
  const AutomaticGoogleDriveBackupResult._({
    required this.status,
    required this.settings,
    this.backup,
    this.accountEmail,
    this.deletedCount = 0,
  });

  factory AutomaticGoogleDriveBackupResult.disabled(
    AutomaticCloudBackupSettings settings,
  ) {
    return AutomaticGoogleDriveBackupResult._(
      status: AutomaticGoogleDriveBackupStatus.disabled,
      settings: settings,
    );
  }

  factory AutomaticGoogleDriveBackupResult.notDue(
    AutomaticCloudBackupSettings settings,
  ) {
    return AutomaticGoogleDriveBackupResult._(
      status: AutomaticGoogleDriveBackupStatus.notDue,
      settings: settings,
    );
  }

  factory AutomaticGoogleDriveBackupResult.signInRequired(
    AutomaticCloudBackupSettings settings,
  ) {
    return AutomaticGoogleDriveBackupResult._(
      status: AutomaticGoogleDriveBackupStatus.signInRequired,
      settings: settings,
    );
  }

  factory AutomaticGoogleDriveBackupResult.noChanges(
    AutomaticCloudBackupSettings settings,
  ) {
    return AutomaticGoogleDriveBackupResult._(
      status: AutomaticGoogleDriveBackupStatus.noChanges,
      settings: settings,
    );
  }

  factory AutomaticGoogleDriveBackupResult.uploaded({
    required AutomaticCloudBackupSettings settings,
    required GoogleDriveStoredBackup backup,
    required String accountEmail,
    required int deletedCount,
  }) {
    return AutomaticGoogleDriveBackupResult._(
      status: AutomaticGoogleDriveBackupStatus.uploaded,
      settings: settings,
      backup: backup,
      accountEmail: accountEmail,
      deletedCount: deletedCount,
    );
  }

  final AutomaticGoogleDriveBackupStatus status;
  final AutomaticCloudBackupSettings settings;
  final GoogleDriveStoredBackup? backup;
  final String? accountEmail;
  final int deletedCount;
}
