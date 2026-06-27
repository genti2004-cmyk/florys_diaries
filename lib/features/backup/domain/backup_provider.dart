import 'dart:io';

enum BackupProviderId {
  device,
  googleDrive,
  oneDrive,
  dropbox,
}

abstract interface class BackupProvider {
  const BackupProvider();

  BackupProviderId get id;
  String get displayName;
  String get description;
  bool get isAvailable;

  Future<BackupProviderSaveResult?> saveBackup(File sourceFile);

  Future<BackupProviderSelection?> pickBackup();
}

class BackupProviderSaveResult {
  const BackupProviderSaveResult({
    required this.displayName,
    required this.location,
  });

  final String displayName;
  final String location;
}

class BackupProviderSelection {
  const BackupProviderSelection({
    required this.file,
    required this.displayName,
    this.deleteAfterUse = false,
  });

  final File file;
  final String displayName;
  final bool deleteAfterUse;
}
