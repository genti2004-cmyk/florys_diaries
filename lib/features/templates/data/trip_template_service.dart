import 'dart:convert';
import 'dart:io';

import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/templates/domain/trip_template.dart';

class TripTemplateService {
  const TripTemplateService({this.directoryProvider});

  static const _fileName = 'florys_trip_templates.json';

  final Future<Directory> Function()? directoryProvider;

  Future<List<TripTemplate>> load() async {
    final file = await _file();
    if (!await file.exists()) {
      return const [];
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      throw const FormatException('Die Vorlagendatei ist ungültig.');
    }
    final templates = decoded
        .whereType<Map<String, dynamic>>()
        .map(TripTemplate.fromJson)
        .where(
          (template) =>
              template.id.trim().isNotEmpty &&
              template.name.trim().isNotEmpty &&
              template.sourceTrip.title.trim().isNotEmpty,
        )
        .toList(growable: true)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<TripTemplate>.unmodifiable(templates);
  }

  Future<void> save(List<TripTemplate> templates) async {
    final file = await _file();
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    final temporary = File('${file.path}.tmp');
    final json = const JsonEncoder.withIndent('  ').convert(
      templates.map((template) => template.toJson()).toList(growable: false),
    );
    await temporary.writeAsString(json, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await temporary.rename(file.path);
  }

  Future<void> add(TripTemplate template) async {
    final sanitized = TripTemplate(
      id: template.id,
      name: template.name,
      createdAt: template.createdAt,
      sourceTrip: template.sourceTrip.copyWith(
        documents: const [],
        albumEntries: const [],
        photoCount: 0,
        budgetExpenses: template.sourceTrip.budgetExpenses
            .where((expense) => expense.status == TripExpenseStatus.planned)
            .toList(growable: false),
      ),
    );
    final templates = List<TripTemplate>.from(await load())
      ..removeWhere((item) => item.id == sanitized.id)
      ..insert(0, sanitized);
    await save(templates);
  }

  Future<void> delete(String id) async {
    final templates = List<TripTemplate>.from(await load())
      ..removeWhere((item) => item.id == id);
    await save(templates);
  }

  Future<File> _file() async {
    final directory = directoryProvider == null
        ? await const TravelFileService().rootDirectory()
        : await directoryProvider!();
    return File('${directory.path}/$_fileName');
  }
}
