import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:florys_diaries/features/security/domain/app_lock_settings.dart';

class AppLockSettingsService {
  const AppLockSettingsService({this.directoryProvider});

  static const _fileName = 'florys_app_lock.json';
  final Future<Directory> Function()? directoryProvider;

  Future<AppLockSettings> load() async {
    final file = await _file();
    if (!await file.exists()) {
      return AppLockSettings.disabled;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return AppLockSettings.disabled;
      }
      final settings = AppLockSettings.fromJson(decoded);
      return settings.enabled && !settings.hasPin
          ? AppLockSettings.disabled
          : settings;
    } catch (_) {
      return AppLockSettings.disabled;
    }
  }

  Future<void> save(AppLockSettings settings) async {
    final file = await _file();
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings.toJson()),
      flush: true,
    );
    if (await file.exists()) {
      await file.delete();
    }
    await temporary.rename(file.path);
  }

  Future<File> _file() async {
    final directory = directoryProvider == null
        ? await getApplicationDocumentsDirectory()
        : await directoryProvider!();
    return File('${directory.path}/$_fileName');
  }
}
