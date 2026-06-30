import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/core/constants/app_metadata.dart';
import 'package:florys_diaries/features/backup/data/backup_provider_registry.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';

void main() {
  test('v1 release version is synchronized across project metadata', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final readme = File('README.md').readAsStringSync();
    final changelog = File('CHANGELOG.md').readAsStringSync();

    expect(AppMetadata.version, '1.0.0');
    expect(AppMetadata.buildNumber, 7);
    expect(AppMetadata.fullVersion, '1.0.0+7');
    expect(pubspec, contains('version: ${AppMetadata.fullVersion}'));
    expect(readme, contains('`v${AppMetadata.fullVersion}`'));
    expect(changelog, contains('## ${AppMetadata.fullVersion}'));
  });

  test('v1 keeps the established release and debug identities', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(AppMetadata.releasePackageId, 'com.florysdiaries.app');
    expect(AppMetadata.debugPackageId, 'com.florysdiaries.app.debug');
    expect(gradle, contains('namespace = "com.florysdiaries.app"'));
    expect(gradle, contains('applicationId = "com.florysdiaries.app"'));
    expect(gradle, isNot(contains('namespace = releaseApplicationId')));
    expect(gradle, contains('applicationIdSuffix = ".debug"'));
    expect(
      manifest,
      contains('android:name="com.florysdiaries.app.MainActivity"'),
    );
  });

  test('Android release keeps platform backup and cleartext disabled', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final backupRules = File(
      'android/app/src/main/res/xml/backup_rules.xml',
    ).readAsStringSync();
    final extractionRules = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );

    expect(backupRules, contains('<full-backup-content>'));
    expect(backupRules, contains('<exclude domain="root" path="."'));
    expect(backupRules, contains('<exclude domain="file" path="."'));
    expect(backupRules, contains('<exclude domain="database" path="."'));
    expect(backupRules, contains('<exclude domain="sharedpref" path="."'));

    expect(extractionRules, contains('<data-extraction-rules>'));
    expect(extractionRules, contains('<cloud-backup>'));
    expect(extractionRules, contains('<device-transfer>'));
    expect(extractionRules, contains('<exclude domain="root" path="."'));
    expect(extractionRules, contains('<exclude domain="file" path="."'));
    expect(extractionRules, contains('<exclude domain="database" path="."'));
    expect(extractionRules, contains('<exclude domain="sharedpref" path="."'));
  });

  test('stable v1 exposes only functional backup destinations', () {
    const registry = BackupProviderRegistry();
    final ids = registry.providers
        .map((provider) => provider.id)
        .toList(growable: false);

    expect(ids, <BackupProviderId>[
      BackupProviderId.device,
      BackupProviderId.googleDrive,
    ]);
    expect(
      registry.providers.every((provider) => provider.isAvailable),
      isTrue,
    );
  });

  test('local signing secrets are protected by ignore rules', () {
    final rootIgnore = File('.gitignore').readAsStringSync();
    final androidIgnore = File('android/.gitignore').readAsStringSync();

    expect(rootIgnore, contains('**/key.properties'));
    expect(rootIgnore, contains('**/*.jks'));
    expect(rootIgnore, contains('**/*.keystore'));

    expect(androidIgnore, contains('key.properties'));
    expect(androidIgnore, contains('**/*.jks'));
    expect(androidIgnore, contains('**/*.keystore'));
  });
}
