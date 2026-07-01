class AppLockSettings {
  const AppLockSettings({
    required this.enabled,
    required this.pinSalt,
    required this.pinHash,
    required this.biometricEnabled,
    required this.documentsOnly,
    required this.lockAfterMinutes,
  });

  static const disabled = AppLockSettings(
    enabled: false,
    pinSalt: '',
    pinHash: '',
    biometricEnabled: false,
    documentsOnly: false,
    lockAfterMinutes: 0,
  );

  final bool enabled;
  final String pinSalt;
  final String pinHash;
  final bool biometricEnabled;
  final bool documentsOnly;
  final int lockAfterMinutes;

  bool get hasPin => pinSalt.isNotEmpty && pinHash.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'pinSalt': pinSalt,
        'pinHash': pinHash,
        'biometricEnabled': biometricEnabled,
        'documentsOnly': documentsOnly,
        'lockAfterMinutes': lockAfterMinutes,
      };

  static AppLockSettings fromJson(Map<String, dynamic> json) {
    final minutes = (json['lockAfterMinutes'] as num?)?.toInt() ?? 0;
    return AppLockSettings(
      enabled: (json['enabled'] as bool?) ?? false,
      pinSalt: (json['pinSalt'] as String?) ?? '',
      pinHash: (json['pinHash'] as String?) ?? '',
      biometricEnabled: (json['biometricEnabled'] as bool?) ?? false,
      documentsOnly: (json['documentsOnly'] as bool?) ?? false,
      lockAfterMinutes: const <int>{0, 1, 5, 15}.contains(minutes)
          ? minutes
          : 0,
    );
  }

  AppLockSettings copyWith({
    bool? enabled,
    String? pinSalt,
    String? pinHash,
    bool? biometricEnabled,
    bool? documentsOnly,
    int? lockAfterMinutes,
  }) {
    return AppLockSettings(
      enabled: enabled ?? this.enabled,
      pinSalt: pinSalt ?? this.pinSalt,
      pinHash: pinHash ?? this.pinHash,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      documentsOnly: documentsOnly ?? this.documentsOnly,
      lockAfterMinutes: lockAfterMinutes ?? this.lockAfterMinutes,
    );
  }
}
