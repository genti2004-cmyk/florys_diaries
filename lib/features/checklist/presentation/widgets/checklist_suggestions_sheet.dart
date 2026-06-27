import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/checklist/application/travel_checklist_suggestion_service.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';

Future<List<TripChecklistSuggestion>?> showChecklistSuggestionsSheet({
  required BuildContext context,
  required List<TripChecklistSuggestion> suggestions,
}) {
  return showModalBottomSheet<List<TripChecklistSuggestion>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ChecklistSuggestionsSheet(suggestions: suggestions),
  );
}

class _ChecklistSuggestionsSheet extends StatefulWidget {
  const _ChecklistSuggestionsSheet({required this.suggestions});

  final List<TripChecklistSuggestion> suggestions;

  @override
  State<_ChecklistSuggestionsSheet> createState() =>
      _ChecklistSuggestionsSheetState();
}

class _ChecklistSuggestionsSheetState
    extends State<_ChecklistSuggestionsSheet> {
  late final Set<String> _selectedKeys;

  @override
  void initState() {
    super.initState();
    _selectedKeys = widget.suggestions.map((item) => item.sourceKey).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Intelligente Vorschläge',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Die Vorschläge entstehen lokal aus Reisedatum, Dokumenten und vorhandenen Aufgaben.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.suggestions.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = widget.suggestions[index];
                    final selected = _selectedKeys.contains(
                      suggestion.sourceKey,
                    );
                    return CheckboxListTile(
                      value: selected,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _selectedKeys.add(suggestion.sourceKey);
                          } else {
                            _selectedKeys.remove(suggestion.sourceKey);
                          }
                        });
                      },
                      secondary: Icon(
                        suggestion.category.icon,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        suggestion.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${suggestion.category.label} · ${suggestion.priority.label} · '
                        '${_formatDate(suggestion.dueDate)}',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selectedKeys.isEmpty
                      ? null
                      : () {
                          final selected = widget.suggestions
                              .where(
                                (suggestion) => _selectedKeys.contains(
                                  suggestion.sourceKey,
                                ),
                              )
                              .toList(growable: false);
                          Navigator.of(context).pop(selected);
                        },
                  icon: const Icon(Icons.add_task_rounded),
                  label: Text(
                    _selectedKeys.length == 1
                        ? '1 Vorschlag hinzufügen'
                        : '${_selectedKeys.length} Vorschläge hinzufügen',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
