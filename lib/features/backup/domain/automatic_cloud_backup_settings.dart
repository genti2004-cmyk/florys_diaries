class AutomaticCloudBackupSettings {
  const AutomaticCloudBackupSettings({
    required this.enabled,
    required this.intervalDays,
    required this.retentionLimit,
    this.lastSuccessfulBackupAt,
    this.lastCheckedAt,
    this.lastContentFingerprint,
  });

  static const int defaultIntervalDays = 3;
  static const int defaultRetentionLimit = 5;
  static const List<int> allowedIntervalDays = <int>[1, 3, 7];
  static const List<int> allowedRetentionLimits = <int>[3, 5, 10];

  static const AutomaticCloudBackupSettings defaults =
      AutomaticCloudBackupSettings(
    enabled: false,
    intervalDays: defaultIntervalDays,
    retentionLimit: defaultRetentionLimit,
  );

  final bool enabled;
  final int intervalDays;
  final int retentionLimit;
  final DateTime? lastSuccessfulBackupAt;
  final DateTime? lastCheckedAt;
  final String? lastContentFingerprint;

  Duration get interval => Duration(days: intervalDays);

  DateTime? get scheduleAnchor => lastCheckedAt ?? lastSuccessfulBackupAt;

  bool isDueAt(DateTime now) {
    if (!enabled) {
      return false;
    }

    final anchor = scheduleAnchor;
    if (anchor == null) {
      return true;
    }

    final elapsed = now.toUtc().difference(anchor.toUtc());
    return elapsed.isNegative || elapsed >= interval;
  }

  DateTime? get nextBackupAt {
    final anchor = scheduleAnchor;
    if (!enabled || anchor == null) {
      return null;
    }
    return anchor.add(interval);
  }

  AutomaticCloudBackupSettings copyWith({
    bool? enabled,
    int? intervalDays,
    int? retentionLimit,
    DateTime? lastSuccessfulBackupAt,
    DateTime? lastCheckedAt,
    String? lastContentFingerprint,
    bool clearLastSuccessfulBackupAt = false,
    bool clearLastCheckedAt = false,
    bool clearLastContentFingerprint = false,
  }) {
    return AutomaticCloudBackupSettings(
      enabled: enabled ?? this.enabled,
      intervalDays: _validInterval(intervalDays ?? this.intervalDays),
      retentionLimit: _validRetention(
        retentionLimit ?? this.retentionLimit,
      ),
      lastSuccessfulBackupAt: clearLastSuccessfulBackupAt
          ? null
          : lastSuccessfulBackupAt ?? this.lastSuccessfulBackupAt,
      lastCheckedAt:
          clearLastCheckedAt ? null : lastCheckedAt ?? this.lastCheckedAt,
      lastContentFingerprint: clearLastContentFingerprint
          ? null
          : lastContentFingerprint ?? this.lastContentFingerprint,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'intervalDays': intervalDays,
      'retentionLimit': retentionLimit,
      'lastSuccessfulBackupAt':
          lastSuccessfulBackupAt?.toUtc().toIso8601String(),
      'lastCheckedAt': lastCheckedAt?.toUtc().toIso8601String(),
      'lastContentFingerprint': lastContentFingerprint,
    };
  }

  factory AutomaticCloudBackupSettings.fromJson(
    Map<String, dynamic> json,
  ) {
    final fingerprint = json['lastContentFingerprint']?.toString().trim();
    return AutomaticCloudBackupSettings(
      enabled: json['enabled'] == true,
      intervalDays: _validInterval(
        int.tryParse(json['intervalDays']?.toString() ?? '') ??
            defaultIntervalDays,
      ),
      retentionLimit: _validRetention(
        int.tryParse(json['retentionLimit']?.toString() ?? '') ??
            defaultRetentionLimit,
      ),
      lastSuccessfulBackupAt: DateTime.tryParse(
        json['lastSuccessfulBackupAt']?.toString() ?? '',
      ),
      lastCheckedAt: DateTime.tryParse(
        json['lastCheckedAt']?.toString() ?? '',
      ),
      lastContentFingerprint:
          fingerprint == null || fingerprint.isEmpty ? null : fingerprint,
    );
  }

  static int _validInterval(int value) {
    return allowedIntervalDays.contains(value)
        ? value
        : defaultIntervalDays;
  }

  static int _validRetention(int value) {
    return allowedRetentionLimits.contains(value)
        ? value
        : defaultRetentionLimit;
  }
}
