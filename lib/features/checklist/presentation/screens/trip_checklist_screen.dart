import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/features/checklist/application/travel_checklist_suggestion_service.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';
import 'package:florys_diaries/features/checklist/presentation/screens/checklist_item_editor_screen.dart';
import 'package:florys_diaries/features/checklist/presentation/widgets/checklist_item_card.dart';
import 'package:florys_diaries/features/checklist/presentation/widgets/checklist_progress_card.dart';
import 'package:florys_diaries/features/checklist/presentation/widgets/checklist_suggestions_sheet.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripChecklistScreen extends StatefulWidget {
  const TripChecklistScreen({required this.trip, super.key});

  final Trip trip;

  @override
  State<TripChecklistScreen> createState() => _TripChecklistScreenState();
}

class _TripChecklistScreenState extends State<TripChecklistScreen> {
  static const _suggestionService = TravelChecklistSuggestionService();

  TripChecklistCategory? _categoryFilter;

  Future<void> _openEditor(Trip trip, {TripChecklistItem? item}) async {
    final store = TripStoreScope.of(context);
    final result = await Navigator.of(context).push<ChecklistItemEditorResult>(
      MaterialPageRoute<ChecklistItemEditorResult>(
        builder: (_) => ChecklistItemEditorScreen(
          tripStartDate: trip.startDate,
          item: item,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final items = List<TripChecklistItem>.from(trip.checklistItems);
    if (result.delete) {
      items.removeWhere((entry) => entry.id == result.item.id);
    } else {
      final index = items.indexWhere((entry) => entry.id == result.item.id);
      if (index == -1) {
        items.add(result.item);
      } else {
        items[index] = result.item;
      }
    }
    await store.updateTrip(trip.copyWith(checklistItems: items));
  }

  Future<void> _toggleItem(
    Trip trip,
    TripChecklistItem item,
    bool completed,
  ) async {
    final store = TripStoreScope.of(context);
    final items = trip.checklistItems
        .map(
          (entry) => entry.id == item.id
              ? entry.copyWith(isCompleted: completed)
              : entry,
        )
        .toList(growable: false);
    await store.updateTrip(trip.copyWith(checklistItems: items));
  }

  Future<void> _addSuggestions(Trip trip) async {
    final suggestions = _suggestionService.suggestionsFor(trip);
    if (suggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktuell gibt es keine neuen passenden Vorschläge.'),
        ),
      );
      return;
    }

    final selected = await showChecklistSuggestionsSheet(
      context: context,
      suggestions: suggestions,
    );
    if (!mounted || selected == null || selected.isEmpty) {
      return;
    }

    final store = TripStoreScope.of(context);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final newItems = <TripChecklistItem>[];
    for (var index = 0; index < selected.length; index++) {
      newItems.add(selected[index].toItem('${timestamp + index}'));
    }
    final items = List<TripChecklistItem>.from(trip.checklistItems)
      ..addAll(newItems);
    await store.updateTrip(trip.copyWith(checklistItems: items));

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selected.length == 1
              ? '1 Vorschlag wurde hinzugefügt.'
              : '${selected.length} Vorschläge wurden hinzugefügt.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final trip = store.trips.firstWhere(
      (item) => item.id == widget.trip.id,
      orElse: () => widget.trip,
    );
    final suggestions = _suggestionService.suggestionsFor(trip);
    final visibleItems = _visibleItems(trip.checklistItems);

    return Scaffold(
      appBar: AppBar(title: Text('Checkliste: ${trip.destination}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(trip),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Aufgabe'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            ChecklistProgressCard(items: trip.checklistItems),
            const SizedBox(height: 14),
            AppSectionCard(
              icon: Icons.auto_awesome_rounded,
              title: suggestions.isEmpty
                  ? 'Vorbereitung geprüft'
                  : '${suggestions.length} passende Vorschläge',
              subtitle: suggestions.isEmpty
                  ? 'Für die vorhandenen Reisedaten gibt es aktuell nichts Neues.'
                  : 'Aus Reisedatum, Dokumenten und offenen Vorbereitungen.',
              trailing: suggestions.isEmpty
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.sage,
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: suggestions.isEmpty ? null : () => _addSuggestions(trip),
            ),
            const SizedBox(height: 16),
            _CategoryFilter(
              selected: _categoryFilter,
              onChanged: (value) => setState(() => _categoryFilter = value),
            ),
            const SizedBox(height: 14),
            if (visibleItems.isEmpty)
              _EmptyChecklistState(
                hasAnyItems: trip.checklistItems.isNotEmpty,
                onAdd: () => _openEditor(trip),
              )
            else
              ...visibleItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChecklistItemCard(
                    item: item,
                    onToggle: (value) => _toggleItem(trip, item, value),
                    onTap: () => _openEditor(trip, item: item),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<TripChecklistItem> _visibleItems(List<TripChecklistItem> source) {
    final items = source
        .where(
          (item) => _categoryFilter == null || item.category == _categoryFilter,
        )
        .toList();
    items.sort((left, right) {
      if (left.isCompleted != right.isCompleted) {
        return left.isCompleted ? 1 : -1;
      }
      final priority = right.priority.weight.compareTo(left.priority.weight);
      if (priority != 0) {
        return priority;
      }
      final leftDate = left.dueDate ?? DateTime(2200);
      final rightDate = right.dueDate ?? DateTime(2200);
      return leftDate.compareTo(rightDate);
    });
    return items;
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onChanged});

  final TripChecklistCategory? selected;
  final ValueChanged<TripChecklistCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Alle'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...TripChecklistCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(category.icon, size: 17),
                label: Text(category.label),
                selected: selected == category,
                onSelected: (_) => onChanged(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChecklistState extends StatelessWidget {
  const _EmptyChecklistState({required this.hasAnyItems, required this.onAdd});

  final bool hasAnyItems;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.checklist_rounded,
              size: 46,
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              hasAnyItems
                  ? 'Keine Aufgabe in dieser Kategorie'
                  : 'Checkliste starten',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyItems
                  ? 'Wähle eine andere Kategorie oder lege eine neue Aufgabe an.'
                  : 'Lege eigene Aufgaben an oder übernimm passende Vorschläge.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Aufgabe hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
