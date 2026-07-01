import 'dart:io';

import 'package:crypto/crypto.dart';

class BackupIntegrityService {
  const BackupIntegrityService();

  static final RegExp sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  Future<String> hashFile(File file) async {
    if (!await file.exists()) {
      throw const FileSystemException(
        'Eine zu sichernde Datei wurde nicht gefunden.',
      );
    }
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  String hashBytes(List<int> bytes) => sha256.convert(bytes).toString();

  Future<Map<String, String>> hashDirectory(Directory root) async {
    if (!await root.exists()) {
      return const <String, String>{};
    }

    final files = <File>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        files.add(entity);
      }
    }

    files.sort(
      (left, right) => _relativePath(root, left).compareTo(
        _relativePath(root, right),
      ),
    );

    final hashes = <String, String>{};
    for (final file in files) {
      hashes[_relativePath(root, file)] = await hashFile(file);
    }
    return Map<String, String>.unmodifiable(hashes);
  }

  static String normalizeSha256(Object? value, {required String label}) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (!sha256Pattern.hasMatch(normalized)) {
      throw FormatException('$label im Backup ist ungültig.');
    }
    return normalized;
  }

  static String _relativePath(Directory root, File file) {
    final separator = Platform.pathSeparator;
    final rootPath = root.absolute.path;
    final prefix = rootPath.endsWith(separator)
        ? rootPath
        : '$rootPath$separator';
    final filePath = file.absolute.path;
    if (!filePath.startsWith(prefix)) {
      throw const FileSystemException(
        'Eine Datei liegt außerhalb des Backup-Verzeichnisses.',
      );
    }
    return filePath.substring(prefix.length).replaceAll('\\', '/');
  }
}
