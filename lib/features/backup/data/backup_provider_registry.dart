import 'package:florys_diaries/features/backup/data/device_backup_provider.dart';
import 'package:florys_diaries/features/backup/data/google_drive_backup_provider.dart';
import 'package:florys_diaries/features/backup/data/planned_cloud_backup_provider.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';

class BackupProviderRegistry {
  const BackupProviderRegistry();

  static const List<BackupProvider> _providers = [
    DeviceBackupProvider(),
    GoogleDriveBackupProvider(),
    PlannedCloudBackupProvider(
      id: BackupProviderId.oneDrive,
      displayName: 'Microsoft OneDrive',
      description: 'Cloud-Anbindung vorbereitet; Anmeldung folgt später.',
    ),
    PlannedCloudBackupProvider(
      id: BackupProviderId.dropbox,
      displayName: 'Dropbox',
      description: 'Cloud-Anbindung vorbereitet; Anmeldung folgt später.',
    ),
  ];

  List<BackupProvider> get providers => _providers;

  BackupProvider providerFor(BackupProviderId id) {
    return _providers.firstWhere(
      (provider) => provider.id == id,
      orElse: () => _providers.first,
    );
  }
}
