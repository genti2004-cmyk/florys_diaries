import 'dart:io';

import 'package:file_picker/file_picker.dart';

class BackupExportService {
  const BackupExportService();

  Future<String?> saveBackup(File sourceFile) async {
    if (!await sourceFile.exists()) {
      throw const FileSystemException(
        'Die neu erstellte Backup-Datei wurde nicht gefunden.',
      );
    }

    final bytes = await sourceFile.readAsBytes();
    return FilePicker.platform.saveFile(
      dialogTitle: 'FlorysDiaries Backup speichern',
      fileName: _baseName(sourceFile.path),
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      bytes: bytes,
    );
  }

  static String _baseName(String path) {
    final parts = path
        .split(RegExp(r'[\\/]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? 'FlorysDiaries_Backup.zip' : parts.last;
  }
}
