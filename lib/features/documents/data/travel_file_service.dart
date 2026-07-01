import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/travel_document.dart';
import 'travel_document_path_policy.dart';

typedef TravelFileClock = DateTime Function();
typedef TravelFileRootDirectoryProvider = Future<Directory> Function();

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
  const TravelFileService({TravelFileClock? now, this.rootDirectoryProvider})
    : _now = now;

  static Future<Directory>? _defaultRootDirectoryFuture;

  final TravelFileClock? _now;
  final TravelFileRootDirectoryProvider? rootDirectoryProvider;

  Future<TravelFileCopyResult> copyFileToTrip({
    required String tripId,
    required String sourcePath,
    required String documentId,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Datei wurde nicht gefunden.', sourcePath);
    }

    final fileName = _fileNameFromPath(sourcePath);
    final extension = _extensionFromName(fileName);
    final safeName = TravelDocumentPathPolicy.safeFileName(fileName);
    final safeDocumentId = TravelDocumentPathPolicy.safeDocumentIdPart(
      documentId,
    );
    final timestamp = (_now?.call() ?? DateTime.now()).microsecondsSinceEpoch;
    final targetName = '${safeDocumentId}_${timestamp}_$safeName';
    final relativePath = TravelDocumentPathPolicy.relativeDocumentPath(
      tripId,
      targetName,
    );
    final targetFile = await _managedFile(relativePath);

    await targetFile.parent.create(recursive: true);

    try {
      await source.copy(targetFile.path);
    } catch (error, stackTrace) {
      await _deleteBestEffort(targetFile);
      Error.throwWithStackTrace(error, stackTrace);
    }

    final size = await targetFile.length();
    return TravelFileCopyResult(
      fileName: fileName,
      relativePath: relativePath,
      fileSizeBytes: size,
      fileExtension: extension,
    );
  }

  Future<File?> resolveDocumentFile(TravelDocument document) async {
    final relativePath = TravelDocumentPathPolicy.normalize(
      document.relativePath,
    );
    if (relativePath.isEmpty) {
      return null;
    }
    if (!TravelDocumentPathPolicy.isManagedDocumentPath(relativePath)) {
      return null;
    }

    return _managedFile(relativePath);
  }

  Future<File?> resolveExistingDocumentFile(TravelDocument document) async {
    final file = await resolveDocumentFile(document);
    if (file == null || !await file.exists()) {
      return null;
    }
    return file;
  }

  Future<bool> documentFileExists(TravelDocument document) async {
    final file = await resolveExistingDocumentFile(document);
    return file != null;
  }

  Future<Directory> rootDirectory() {
    return _rootDirectory();
  }

  Future<Directory> tripDirectory(String tripId) async {
    final root = await _rootDirectory();
    final relativePath = TravelDocumentPathPolicy.relativeTripPath(tripId);
    return Directory(_joinRelative(root.path, relativePath));
  }

  Future<Directory> tripExportDirectory(String tripId) async {
    final tripRoot = await tripDirectory(tripId);
    return Directory(_join(tripRoot.path, 'export'));
  }

  Future<void> deleteTripFiles(String tripId) async {
    final directory = await tripDirectory(tripId);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> deleteDocumentFile(TravelDocument document) async {
    final relativePath = TravelDocumentPathPolicy.normalize(
      document.relativePath,
    );
    if (relativePath.isEmpty) {
      return;
    }
    if (!TravelDocumentPathPolicy.isManagedDocumentPath(relativePath)) {
      throw FileSystemException(
        'Der Dokumentpfad ist ungültig und wurde nicht gelöscht.',
        document.relativePath,
      );
    }

    final file = await _managedFile(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _rootDirectory() async {
    final provider = rootDirectoryProvider;
    if (provider != null) {
      return provider();
    }

    final cached = _defaultRootDirectoryFuture;
    if (cached != null) {
      return cached;
    }

    final future = _loadDefaultRootDirectory();
    _defaultRootDirectoryFuture = future;
    try {
      return await future;
    } catch (_) {
      if (identical(_defaultRootDirectoryFuture, future)) {
        _defaultRootDirectoryFuture = null;
      }
      rethrow;
    }
  }

  static Future<Directory> _loadDefaultRootDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory(_join(directory.path, 'FlorysDiaries'));
  }

  Future<File> _managedFile(String relativePath) async {
    final normalized = TravelDocumentPathPolicy.normalize(relativePath);
    if (!TravelDocumentPathPolicy.isManagedDocumentPath(normalized)) {
      throw FileSystemException(
        'Der Dokumentpfad liegt außerhalb des geschützten App-Bereichs.',
        relativePath,
      );
    }

    final root = await _rootDirectory();
    final file = File(_joinRelative(root.path, normalized));
    if (!_isInsideRoot(root, file)) {
      throw FileSystemException(
        'Der Dokumentpfad liegt außerhalb des geschützten App-Bereichs.',
        relativePath,
      );
    }
    return file;
  }

  static bool _isInsideRoot(Directory root, File file) {
    var rootPath = root.absolute.path;
    var filePath = file.absolute.path;

    if (Platform.isWindows) {
      rootPath = rootPath.toLowerCase();
      filePath = filePath.toLowerCase();
    }

    final prefix = rootPath.endsWith(Platform.pathSeparator)
        ? rootPath
        : '$rootPath${Platform.pathSeparator}';
    return filePath.startsWith(prefix);
  }

  static Future<void> _deleteBestEffort(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Der ursprüngliche Kopierfehler wird weitergereicht.
    }
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

  static String _join(String left, String right) {
    return '$left${Platform.pathSeparator}$right';
  }

  static String _joinRelative(String root, String relativePath) {
    return [
      root,
      ...TravelDocumentPathPolicy.normalize(relativePath).split('/'),
    ].join(Platform.pathSeparator);
  }
}
