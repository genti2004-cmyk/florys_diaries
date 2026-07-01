enum BackupIntegrityLevel { structural, sha256 }

extension BackupIntegrityLevelX on BackupIntegrityLevel {
  bool get isCryptographic => this == BackupIntegrityLevel.sha256;

  String get displayName {
    return switch (this) {
      BackupIntegrityLevel.structural => 'Strukturell geprüft',
      BackupIntegrityLevel.sha256 => 'SHA-256-Integrität geprüft',
    };
  }

  String get description {
    return switch (this) {
      BackupIntegrityLevel.structural =>
        'Älteres Backup: Aufbau, Inhalte und Dateigrößen wurden geprüft.',
      BackupIntegrityLevel.sha256 =>
        'Reisedaten und jede archivierte Datei wurden mit SHA-256 auf '
        'Beschädigungen geprüft. Das Backup ist nicht digital signiert.',
    };
  }
}
