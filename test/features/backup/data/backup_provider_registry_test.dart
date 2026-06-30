import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/data/backup_provider_registry.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';

void main() {
  const registry = BackupProviderRegistry();

  test('stable release exposes only working backup providers', () {
    final providers = registry.providers;

    expect(providers.map((provider) => provider.id), <BackupProviderId>[
      BackupProviderId.device,
      BackupProviderId.googleDrive,
    ]);
    expect(providers.every((provider) => provider.isAvailable), isTrue);
  });

  test('unknown provider is rejected instead of silently using device', () {
    expect(
      () => registry.providerFor(BackupProviderId.oneDrive),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => registry.providerFor(BackupProviderId.dropbox),
      throwsA(isA<ArgumentError>()),
    );
  });
}
