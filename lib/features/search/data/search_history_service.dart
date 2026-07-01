import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

typedef SearchHistoryDirectoryProvider = Future<Directory> Function();

class SearchHistoryService {
  const SearchHistoryService({
    this.directoryProvider,
    this.maxItems = 8,
  });

  final SearchHistoryDirectoryProvider? directoryProvider;
  final int maxItems;

  Future<List<String>> load() async {
    try {
      final file = await _historyFile();
      if (!await file.exists()) {
        return const <String>[];
      }

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        return const <String>[];
      }

      final values = <String>[];
      final seen = <String>{};
      for (final item in decoded.whereType<String>()) {
        final value = item.trim();
        final key = value.toLowerCase();
        if (value.isEmpty || !seen.add(key)) {
          continue;
        }
        values.add(value);
        if (values.length >= maxItems) {
          break;
        }
      }
      return List<String>.unmodifiable(values);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<List<String>> add(String query) async {
    final value = query.trim();
    if (value.isEmpty) {
      return load();
    }

    final current = await load();
    final normalized = value.toLowerCase();
    final next = <String>[
      value,
      ...current.where((item) => item.toLowerCase() != normalized),
    ].take(maxItems).toList(growable: false);
    await _write(next);
    return List<String>.unmodifiable(next);
  }

  Future<void> clear() async {
    try {
      final file = await _historyFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // A failed history cleanup must never block the search feature.
    }
  }

  Future<void> _write(List<String> values) async {
    try {
      final file = await _historyFile();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(jsonEncode(values), flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await temporary.rename(file.path);
    } catch (_) {
      // Search works without persisted history, so storage failures stay soft.
    }
  }

  Future<File> _historyFile() async {
    final provider = directoryProvider ?? getApplicationDocumentsDirectory;
    final directory = await provider();
    return File(
      '${directory.path}${Platform.pathSeparator}florys_search_history.json',
    );
  }
}
