import 'dart:io';

import 'package:florys_diaries/features/backup/domain/backup_integrity_level.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class AppBackupCreateResult {
  const AppBackupCreateResult({
    required this.file,
    required this.createdAt,
    required this.tripCount,
    required this.fileCount,
    required this.sizeBytes,
  });

  final File file;
  final DateTime createdAt;
  final int tripCount;
  final int fileCount;
  final int sizeBytes;
}

class AppBackupInspectionResult {
  const AppBackupInspectionResult({
    required this.backupCreatedAt,
    required this.tripCount,
    required this.fileCount,
    required this.sizeBytes,
    this.appVersion = 'Unbekannt',
    this.countryCount = 0,
    this.destinationCount = 0,
    this.documentCount = 0,
    this.albumEntryCount = 0,
    this.checklistItemCount = 0,
    this.firstTripStartAt,
    this.lastTripEndAt,
    this.integrityLevel = BackupIntegrityLevel.structural,
  });

  factory AppBackupInspectionResult.fromTrips({
    required DateTime backupCreatedAt,
    required List<Trip> trips,
    required int fileCount,
    required int sizeBytes,
    required String appVersion,
    BackupIntegrityLevel integrityLevel = BackupIntegrityLevel.structural,
  }) {
    final countries = <String>{};
    final destinations = <String>{};
    var documentCount = 0;
    var albumEntryCount = 0;
    var checklistItemCount = 0;
    DateTime? firstTripStartAt;
    DateTime? lastTripEndAt;

    for (final trip in trips) {
      final country = trip.country.trim().toLowerCase();
      if (country.isNotEmpty) {
        countries.add(country);
      }

      final destination = trip.destination.trim().toLowerCase();
      if (destination.isNotEmpty) {
        destinations.add(destination);
      }

      documentCount += trip.documents.length;
      albumEntryCount += trip.albumEntries.length;
      checklistItemCount += trip.checklistItems.length;

      if (firstTripStartAt == null ||
          trip.startDate.isBefore(firstTripStartAt)) {
        firstTripStartAt = trip.startDate;
      }
      if (lastTripEndAt == null || trip.endDate.isAfter(lastTripEndAt)) {
        lastTripEndAt = trip.endDate;
      }
    }

    return AppBackupInspectionResult(
      backupCreatedAt: backupCreatedAt,
      tripCount: trips.length,
      fileCount: fileCount,
      sizeBytes: sizeBytes,
      appVersion: appVersion.trim().isEmpty ? 'Unbekannt' : appVersion.trim(),
      countryCount: countries.length,
      destinationCount: destinations.length,
      documentCount: documentCount,
      albumEntryCount: albumEntryCount,
      checklistItemCount: checklistItemCount,
      firstTripStartAt: firstTripStartAt,
      lastTripEndAt: lastTripEndAt,
      integrityLevel: integrityLevel,
    );
  }

  final DateTime backupCreatedAt;
  final int tripCount;
  final int fileCount;
  final int sizeBytes;
  final String appVersion;
  final int countryCount;
  final int destinationCount;
  final int documentCount;
  final int albumEntryCount;
  final int checklistItemCount;
  final DateTime? firstTripStartAt;
  final DateTime? lastTripEndAt;
  final BackupIntegrityLevel integrityLevel;

  bool get isCryptographicallyVerified => integrityLevel.isCryptographic;

  bool get hasTravelPeriod => firstTripStartAt != null && lastTripEndAt != null;
}

class AppBackupRestoreResult {
  const AppBackupRestoreResult({
    required this.backupCreatedAt,
    required this.tripCount,
    required this.fileCount,
  });

  final DateTime backupCreatedAt;
  final int tripCount;
  final int fileCount;
}
