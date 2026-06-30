import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:florys_diaries/features/backup/data/backup_content_fingerprint_service.dart';
import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';

typedef AutomaticCloudSettingsDirectoryProvider = Future<Directory> Function();

class AutomaticCloudBackupSettingsException implements Exception {
  const AutomaticCloudBackupSettingsException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class AutomaticCloudBackupSettingsService {
  const AutomaticCloudBackupSettingsService({this.supportDirectoryProvider});

  static const String _fileName = 'florys_diaries_automatic_cloud_backup.json';
  static const String _temporarySuffix = '.tmp';
  static const String _rollbackSuffix = '.rollback';
  static const String _recoverySuffix = '.bak';

  final AutomaticCloudSettingsDirectoryProvider? supportDirectoryProvider;

  Future<AutomaticCloudBackupSettings> load() async {
    final primary = await _settingsFile();
    final rollback = File('${primary.path}$_rollbackSuffix');
    final recovery = File('${primary.path}$_recoverySuffix');

    if (await primary.exists()) {
      try {
        final settings = await _readSettings(primary);
        await _refreshRecoveryBestEffort(primary, recovery);
        await _deleteBestEffort(rollback);
        return settings;
      } catch (primaryError) {
        return _recoverOrThrow(
          primary: primary,
          rollback: rollback,
          recovery: recovery,
          primaryError: primaryError,
        );
      }
    }

    final hasFallback = await rollback.exists() || await recovery.exists();
    if (!hasFallback) {
      return AutomaticCloudBackupSettings.defaults;
    }

    return _recoverOrThrow(
      primary: primary,
      rollback: rollback,
      recovery: recovery,
      primaryError: const FileSystemException(
        'Die primäre Datei mit den Backup-Einstellungen fehlt.',
      ),
    );
  }

  Future<void> save(AutomaticCloudBackupSettings settings) async {
    final primary = await _settingsFile();
    final temporary = File('${primary.path}$_temporarySuffix');
    final rollback = File('${primary.path}$_rollbackSuffix');
    final recovery = File('${primary.path}$_recoverySuffix');
    final encoder = const JsonEncoder.withIndent('  ');

    try {
      final normalizedJson = settings.toJson();
      _validateSettingsJson(normalizedJson);

      await _deleteIfExists(temporary);
      await temporary.writeAsString(
        encoder.convert(normalizedJson),
        flush: true,
      );
      await _readSettings(temporary);

      await _deleteIfExists(rollback);
      if (await primary.exists()) {
        await primary.copy(rollback.path);
      }

      if (await primary.exists()) {
        await primary.delete();
      }
      await temporary.rename(primary.path);

      await _refreshRecoveryBestEffort(primary, recovery);
      await _deleteBestEffort(rollback);
      await _deleteBestEffort(temporary);
    } catch (error, stackTrace) {
      await _restoreRollbackBestEffort(primary, rollback);
      await _deleteBestEffort(temporary);

      Error.throwWithStackTrace(
        AutomaticCloudBackupSettingsException(
          'Die automatischen Backup-Einstellungen konnten nicht sicher '
          'gespeichert werden. Die bisherige Konfiguration bleibt erhalten.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }

  Future<AutomaticCloudBackupSettings> _recoverOrThrow({
    required File primary,
    required File rollback,
    required File recovery,
    required Object primaryError,
  }) async {
    Object? lastFallbackError;

    for (final candidate in <File>[rollback, recovery]) {
      if (!await candidate.exists()) {
        continue;
      }

      try {
        final settings = await _readSettings(candidate);
        await _restorePrimary(candidate, primary);
        await _refreshRecoveryBestEffort(primary, recovery);
        await _deleteBestEffort(rollback);
        return settings;
      } catch (error) {
        lastFallbackError = error;
      }
    }

    throw AutomaticCloudBackupSettingsException(
      'Die automatischen Backup-Einstellungen konnten nicht sicher gelesen '
      'werden. Die vorhandenen Dateien wurden nicht überschrieben.',
      cause: lastFallbackError ?? primaryError,
    );
  }

  Future<AutomaticCloudBackupSettings> _readSettings(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const FormatException(
        'Die Datei mit den Backup-Einstellungen ist ungültig.',
      );
    }

    final json = decoded.map((key, value) => MapEntry(key.toString(), value));
    _validateSettingsJson(json);
    return AutomaticCloudBackupSettings.fromJson(json);
  }

  static void _validateSettingsJson(Map<String, dynamic> json) {
    final enabled = json['enabled'];
    final intervalDays = json['intervalDays'];
    final retentionLimit = json['retentionLimit'];

    if (enabled is! bool) {
      throw const FormatException(
        'Der Status der automatischen Sicherung ist ungültig.',
      );
    }

    if (intervalDays is! int ||
        !AutomaticCloudBackupSettings.allowedIntervalDays.contains(
          intervalDays,
        )) {
      throw const FormatException(
        'Das Intervall der automatischen Sicherung ist ungültig.',
      );
    }

    if (retentionLimit is! int ||
        !AutomaticCloudBackupSettings.allowedRetentionLimits.contains(
          retentionLimit,
        )) {
      throw const FormatException(
        'Die Aufbewahrungsanzahl der automatischen Sicherung ist ungültig.',
      );
    }

    _validateOptionalDate(json['lastSuccessfulBackupAt']);
    _validateOptionalDate(json['lastCheckedAt']);

    final fingerprint = json['lastContentFingerprint'];
    if (fingerprint != null) {
      if (fingerprint is! String) {
        throw const FormatException('Der Backup-Fingerabdruck ist ungültig.');
      }

      try {
        json['lastContentFingerprint'] =
            BackupContentFingerprintService.normalize(fingerprint);
      } on FormatException {
        throw const FormatException('Der Backup-Fingerabdruck ist ungültig.');
      }
    }
  }

  static void _validateOptionalDate(Object? value) {
    if (value == null) {
      return;
    }
    if (value is! String || DateTime.tryParse(value) == null) {
      throw const FormatException(
        'Ein Zeitstempel der automatischen Sicherung ist ungültig.',
      );
    }
  }

  Future<void> _restorePrimary(File source, File primary) async {
    final temporary = File('${primary.path}.restore$_temporarySuffix');
    await _deleteIfExists(temporary);
    await source.copy(temporary.path);
    await _readSettings(temporary);

    if (await primary.exists()) {
      await primary.delete();
    }
    await temporary.rename(primary.path);
  }

  Future<void> _refreshRecoveryBestEffort(File primary, File recovery) async {
    final temporary = File('${recovery.path}$_temporarySuffix');
    try {
      await _deleteIfExists(temporary);
      await primary.copy(temporary.path);
      await _readSettings(temporary);

      if (await recovery.exists()) {
        await recovery.delete();
      }
      await temporary.rename(recovery.path);
    } catch (_) {
      await _deleteBestEffort(temporary);
    }
  }

  Future<void> _restoreRollbackBestEffort(File primary, File rollback) async {
    try {
      if (!await primary.exists() && await rollback.exists()) {
        await rollback.copy(primary.path);
      }
    } catch (_) {
      // Die Rollback-Datei bleibt für einen späteren Ladeversuch erhalten.
    }
  }

  Future<File> _settingsFile() async {
    final provider = supportDirectoryProvider;
    final directory = provider == null
        ? await getApplicationSupportDirectory()
        : await provider();

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  static Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> _deleteBestEffort(File file) async {
    try {
      await _deleteIfExists(file);
    } catch (_) {
      // Sicherheitsdateien werden beim nächsten Zugriff erneut geprüft.
    }
  }
}
