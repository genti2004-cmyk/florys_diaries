import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';

class AutomaticCloudBackupSettingsService {
  const AutomaticCloudBackupSettingsService();

  static const String _fileName =
      'florys_diaries_automatic_cloud_backup.json';

  Future<AutomaticCloudBackupSettings> load() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return AutomaticCloudBackupSettings.defaults;
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return AutomaticCloudBackupSettings.defaults;
      }

      return AutomaticCloudBackupSettings.fromJson(
        decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    } on FileSystemException {
      return AutomaticCloudBackupSettings.defaults;
    } on FormatException {
      return AutomaticCloudBackupSettings.defaults;
    }
  }

  Future<void> save(AutomaticCloudBackupSettings settings) async {
    final file = await _settingsFile();
    final temporary = File('${file.path}.tmp');
    final encoder = const JsonEncoder.withIndent('  ');

    await temporary.writeAsString(
      encoder.convert(settings.toJson()),
      flush: true,
    );

    if (await file.exists()) {
      await file.delete();
    }
    await temporary.rename(file.path);
  }

  Future<File> _settingsFile() async {
    final directory = await getApplicationSupportDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File(
      '${directory.path}${Platform.pathSeparator}$_fileName',
    );
  }
}
