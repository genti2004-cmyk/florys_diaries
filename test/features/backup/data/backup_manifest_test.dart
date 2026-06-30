import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/core/constants/app_metadata.dart';
import 'package:florys_diaries/features/backup/data/backup_archive_reader.dart';
import 'package:florys_diaries/features/backup/data/backup_manifest.dart';

void main() {
  test('backup manifest uses the central current app version', () {
    final manifest = BackupManifest.create(
      createdAt: DateTime.utc(2026, 6, 29, 12, 30),
      tripCount: 3,
      fileCount: 5,
      contentBytes: 4096,
    );

    expect(manifest['format'], BackupArchiveReader.formatId);
    expect(manifest['schemaVersion'], BackupArchiveReader.schemaVersion);
    expect(manifest['appVersion'], AppMetadata.version);
    expect(manifest['createdAt'], '2026-06-29T12:30:00.000Z');
    expect(manifest['tripCount'], 3);
    expect(manifest['fileCount'], 5);
    expect(manifest['contentBytes'], 4096);
  });

  test('pubspec version matches central metadata', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([^\s]+)',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull);
    expect(match!.group(1), AppMetadata.fullVersion);
  });

  test('central metadata exposes the installed build consistently', () {
    expect(AppMetadata.name, 'FlorysDiaries');
    expect(AppMetadata.developmentName, 'FlorysDiaries DEV');
    expect(AppMetadata.releasePackageId, 'com.florysdiaries.app');
    expect(AppMetadata.debugPackageId, 'com.florysdiaries.app.debug');
    expect(AppMetadata.mapUserAgentPackageName, AppMetadata.releasePackageId);
    expect(AppMetadata.version, '1.0.0');
    expect(AppMetadata.buildNumber, 7);
    expect(AppMetadata.displayVersion, 'v1.0.0');
    expect(AppMetadata.fullVersion, '1.0.0+7');
  });
}
