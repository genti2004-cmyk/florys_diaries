import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/travel_document.dart';

typedef TravelFileClock = DateTime Function();

class TravelFileCopyResult {
  const TravelFileCopyResult({
    required this.fileName,
    required this.relativePath,
    required this.fileSizeBytes,
    required this.fileExtension,
  });

  final String fileName;
  final String relativePath;
  final int fileSizeBytes;
  final String fileExtension;
}

class TravelFileService {
  const TravelFileService({TravelFileClock? now}) : _now = now;

  final TravelFileClock? _now;

  Future<TravelFileCopyResult> copyFileToTrip({
    required String tripId,
    required String sourcePath,
    required String documentId,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Datei wurde nicht gefunden.');
    }

    final fileName = _fileNameFromPath(sourcePath);
    final extension = _extensionFromName(fileName);
    final safeName = _safeFileName(fileName);
    final targetDirectory = await _tripDocumentsDirectory(tripId);

    if (!await targetDirectory.exists()) {
      await targetDirectory.create(recursive: true);
    }

    final timestamp = (_now?.call() ?? DateTime.now()).microsecondsSinceEpoch;
    final targetName = '${documentId}_${timestamp}_$safeName';
    final targetFile = File(_join(targetDirectory.path, targetName));
    await source.copy(targetFile.path);

    final size = await targetFile.length();
    return TravelFileCopyResult(
      fileName: fileName,
      relativePath: _relativeDocumentPath(tripId, targetName),
      fileSizeBytes: size,
      fileExtension: extension,
    );
  }

  Future<File?> resolveDocumentFile(TravelDocument document) async {
    final relativePath = document.relativePath.trim();
    if (relativePath.isEmpty) {
      return null;
    }

    final root = await _rootDirectory();
    final file = File(_join(root.path, relativePath));
    return file;
  }

  Future<bool> documentFileExists(TravelDocument document) async {
    final file = await resolveDocumentFile(document);
    return file != null && file.existsSync();
  }

  Future<Directory> rootDirectory() {
    return _rootDirectory();
  }

  Future<Directory> tripDirectory(String tripId) async {
    final root = await _rootDirectory();
    return Directory(_join(root.path, _relativeTripPath(tripId)));
  }

  Future<Directory> tripExportDirectory(String tripId) async {
    final root = await _rootDirectory();
    return Directory(
      _join(root.path, _joinMany([_relativeTripPath(tripId), 'export'])),
    );
  }

  Future<void> deleteTripFiles(String tripId) async {
    final root = await _rootDirectory();
    final directory = Directory(_join(root.path, _relativeTripPath(tripId)));
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> deleteDocumentFile(TravelDocument document) async {
    final relativePath = document.relativePath.trim();
    if (relativePath.isEmpty) {
      return;
    }

    final root = await _rootDirectory();
    final file = File(_join(root.path, relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _rootDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory(_join(directory.path, 'FlorysDiaries'));
  }

  Future<Directory> _tripDocumentsDirectory(String tripId) async {
    final root = await _rootDirectory();
    return Directory(_join(root.path, _relativeTripDocumentsPath(tripId)));
  }

  static String _relativeTripPath(String tripId) {
    return _joinMany(['Reisen', _safeFolderName(tripId)]);
  }

  static String _relativeTripDocumentsPath(String tripId) {
    return _joinMany([_relativeTripPath(tripId), 'documents']);
  }

  static String _relativeDocumentPath(String tripId, String fileName) {
    return _joinMany([_relativeTripDocumentsPath(tripId), fileName]);
  }

  static String _fileNameFromPath(String path) {
    final parts = path.split(RegExp(r'[\\/]+'));
    return parts.isEmpty ? 'datei' : parts.last;
  }

  static String _extensionFromName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) {
      return '';
    }
    return parts.last.toLowerCase();
  }

  static String _safeFileName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    return cleaned.isEmpty ? 'datei' : cleaned;
  }

  static String _safeFolderName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    return cleaned.isEmpty ? 'reise' : cleaned;
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
