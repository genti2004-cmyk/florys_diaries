import 'dart:io';

import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/trips/data/trip_storage_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

typedef BackupDirectoryRenamer =
    Future<Directory> Function(Directory source, String targetPath);

class BackupCopySummary {
  const BackupCopySummary({required this.fileCount, required this.totalBytes});

  final int fileCount;
  final int totalBytes;
}

class BackupFileManager {
  const BackupFileManager({
    this.fileService = const TravelFileService(),
    this.storageService = const TripStorageService(),
    this.directoryRenamer,
  });

  final TravelFileService fileService;
  final TripStorageService storageService;
  final BackupDirectoryRenamer? directoryRenamer;

  Future<BackupCopySummary> copyDirectoryContents(
    Directory source,
    Directory target,
  ) async {
    if (!await source.exists()) {
      return const BackupCopySummary(fileCount: 0, totalBytes: 0);
    }

    var fileCount = 0;
    var totalBytes = 0;

    await for (final entity in source.list(followLinks: false)) {
      final name = _baseName(entity.path);
      if (entity is Directory) {
        final childTarget = Directory(_join(target.path, name));
        await childTarget.create(recursive: true);
        final childSummary = await copyDirectoryContents(entity, childTarget);
        fileCount += childSummary.fileCount;
        totalBytes += childSummary.totalBytes;
      } else if (entity is File) {
        await target.create(recursive: true);
        final copied = await entity.copy(_join(target.path, name));
        fileCount++;
        totalBytes += await copied.length();
      }
    }

    return BackupCopySummary(fileCount: fileCount, totalBytes: totalBytes);
  }

  Future<void> replaceLocalData({
    required List<Trip> restoredTrips,
    required Directory stagedFiles,
    required int stamp,
  }) async {
    if (!await stagedFiles.exists()) {
      throw const FileSystemException(
        'Die vorbereiteten Backup-Dateien wurden nicht gefunden.',
      );
    }

    final currentTrips = await storageService.loadTrips();
    final localRoot = await fileService.rootDirectory();
    final safetyRoot = Directory('${localRoot.path}.restore_safety_$stamp');
    final hadExistingRoot = await localRoot.exists();

    var originalRootMoved = false;
    var replacementRootCreated = false;
    var restoredTripsSaveStarted = false;

    if (!await localRoot.parent.exists()) {
      await localRoot.parent.create(recursive: true);
    }
    if (await safetyRoot.exists()) {
      await safetyRoot.delete(recursive: true);
    }

    try {
      if (hadExistingRoot) {
        await _renameDirectory(localRoot, safetyRoot.path);
        originalRootMoved = true;
      }

      await localRoot.create(recursive: true);
      replacementRootCreated = true;
      await copyDirectoryContents(stagedFiles, localRoot);

      restoredTripsSaveStarted = true;
      await storageService.saveTrips(restoredTrips);

      if (await safetyRoot.exists()) {
        await safetyRoot.delete(recursive: true);
      }
    } catch (error, stackTrace) {
      final rollbackFailures = <Object>[];

      if (replacementRootCreated) {
        try {
          if (await localRoot.exists()) {
            await localRoot.delete(recursive: true);
          }
        } catch (rollbackError) {
          rollbackFailures.add(rollbackError);
        }
      }

      if (originalRootMoved) {
        try {
          if (await safetyRoot.exists()) {
            await _renameDirectory(safetyRoot, localRoot.path);
          } else {
            rollbackFailures.add(
              const FileSystemException(
                'Der Sicherheitsordner des vorherigen Datenstands fehlt.',
              ),
            );
          }
        } catch (rollbackError) {
          rollbackFailures.add(rollbackError);
        }
      }

      if (restoredTripsSaveStarted) {
        try {
          await storageService.saveTrips(currentTrips);
        } catch (rollbackError) {
          rollbackFailures.add(rollbackError);
        }
      }

      if (rollbackFailures.isNotEmpty) {
        Error.throwWithStackTrace(
          const FileSystemException(
            'Die Wiederherstellung ist fehlgeschlagen und der vorherige '
            'Datenstand konnte nicht vollständig zurückgesetzt werden. '
            'Bitte keine weiteren Änderungen vornehmen und ein vorhandenes '
            'Backup prüfen.',
          ),
          stackTrace,
        );
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<Directory> _renameDirectory(Directory source, String targetPath) {
    final customRenamer = directoryRenamer;
    if (customRenamer != null) {
      return customRenamer(source, targetPath);
    }
    return source.rename(targetPath);
  }

  static String _baseName(String path) {
    final parts = path
        .split(RegExp(r'[\\/]+'))
        .where((part) => part.isNotEmpty);
    return parts.isEmpty ? 'datei' : parts.last;
  }

  static String _join(String left, String right) {
    return '$left${Platform.pathSeparator}$right';
  }
}
