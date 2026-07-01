import 'package:flutter/foundation.dart';

import 'app_theme_preset.dart';
import 'app_theme_settings_service.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController({
    AppThemeSettingsService service = const AppThemeSettingsService(),
  }) : _service = service;

  final AppThemeSettingsService _service;

  AppThemePreset _preset = AppThemePreset.standard;
  bool _isLoaded = false;

  AppThemePreset get preset => _preset;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final loaded = await _service.load();
    _preset = loaded;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPreset(AppThemePreset preset) async {
    if (_preset == preset) {
      return;
    }

    final previous = _preset;
    _preset = preset;
    notifyListeners();

    try {
      await _service.save(preset);
    } catch (_) {
      _preset = previous;
      notifyListeners();
      rethrow;
    }
  }
}
