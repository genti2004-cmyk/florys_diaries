import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/security/application/app_lock_controller.dart';
import 'package:florys_diaries/features/security/data/app_lock_settings_service.dart';

void main() {
  test('stores a salted PIN and validates it without clear text storage', () async {
    final directory = await Directory.systemTemp.createTemp('florys-lock-');
    addTearDown(() => directory.delete(recursive: true));
    final service = AppLockSettingsService(
      directoryProvider: () async => directory,
    );
    final controller = AppLockController(service: service);
    addTearDown(controller.dispose);

    await controller.load();
    await controller.configure(
      pin: '2580',
      biometricEnabled: false,
      documentsOnly: false,
      lockAfterMinutes: 0,
    );

    expect(controller.settings.pinHash, isNot('2580'));
    controller.lock();
    expect(controller.isLocked, isTrue);
    expect(controller.authenticatePin('1111'), isFalse);
    expect(controller.authenticatePin('2580'), isTrue);
    expect(controller.isLocked, isFalse);

    final restored = await service.load();
    expect(restored.pinHash, controller.settings.pinHash);
  });
}
