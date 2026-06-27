import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:florys_diaries/features/backup/data/backup_export_service.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';

class DeviceBackupProvider implements BackupProvider {
  const DeviceBackupProvider({
    this.exportService = const BackupExportService(),
  });

  final BackupExportService exportService;

  @override
  BackupProviderId get id => BackupProviderId.device;

  @override
  String get displayName => 'Dieses Gerät';

  @override
  String get description =>
      'Backup als ZIP-Datei in einem ausgewählten Geräteordner speichern.';

  @override
  bool get isAvailable => true;

  @override
  Future<BackupProviderSaveResult?> saveBackup(File sourceFile) async {
    final savedPath = await exportService.saveBackup(sourceFile);
    if (savedPath == null) {
      return null;
    }

    return BackupProviderSaveResult(
      displayName: _fileNameFromPath(savedPath, sourceFile.path),
      location: savedPath,
    );
  }

  @override
  Future<BackupProviderSelection?> pickBackup() async {
    final selection = await FilePicker.platform.pickFiles(
      dialogTitle: 'FlorysDiaries Backup auswählen',
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      allowMultiple: false,
      withData: false,
    );
    if (selection == null || selection.files.isEmpty) {
      return null;
    }

    final selectedFile = selection.files.single;
    final path = selectedFile.path;
    if (path == null || path.trim().isEmpty) {
      throw const FileSystemException(
        'Die ausgewählte Datei konnte nicht geöffnet werden.',
      );
    }

    return BackupProviderSelection(
      file: File(path),
      displayName: selectedFile.name,
    );
  }

  static String _fileNameFromPath(String savedPath, String fallbackPath) {
    final savedName = _lastPathSegment(savedPath);
    if (savedName.isNotEmpty && !savedName.contains('content:')) {
      return savedName;
    }

    final fallbackName = _lastPathSegment(fallbackPath);
    return fallbackName.isEmpty
        ? 'FlorysDiaries_Backup.zip'
        : fallbackName;
  }

  static String _lastPathSegment(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized
        .split('/')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? '' : parts.last;
  }
}
