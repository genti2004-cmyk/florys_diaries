import 'dart:io';

import 'package:florys_diaries/features/backup/data/local_backup_service.dart';
import 'package:florys_diaries/features/backup/domain/data_safety_report.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/documents/data/travel_document_path_policy.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class DataSafetyService {
  const DataSafetyService({
    this.fileService = const TravelFileService(),
    this.localBackupService = const LocalBackupService(),
    this.clock,
  });

  final TravelFileService fileService;
  final LocalBackupService localBackupService;
  final DateTime Function()? clock;

  Future<DataSafetyReport> inspect(
    List<Trip> trips, {
    List<LocalBackupEntry>? localBackups,
  }) async {
    final referencedPaths = <String>{};
    var documentCount = 0;
    var missingFileCount = 0;
    var invalidReferenceCount = 0;

    final tripIds = <String>{};
    final documentIds = <String>{};

    for (final trip in trips) {
      if (trip.id.trim().isEmpty || !tripIds.add(trip.id)) {
        invalidReferenceCount++;
      }
      if (trip.endDate.isBefore(trip.startDate)) {
        invalidReferenceCount++;
      }

      for (final document in trip.documents) {
        documentCount++;
        final documentKey = '${trip.id}\u0000${document.id}';
        if (document.id.trim().isEmpty || !documentIds.add(documentKey)) {
          invalidReferenceCount++;
        }

        final path = TravelDocumentPathPolicy.normalize(document.relativePath);
        if (path.isEmpty) {
          continue;
        }
        if (!TravelDocumentPathPolicy.isDocumentPathForTrip(path, trip.id)) {
          invalidReferenceCount++;
          continue;
        }

        final pathKey = _pathKey(path);
        if (!referencedPaths.add(pathKey)) {
          invalidReferenceCount++;
          continue;
        }

        try {
          final file = await fileService.resolveExistingDocumentFile(document);
          if (file == null) {
            missingFileCount++;
          }
        } on FileSystemException {
          missingFileCount++;
        }
      }
    }

    final root = await fileService.rootDirectory();
    var managedFileCount = 0;
    var orphanFileCount = 0;

    if (await root.exists()) {
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        final relativePath = _relativePath(root, entity);
        if (!TravelDocumentPathPolicy.isManagedDocumentPath(relativePath)) {
          continue;
        }
        managedFileCount++;
        if (!referencedPaths.contains(_pathKey(relativePath))) {
          orphanFileCount++;
        }
      }
    }

    final backups =
        localBackups ?? await localBackupService.listBackups();
    final validBackups = backups
        .where((entry) => entry.isValid)
        .toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

    return DataSafetyReport(
      checkedAt: clock?.call() ?? DateTime.now(),
      tripCount: trips.length,
      documentCount: documentCount,
      managedFileCount: managedFileCount,
      missingFileCount: missingFileCount,
      orphanFileCount: orphanFileCount,
      invalidReferenceCount: invalidReferenceCount,
      validBackupCount: validBackups.length,
      invalidBackupCount: backups.length - validBackups.length,
      newestValidBackupAt: validBackups.isEmpty
          ? null
          : validBackups.first.createdAt,
    );
  }

  static String _relativePath(Directory root, File file) {
    var rootPath = root.absolute.path;
    var filePath = file.absolute.path;

    if (Platform.isWindows) {
      rootPath = rootPath.toLowerCase();
      filePath = filePath.toLowerCase();
    }

    final prefix = rootPath.endsWith(Platform.pathSeparator)
        ? rootPath
        : '$rootPath${Platform.pathSeparator}';
    if (!filePath.startsWith(prefix)) {
      return '';
    }

    final originalRoot = root.absolute.path;
    final originalPrefix = originalRoot.endsWith(Platform.pathSeparator)
        ? originalRoot
        : '$originalRoot${Platform.pathSeparator}';
    return TravelDocumentPathPolicy.normalize(
      file.absolute.path.substring(originalPrefix.length),
    );
  }

  static String _pathKey(String value) {
    final normalized = TravelDocumentPathPolicy.normalize(value);
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }
}
