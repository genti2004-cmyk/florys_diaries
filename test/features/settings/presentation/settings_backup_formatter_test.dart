import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';
import 'package:florys_diaries/features/settings/presentation/settings_backup_formatter.dart';

void main() {
  test('formats bytes in B, KB and MB', () {
    expect(SettingsBackupFormatter.formatBytes(512), '512 B');
    expect(SettingsBackupFormatter.formatBytes(1536), '1.5 KB');
    expect(SettingsBackupFormatter.formatBytes(2 * 1024 * 1024), '2.0 MB');
  });

  test('builds stable backup summaries', () {
    final createResult = AppBackupCreateResult(
      file: File('unused.zip'),
      createdAt: DateTime(2026, 6, 28, 10, 30),
      tripCount: 3,
      fileCount: 5,
      sizeBytes: 1536,
    );
    final inspection = AppBackupInspectionResult(
      backupCreatedAt: DateTime(2026, 6, 28, 10, 30),
      tripCount: 3,
      fileCount: 5,
      sizeBytes: 1536,
    );
    final restore = AppBackupRestoreResult(
      backupCreatedAt: DateTime(2026, 6, 28, 10, 30),
      tripCount: 3,
      fileCount: 5,
    );

    expect(
      SettingsBackupFormatter.savedBackupSummary(
        createResult,
        'backup.zip',
        'Gerät',
      ),
      contains('3 Reisen, 5 Dateien, 1.5 KB'),
    );
    expect(
      SettingsBackupFormatter.selectedBackupSummary('backup.zip', inspection),
      contains('3 Reisen'),
    );
    expect(
      SettingsBackupFormatter.restoreSummary(restore),
      contains('3 Reisen und 5 Dateien'),
    );
  });
}
