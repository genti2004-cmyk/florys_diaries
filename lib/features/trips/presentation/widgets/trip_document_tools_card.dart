import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/documents/application/trip_document_query.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';

class TripDocumentToolsCard extends StatelessWidget {
  const TripDocumentToolsCard({
    required this.controller,
    required this.query,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onFavoritesChanged,
    required this.onResetFilters,
    super.key,
  });

  final TextEditingController controller;
  final TripDocumentQuery query;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<DocumentSortMode> onSortChanged;
  final ValueChanged<bool> onFavoritesChanged;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Dokument suchen',
                      suffixIcon: query.searchText.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Suche löschen',
                              onPressed: () {
                                controller.clear();
                                onSearchChanged('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ToolButton(
                  tooltip: query.favoritesOnly
                      ? 'Alle Dokumente anzeigen'
                      : 'Nur Favoriten anzeigen',
                  selected: query.favoritesOnly,
                  icon: query.favoritesOnly
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  onPressed: () => onFavoritesChanged(!query.favoritesOnly),
                ),
                const SizedBox(width: 8),
                _ToolButton(
                  tooltip: 'Filtern und sortieren',
                  selected: _hasAdvancedFilter,
                  showBadge: _hasAdvancedFilter,
                  icon: Icons.tune_rounded,
                  onPressed: () => _openFilters(context),
                ),
              ],
            ),
            if (_hasAnyFilter) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _filterSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onResetFilters,
                    child: const Text('Zurücksetzen'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasAdvancedFilter {
    return query.categoryId != TripDocumentQuery.allCategoriesId ||
        query.sortMode != DocumentSortMode.newest;
  }

  bool get _hasAnyFilter {
    return query.searchText.trim().isNotEmpty ||
        query.favoritesOnly ||
        _hasAdvancedFilter;
  }

  String get _filterSummary {
    final parts = <String>[];
    if (query.searchText.trim().isNotEmpty) {
      parts.add('Suche: „${query.searchText.trim()}“');
    }
    if (query.categoryId != TripDocumentQuery.allCategoriesId) {
      parts.add(DocumentCategories.byId(query.categoryId).label);
    }
    if (query.favoritesOnly) {
      parts.add('Nur Favoriten');
    }
    if (query.sortMode != DocumentSortMode.newest) {
      parts.add(_sortLabel(query.sortMode));
    }
    return parts.join(' · ');
  }

  Future<void> _openFilters(BuildContext context) async {
    var categoryId = query.categoryId;
    var sortMode = query.sortMode;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  18 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Dokumente ordnen',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Wähle eine Kategorie und die gewünschte Reihenfolge.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kategorie',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: TripDocumentQuery.allCategoriesId,
                          child: Text('Alle Kategorien'),
                        ),
                        ...DocumentCategories.values.map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.label),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => categoryId = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DocumentSortMode>(
                      initialValue: sortMode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sortierung',
                        prefixIcon: Icon(Icons.sort_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: DocumentSortMode.newest,
                          child: Text('Neueste zuerst'),
                        ),
                        DropdownMenuItem(
                          value: DocumentSortMode.oldest,
                          child: Text('Älteste zuerst'),
                        ),
                        DropdownMenuItem(
                          value: DocumentSortMode.title,
                          child: Text('Titel A–Z'),
                        ),
                        DropdownMenuItem(
                          value: DocumentSortMode.category,
                          child: Text('Nach Kategorie'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => sortMode = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              onCategoryChanged(
                                TripDocumentQuery.allCategoriesId,
                              );
                              onSortChanged(DocumentSortMode.newest);
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Standard'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              onCategoryChanged(categoryId);
                              onSortChanged(sortMode);
                              Navigator.of(sheetContext).pop();
                            },
                            child: const Text('Übernehmen'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _sortLabel(DocumentSortMode mode) {
    switch (mode) {
      case DocumentSortMode.newest:
        return 'Neueste zuerst';
      case DocumentSortMode.oldest:
        return 'Älteste zuerst';
      case DocumentSortMode.title:
        return 'Titel A–Z';
      case DocumentSortMode.category:
        return 'Nach Kategorie';
    }
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tooltip,
    required this.selected,
    required this.icon,
    required this.onPressed,
    this.showBadge = false,
  });

  final String tooltip;
  final bool selected;
  final IconData icon;
  final VoidCallback onPressed;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Badge(
                isLabelVisible: showBadge,
                child: Icon(
                  icon,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
