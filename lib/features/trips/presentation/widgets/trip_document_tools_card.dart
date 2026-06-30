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
    super.key,
  });

  final TextEditingController controller;
  final TripDocumentQuery query;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<DocumentSortMode> onSortChanged;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Dokumente durchsuchen',
                suffixIcon: IconButton(
                  tooltip: 'Filter und Sortierung',
                  onPressed: () => _openFilters(context),
                  icon: Badge(
                    isLabelVisible: _hasActiveFilter,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
              ),
            ),
            if (_hasActiveFilter) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (query.categoryId != TripDocumentQuery.allCategoriesId)
                    _ActiveFilterChip(
                      icon: Icons.category_outlined,
                      label: DocumentCategories.byId(query.categoryId).label,
                    ),
                  if (query.favoritesOnly)
                    const _ActiveFilterChip(
                      icon: Icons.star_rounded,
                      label: 'Nur Favoriten',
                    ),
                  _ActiveFilterChip(
                    icon: Icons.sort_rounded,
                    label: _sortLabel(query.sortMode),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasActiveFilter {
    return query.categoryId != TripDocumentQuery.allCategoriesId ||
        query.favoritesOnly ||
        query.sortMode != DocumentSortMode.newest;
  }

  Future<void> _openFilters(BuildContext context) async {
    var categoryId = query.categoryId;
    var sortMode = query.sortMode;
    var favoritesOnly = query.favoritesOnly;

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
                      'Dokumente filtern',
                      style: Theme.of(context).textTheme.titleLarge,
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
                        if (value == null) {
                          return;
                        }
                        setSheetState(() => categoryId = value);
                        onCategoryChanged(value);
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
                        if (value == null) {
                          return;
                        }
                        setSheetState(() => sortMode = value);
                        onSortChanged(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: SwitchListTile.adaptive(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        value: favoritesOnly,
                        onChanged: (value) {
                          setSheetState(() => favoritesOnly = value);
                          onFavoritesChanged(value);
                        },
                        title: const Text('Nur Favoriten'),
                        secondary: const Icon(Icons.star_border_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Fertig'),
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

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
