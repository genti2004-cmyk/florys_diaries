import 'package:florys_diaries/features/backup/data/device_backup_provider.dart';
import 'package:florys_diaries/features/backup/data/google_drive_backup_provider.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';

class BackupProviderRegistry {
  const BackupProviderRegistry();

  static const List<BackupProvider> _providers = <BackupProvider>[
    DeviceBackupProvider(),
    GoogleDriveBackupProvider(),
  ];

  List<BackupProvider> get providers => _providers;

  BackupProvider providerFor(BackupProviderId id) {
    for (final provider in _providers) {
      if (provider.id == id) {
        return provider;
      }
    }

    throw ArgumentError.value(
      id,
      'id',
      'Dieses Backup-Ziel ist in der stabilen App nicht verfügbar.',
    );
  }
}
