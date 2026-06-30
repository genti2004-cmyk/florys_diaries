enum DataSafetyState { healthy, warning, critical }

class DataSafetyReport {
  const DataSafetyReport({
    required this.checkedAt,
    required this.tripCount,
    required this.documentCount,
    required this.managedFileCount,
    required this.missingFileCount,
    required this.orphanFileCount,
    required this.invalidReferenceCount,
    required this.validBackupCount,
    required this.invalidBackupCount,
    required this.newestValidBackupAt,
  });

  final DateTime checkedAt;
  final int tripCount;
  final int documentCount;
  final int managedFileCount;
  final int missingFileCount;
  final int orphanFileCount;
  final int invalidReferenceCount;
  final int validBackupCount;
  final int invalidBackupCount;
  final DateTime? newestValidBackupAt;

  bool get hasRecentBackup {
    final newest = newestValidBackupAt;
    if (newest == null) {
      return false;
    }
    return checkedAt.difference(newest).inDays <= 7;
  }

  DataSafetyState get state {
    if (missingFileCount > 0 || invalidReferenceCount > 0) {
      return DataSafetyState.critical;
    }
    if (orphanFileCount > 0 ||
        invalidBackupCount > 0 ||
        validBackupCount == 0 ||
        !hasRecentBackup) {
      return DataSafetyState.warning;
    }
    return DataSafetyState.healthy;
  }

  int get issueCount {
    var count = missingFileCount + orphanFileCount + invalidReferenceCount;
    if (invalidBackupCount > 0) {
      count += invalidBackupCount;
    }
    if (validBackupCount == 0 || !hasRecentBackup) {
      count += 1;
    }
    return count;
  }
}
