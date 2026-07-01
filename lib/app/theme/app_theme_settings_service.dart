import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'app_theme_preset.dart';

typedef AppThemeSettingsDirectoryProvider = Future<Directory> Function();

class AppThemeSettingsService {
  const AppThemeSettingsService({this.directoryProvider});

  static const String _fileName = 'florys_diaries_theme.json';

  final AppThemeSettingsDirectoryProvider? directoryProvider;

  Future<AppThemePreset> load() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) {
        return AppThemePreset.standard;
      }

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return AppThemePreset.standard;
      }
      return appThemePresetFromName(decoded['preset']?.toString());
    } catch (_) {
      return AppThemePreset.standard;
    }
  }

  Future<void> save(AppThemePreset preset) async {
    final file = await _settingsFile();
    final temporary = File('${file.path}.tmp');
    final content = const JsonEncoder.withIndent(' ').convert({
      'preset': preset.name,
    });

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    if (await temporary.exists()) {
      await temporary.delete();
    }
    await temporary.writeAsString(content, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await temporary.rename(file.path);
  }

  Future<File> _settingsFile() async {
    final provider = directoryProvider;
    final directory = provider == null
        ? await getApplicationSupportDirectory()
        : await provider();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }
}
