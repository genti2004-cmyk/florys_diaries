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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                labelText: 'Dokumente durchsuchen',
                hintText: 'Titel, Datei, Kategorie oder Notiz',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: query.categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kategorie',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: TripDocumentQuery.allCategoriesId,
                        child: Text('Alle'),
                      ),
                      ...DocumentCategories.values.map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onCategoryChanged(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<DocumentSortMode>(
                    initialValue: query.sortMode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sortierung',
                      prefixIcon: Icon(Icons.sort_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: DocumentSortMode.newest,
                        child: Text('Neueste'),
                      ),
                      DropdownMenuItem(
                        value: DocumentSortMode.oldest,
                        child: Text('Älteste'),
                      ),
                      DropdownMenuItem(
                        value: DocumentSortMode.title,
                        child: Text('Titel A–Z'),
                      ),
                      DropdownMenuItem(
                        value: DocumentSortMode.category,
                        child: Text('Kategorie'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onSortChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                value: query.favoritesOnly,
                onChanged: onFavoritesChanged,
                title: const Text('Nur Favoriten'),
                secondary: const Icon(Icons.star_border_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
