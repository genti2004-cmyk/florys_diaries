import 'package:florys_diaries/core/constants/app_metadata.dart';
import 'package:florys_diaries/features/backup/domain/data_safety_report.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/release/domain/release_quality_report.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class ReleaseQualityAnalyzer {
  const ReleaseQualityAnalyzer();

  ReleaseQualityReport inspect({
    required List<Trip> trips,
    required List<LocalBackupEntry> localBackups,
    required DataSafetyReport? dataSafetyReport,
    required bool isReleaseBuild,
    DateTime? now,
  }) {
    final checkedAt = now ?? DateTime.now();
    final checks = <ReleaseQualityCheck>[
      _buildModeCheck(isReleaseBuild),
      _identityCheck(),
      _versionCheck(),
      _dataSafetyCheck(dataSafetyReport),
      _backupCheck(localBackups, checkedAt),
      const ReleaseQualityCheck(
        id: 'backup-integrity',
        title: 'Backup-Integrität',
        detail:
            'Neue Backups verwenden Format 2 mit SHA-256-Prüfsummen; ältere Backups bleiben lesbar.',
        state: ReleaseCheckState.ready,
      ),
    ];

    return ReleaseQualityReport(
      generatedAt: checkedAt,
      isReleaseBuild: isReleaseBuild,
      tripCount: trips.length,
      documentCount: trips.fold<int>(
        0,
        (sum, trip) => sum + trip.documents.length,
      ),
      momentCount: trips.fold<int>(
        0,
        (sum, trip) => sum + trip.albumEntries.length,
      ),
      planItemCount: trips.fold<int>(
        0,
        (sum, trip) => sum + trip.planItems.length,
      ),
      expenseCount: trips.fold<int>(
        0,
        (sum, trip) => sum + trip.budgetExpenses.length,
      ),
      participantCount: trips.fold<int>(
        0,
        (sum, trip) => sum + trip.participants.length,
      ),
      checks: List<ReleaseQualityCheck>.unmodifiable(checks),
    );
  }

  ReleaseQualityCheck _buildModeCheck(bool isReleaseBuild) {
    if (isReleaseBuild) {
      return const ReleaseQualityCheck(
        id: 'build-mode',
        title: 'Buildmodus',
        detail: 'Die App läuft als Release-Build.',
        state: ReleaseCheckState.ready,
      );
    }

    return const ReleaseQualityCheck(
      id: 'build-mode',
      title: 'Buildmodus',
      detail:
          'Aktuell läuft ein Debug- oder Profil-Build. Für die finale Prüfung ist ein signierter Release-Build erforderlich.',
      state: ReleaseCheckState.attention,
    );
  }

  ReleaseQualityCheck _identityCheck() {
    final releaseId = AppMetadata.releasePackageId.trim();
    final debugId = AppMetadata.debugPackageId.trim();
    final isValid = releaseId == 'com.florysdiaries.app' &&
        debugId.isNotEmpty &&
        debugId != releaseId;

    return ReleaseQualityCheck(
      id: 'app-identity',
      title: 'App-Identität',
      detail: isValid
          ? 'Release und DEV verwenden getrennte Paketkennungen.'
          : 'Paketkennungen sind leer, identisch oder entsprechen nicht der festgelegten Release-Kennung.',
      state: isValid
          ? ReleaseCheckState.ready
          : ReleaseCheckState.blocked,
    );
  }

  ReleaseQualityCheck _versionCheck() {
    final isValid = AppMetadata.version.trim().isNotEmpty &&
        AppMetadata.buildNumber > 0 &&
        AppMetadata.developmentMilestone.trim().isNotEmpty;

    return ReleaseQualityCheck(
      id: 'version-metadata',
      title: 'Versionsangaben',
      detail: isValid
          ? '${AppMetadata.displayVersion}, Build ${AppMetadata.buildNumber}; Entwicklungsstand ${AppMetadata.developmentMilestone}.'
          : 'Release-Version, Buildnummer oder Entwicklungsstand fehlen.',
      state: isValid
          ? ReleaseCheckState.ready
          : ReleaseCheckState.blocked,
    );
  }

  ReleaseQualityCheck _dataSafetyCheck(DataSafetyReport? report) {
    if (report == null) {
      return const ReleaseQualityCheck(
        id: 'data-safety',
        title: 'Daten-Sicherheitsprüfung',
        detail:
            'Die lokale Datenprüfung wurde in dieser Sitzung noch nicht abgeschlossen.',
        state: ReleaseCheckState.attention,
      );
    }

    return switch (report.state) {
      DataSafetyState.healthy => ReleaseQualityCheck(
          id: 'data-safety',
          title: 'Daten-Sicherheitsprüfung',
          detail:
              '${report.documentCount} Dokumente und ${report.managedFileCount} verwaltete Dateien wurden ohne kritischen Befund geprüft.',
          state: ReleaseCheckState.ready,
        ),
      DataSafetyState.warning => ReleaseQualityCheck(
          id: 'data-safety',
          title: 'Daten-Sicherheitsprüfung',
          detail:
              '${report.issueCount} Hinweis(e) wurden gefunden. Vor dem Release Backup-Alter, verwaiste Dateien und ungültige Backups prüfen.',
          state: ReleaseCheckState.attention,
        ),
      DataSafetyState.critical => ReleaseQualityCheck(
          id: 'data-safety',
          title: 'Daten-Sicherheitsprüfung',
          detail:
              '${report.issueCount} kritische oder relevante Datenprobleme wurden erkannt. Fehlende Dateien oder ungültige Referenzen zuerst beheben.',
          state: ReleaseCheckState.blocked,
        ),
    };
  }

  ReleaseQualityCheck _backupCheck(
    List<LocalBackupEntry> entries,
    DateTime checkedAt,
  ) {
    final valid = entries.where((entry) => entry.isValid).toList();
    final invalidCount = entries.length - valid.length;

    if (valid.isEmpty) {
      return ReleaseQualityCheck(
        id: 'local-backup',
        title: 'Lokales Sicherheitsbackup',
        detail: invalidCount == 0
            ? 'Es ist noch kein gültiges lokales Backup vorhanden.'
            : 'Es ist kein gültiges Backup vorhanden; $invalidCount Sicherung(en) sind ungültig.',
        state: ReleaseCheckState.attention,
      );
    }

    valid.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    final newest = valid.first.createdAt;
    final age = checkedAt.difference(newest).inDays.clamp(0, 999999);

    if (age > 7 || invalidCount > 0) {
      final reasons = <String>[];
      if (age > 7) {
        reasons.add('das neueste gültige Backup ist $age Tage alt');
      }
      if (invalidCount > 0) {
        reasons.add('$invalidCount Backup(s) sind ungültig');
      }
      return ReleaseQualityCheck(
        id: 'local-backup',
        title: 'Lokales Sicherheitsbackup',
        detail: '${reasons.join(' und ')}.',
        state: ReleaseCheckState.attention,
      );
    }

    return ReleaseQualityCheck(
      id: 'local-backup',
      title: 'Lokales Sicherheitsbackup',
      detail: age == 0
          ? 'Ein gültiges Backup von heute ist vorhanden.'
          : 'Ein gültiges Backup von vor $age Tag(en) ist vorhanden.',
      state: ReleaseCheckState.ready,
    );
  }
}
