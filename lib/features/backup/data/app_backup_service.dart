import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

import 'package:florys_diaries/features/backup/data/backup_archive_reader.dart';
import 'package:florys_diaries/features/backup/data/backup_file_manager.dart';
import 'package:florys_diaries/features/backup/data/backup_manifest.dart';
import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

typedef BackupTemporaryDirectoryProvider = Future<Directory> Function();

class AppBackupService {
  const AppBackupService({
    this.archiveReader = const BackupArchiveReader(),
    this.fileManager = const BackupFileManager(),
    this.temporaryDirectoryProvider,
  });

  final BackupArchiveReader archiveReader;
  final BackupFileManager fileManager;
  final BackupTemporaryDirectoryProvider? temporaryDirectoryProvider;

  Future<AppBackupCreateResult> createBackup(
    List<Trip> trips, {
    String fileNamePrefix = 'FlorysDiaries_Backup',
  }) async {
    final now = DateTime.now();
    final temp = await _temporaryDirectory();
    final workspace = Directory(
      _joinMany([
        temp.path,
        'florys_diaries_backup_workspace_${now.microsecondsSinceEpoch}',
      ]),
    );
    final filesDirectory = Directory(_join(workspace.path, 'files'));
    File? target;

    await filesDirectory.create(recursive: true);

    try {
      final sourceRoot = await fileManager.fileService.rootDirectory();
      final copied = await fileManager.copyDirectoryContents(
        sourceRoot,
        filesDirectory,
      );
      await _writeTripsFile(workspace, trips);
      await _writeManifest(
        workspace,
        createdAt: now,
        tripCount: trips.length,
        fileCount: copied.fileCount,
        contentBytes: copied.totalBytes,
      );

      final backupTarget = await _targetBackupFile(
        now,
        fileNamePrefix: fileNamePrefix,
      );
      target = backupTarget;
      if (await backupTarget.exists()) {
        await backupTarget.delete();
      }

      final encoder = ZipFileEncoder();
      encoder.create(backupTarget.path);
      await encoder.addDirectory(workspace, includeDirName: false);
      encoder.closeSync();

      // Ein Backup wird erst als erfolgreich gemeldet, wenn es mit genau
      // demselben Leser vollständig geprüft wurde, der später für Vorschau
      // und Wiederherstellung verwendet wird.
      await archiveReader.read(backupTarget);

      return AppBackupCreateResult(
        file: backupTarget,
        createdAt: now,
        tripCount: trips.length,
        fileCount: copied.fileCount,
        sizeBytes: await backupTarget.length(),
      );
    } catch (error, stackTrace) {
      if (target != null) {
        await _deleteBestEffort(target);
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      if (await workspace.exists()) {
        await workspace.delete(recursive: true);
      }
    }
  }

  Future<AppBackupInspectionResult> inspectBackup(File backupFile) async {
    final package = await archiveReader.read(backupFile);
    return AppBackupInspectionResult.fromTrips(
      backupCreatedAt: package.createdAt,
      trips: package.trips,
      fileCount: package.fileEntries.length,
      sizeBytes: await backupFile.length(),
      appVersion: package.appVersion,
    );
  }

  Future<AppBackupRestoreResult> restoreBackup(File backupFile) async {
    final package = await archiveReader.read(backupFile);
    final temp = await _temporaryDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final stagingRoot = Directory(
      _joinMany([temp.path, 'florys_diaries_restore_$stamp']),
    );
    final stagedFiles = Directory(_join(stagingRoot.path, 'files'));

    await stagedFiles.create(recursive: true);

    try {
      final extractedFileCount = await archiveReader.extractFiles(
        package,
        stagedFiles,
      );
      await fileManager.replaceLocalData(
        restoredTrips: package.trips,
        stagedFiles: stagedFiles,
        stamp: stamp,
      );

      return AppBackupRestoreResult(
        backupCreatedAt: package.createdAt,
        tripCount: package.trips.length,
        fileCount: extractedFileCount,
      );
    } finally {
      if (await stagingRoot.exists()) {
        await stagingRoot.delete(recursive: true);
      }
    }
  }

  Future<void> _writeTripsFile(Directory workspace, List<Trip> trips) async {
    final encoder = const JsonEncoder.withIndent('  ');
    final file = File(_join(workspace.path, 'trips.json'));
    await file.writeAsString(
      encoder.convert(trips.map((trip) => trip.toJson()).toList()),
      flush: true,
    );
  }

  Future<void> _writeManifest(
    Directory workspace, {
    required DateTime createdAt,
    required int tripCount,
    required int fileCount,
    required int contentBytes,
  }) async {
    final encoder = const JsonEncoder.withIndent('  ');
    final file = File(_join(workspace.path, 'manifest.json'));
    await file.writeAsString(
      encoder.convert(
        BackupManifest.create(
          createdAt: createdAt,
          tripCount: tripCount,
          fileCount: fileCount,
          contentBytes: contentBytes,
        ),
      ),
      flush: true,
    );
  }

  Future<File> _targetBackupFile(
    DateTime createdAt, {
    required String fileNamePrefix,
  }) async {
    final temp = await _temporaryDirectory();
    final output = Directory(_join(temp.path, 'florys_diaries_backups'));
    await output.create(recursive: true);

    return File(
      _join(
        output.path,
        '${_safePrefix(fileNamePrefix)}_${_fileStamp(createdAt)}.zip',
      ),
    );
  }

  Future<Directory> _temporaryDirectory() {
    final provider = temporaryDirectoryProvider;
    return provider == null ? getTemporaryDirectory() : provider();
  }

  static Future<void> _deleteBestEffort(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Der ursprüngliche Erstellungs- oder Prüfungsfehler wird weitergereicht.
    }
  }

  static String _safePrefix(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'FlorysDiaries_Backup' : cleaned;
  }

  static String _fileStamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }

  static String _join(String left, String right) {
    return '$left${Platform.pathSeparator}$right';
  }

  static String _joinMany(List<String> parts) {
    return parts
        .where((part) => part.trim().isNotEmpty)
        .join(Platform.pathSeparator);
  }
}
