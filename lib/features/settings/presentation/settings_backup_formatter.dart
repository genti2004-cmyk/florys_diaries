import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';

abstract final class SettingsBackupFormatter {
  static String savedBackupSummary(
    AppBackupCreateResult result,
    String savedName,
    String providerName,
  ) {
    return 'Gespeichert auf $providerName: $savedName · '
        '${result.tripCount} Reisen, ${result.fileCount} Dateien, '
        '${formatBytes(result.sizeBytes)}';
  }

  static String selectedBackupSummary(
    String fileName,
    AppBackupInspectionResult inspection,
  ) {
    return 'Geprüft: $fileName · Backup vom '
        '${formatDateTime(inspection.backupCreatedAt.toLocal())} · '
        '${inspection.tripCount} Reisen, '
        '${inspection.countryCount} Länder, '
        '${inspection.fileCount} Dateien';
  }

  static String restoreSummary(AppBackupRestoreResult result) {
    return 'Wiederhergestellt: ${result.tripCount} Reisen und '
        '${result.fileCount} Dateien · Backup vom '
        '${formatDateTime(result.backupCreatedAt.toLocal())}';
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}, '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
