import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';

import 'package:florys_diaries/features/security/data/app_lock_settings_service.dart';
import 'package:florys_diaries/features/security/domain/app_lock_settings.dart';

class AppLockController extends ChangeNotifier {
  AppLockController({
    AppLockSettingsService service = const AppLockSettingsService(),
    LocalAuthentication? localAuthentication,
  }) : _service = service,
       _localAuthentication = localAuthentication ?? LocalAuthentication();

  final AppLockSettingsService _service;
  final LocalAuthentication _localAuthentication;

  AppLockSettings _settings = AppLockSettings.disabled;
  bool _isLoading = true;
  bool _isLocked = false;
  DateTime? _backgroundedAt;
  bool _isDisposed = false;

  AppLockSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isLocked => _isLocked;
  bool get protectsDocuments =>
      _settings.enabled && _settings.documentsOnly;

  Future<void> load() async {
    try {
      _settings = await _service.load();
      _isLocked = _settings.enabled && !_settings.documentsOnly;
    } catch (error) {
      debugPrint('App-Schutz konnte nicht geladen werden: $error');
      _settings = AppLockSettings.disabled;
      _isLocked = false;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> configure({
    required String pin,
    required bool biometricEnabled,
    required bool documentsOnly,
    required int lockAfterMinutes,
  }) async {
    final normalizedPin = pin.trim();
    if (!RegExp(r'^\d{4,8}$').hasMatch(normalizedPin)) {
      throw const FormatException('Die PIN muss aus 4 bis 8 Ziffern bestehen.');
    }
    final salt = _createSalt();
    _settings = AppLockSettings(
      enabled: true,
      pinSalt: salt,
      pinHash: _hash(normalizedPin, salt),
      biometricEnabled: biometricEnabled,
      documentsOnly: documentsOnly,
      lockAfterMinutes: lockAfterMinutes,
    );
    await _service.save(_settings);
    _isLocked = false;
    _notifyListeners();
  }

  Future<void> updatePreferences({
    required bool biometricEnabled,
    required bool documentsOnly,
    required int lockAfterMinutes,
  }) async {
    if (!_settings.enabled) {
      return;
    }
    _settings = _settings.copyWith(
      biometricEnabled: biometricEnabled,
      documentsOnly: documentsOnly,
      lockAfterMinutes: lockAfterMinutes,
    );
    await _service.save(_settings);
    _isLocked = _settings.enabled && !_settings.documentsOnly && _isLocked;
    _notifyListeners();
  }

  Future<void> disable() async {
    _settings = AppLockSettings.disabled;
    _isLocked = false;
    await _service.save(_settings);
    _notifyListeners();
  }

  bool authenticatePin(String pin) {
    if (!_settings.enabled || !_settings.hasPin) {
      return true;
    }
    final actual = _hash(pin.trim(), _settings.pinSalt);
    final expected = _settings.pinHash;
    if (actual.length != expected.length) {
      return false;
    }
    var difference = 0;
    for (var index = 0; index < actual.length; index++) {
      difference |= actual.codeUnitAt(index) ^ expected.codeUnitAt(index);
    }
    if (difference == 0) {
      _isLocked = false;
      _notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> authenticateBiometric() async {
    if (!_settings.enabled || !_settings.biometricEnabled) {
      return false;
    }
    try {
      final supported = await _localAuthentication.isDeviceSupported();
      final canCheck = await _localAuthentication.canCheckBiometrics;
      if (!supported && !canCheck) {
        return false;
      }
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: 'FlorysDiaries entsperren',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );
      if (authenticated) {
        _isLocked = false;
        _notifyListeners();
      }
      return authenticated;
    } catch (error) {
      debugPrint('Biometrische Entsperrung fehlgeschlagen: $error');
      return false;
    }
  }

  void lock() {
    if (_settings.enabled && !_settings.documentsOnly && !_isLocked) {
      _isLocked = true;
      _notifyListeners();
    }
  }

  void handleLifecycle(AppLifecycleState state) {
    if (!_settings.enabled || _settings.documentsOnly) {
      return;
    }
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _backgroundedAt ??= DateTime.now();
        if (_settings.lockAfterMinutes == 0) {
          lock();
        }
        break;
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (backgroundedAt == null) {
          return;
        }
        final elapsed = DateTime.now().difference(backgroundedAt);
        if (elapsed >= Duration(minutes: _settings.lockAfterMinutes)) {
          lock();
        }
        break;
    }
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  static String _createSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }
}
