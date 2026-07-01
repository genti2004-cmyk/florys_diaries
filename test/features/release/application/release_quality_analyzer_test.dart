import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/domain/data_safety_report.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/release/application/release_quality_analyzer.dart';
import 'package:florys_diaries/features/release/domain/release_quality_report.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  const analyzer = ReleaseQualityAnalyzer();
  final now = DateTime(2026, 7, 2, 12);

  test('healthy data and a recent backup are release-ready', () {
    final report = analyzer.inspect(
      trips: [
        Trip(
          id: 'trip-1',
          title: 'Berlin',
          destination: 'Berlin',
          country: 'Deutschland',
          startDate: DateTime(2026, 7, 10),
          endDate: DateTime(2026, 7, 12),
        ),
      ],
      localBackups: [
        LocalBackupEntry(
          file: File('FlorysDiaries_Backup.zip'),
          createdAt: DateTime(2026, 7, 2, 8),
          sizeBytes: 2048,
          isAutomatic: false,
        ),
      ],
      dataSafetyReport: DataSafetyReport(
        checkedAt: now,
        tripCount: 1,
        documentCount: 0,
        managedFileCount: 0,
        missingFileCount: 0,
        orphanFileCount: 0,
        invalidReferenceCount: 0,
        validBackupCount: 1,
        invalidBackupCount: 0,
        newestValidBackupAt: DateTime(2026, 7, 2, 8),
      ),
      isReleaseBuild: true,
      now: now,
    );

    expect(report.state, ReleaseCheckState.ready);
    expect(report.tripCount, 1);
    expect(report.blockedCount, 0);
    expect(report.attentionCount, 0);
  });

  test('critical data findings block release readiness', () {
    final report = analyzer.inspect(
      trips: const [],
      localBackups: [
        LocalBackupEntry(
          file: File('FlorysDiaries_Backup.zip'),
          createdAt: now,
          sizeBytes: 1024,
          isAutomatic: false,
        ),
      ],
      dataSafetyReport: DataSafetyReport(
        checkedAt: now,
        tripCount: 0,
        documentCount: 1,
        managedFileCount: 1,
        missingFileCount: 1,
        orphanFileCount: 0,
        invalidReferenceCount: 0,
        validBackupCount: 1,
        invalidBackupCount: 0,
        newestValidBackupAt: now,
      ),
      isReleaseBuild: true,
      now: now,
    );

    expect(report.state, ReleaseCheckState.blocked);
    expect(report.blockedCount, 1);
    expect(
      report.checks.singleWhere((check) => check.id == 'data-safety').state,
      ReleaseCheckState.blocked,
    );
  });

  test('debug build and missing backup remain explicit attention items', () {
    final report = analyzer.inspect(
      trips: const [],
      localBackups: const [],
      dataSafetyReport: null,
      isReleaseBuild: false,
      now: now,
    );

    expect(report.state, ReleaseCheckState.attention);
    expect(report.attentionCount, 3);
    expect(report.blockedCount, 0);
  });
}
