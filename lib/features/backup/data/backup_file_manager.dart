import 'dart:io';

import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/trips/data/trip_storage_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class BackupCopySummary {
  const BackupCopySummary({required this.fileCount, required this.totalBytes});

  final int fileCount;
  final int totalBytes;
}

class BackupFileManager {
  const BackupFileManager({
    this.fileService = const TravelFileService(),
    this.storageService = const TripStorageService(),
  });

  final TravelFileService fileService;
  final TripStorageService storageService;

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
    final currentTrips = await storageService.loadTrips();
    final localRoot = await fileService.rootDirectory();
    final safetyRoot = Directory('${localRoot.path}.restore_safety_$stamp');
    var movedExistingRoot = false;

    if (!await localRoot.parent.exists()) {
      await localRoot.parent.create(recursive: true);
    }
    if (await safetyRoot.exists()) {
      await safetyRoot.delete(recursive: true);
    }

    try {
      if (await localRoot.exists()) {
        await localRoot.rename(safetyRoot.path);
        movedExistingRoot = true;
      }

      await localRoot.create(recursive: true);
      await copyDirectoryContents(stagedFiles, localRoot);
      await storageService.saveTrips(restoredTrips);

      if (await safetyRoot.exists()) {
        await safetyRoot.delete(recursive: true);
      }
    } catch (_) {
      if (await localRoot.exists()) {
        await localRoot.delete(recursive: true);
      }
      if (movedExistingRoot && await safetyRoot.exists()) {
        await safetyRoot.rename(localRoot.path);
      }
      try {
        await storageService.saveTrips(currentTrips);
      } catch (_) {
        // Der ursprüngliche Fehler bleibt maßgeblich.
      }
      rethrow;
    }
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
