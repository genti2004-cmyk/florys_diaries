import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/security/domain/app_lock_settings.dart';

void main() {
  test('json round trip preserves lock settings', () {
    const settings = AppLockSettings(
      enabled: true,
      pinSalt: 'salt',
      pinHash: 'hash',
      biometricEnabled: true,
      documentsOnly: true,
      lockAfterMinutes: 5,
    );

    final restored = AppLockSettings.fromJson(settings.toJson());

    expect(restored.enabled, isTrue);
    expect(restored.hasPin, isTrue);
    expect(restored.biometricEnabled, isTrue);
    expect(restored.documentsOnly, isTrue);
    expect(restored.lockAfterMinutes, 5);
  });

  test('invalid lock delay falls back to immediate locking', () {
    final restored = AppLockSettings.fromJson(const {
      'enabled': true,
      'pinSalt': 'salt',
      'pinHash': 'hash',
      'lockAfterMinutes': 99,
    });

    expect(restored.lockAfterMinutes, 0);
  });
}
