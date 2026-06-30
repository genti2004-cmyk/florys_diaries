import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/documents/application/trip_document_query.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/documents/presentation/widgets/travel_document_card.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_document_tools_card.dart';

class TripVaultSection extends StatelessWidget {
  const TripVaultSection({
    required this.trip,
    required this.visibleDocuments,
    required this.searchController,
    required this.query,
    required this.onAddDocument,
    required this.onDocumentTap,
    required this.onFavoriteToggle,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onFavoritesChanged,
    required this.onResetFilters,
    super.key,
  });

  final Trip trip;
  final List<TravelDocument> visibleDocuments;
  final TextEditingController searchController;
  final TripDocumentQuery query;
  final VoidCallback onAddDocument;
  final ValueChanged<TravelDocument> onDocumentTap;
  final ValueChanged<TravelDocument> onFavoriteToggle;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<DocumentSortMode> onSortChanged;
  final ValueChanged<bool> onFavoritesChanged;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final favoriteCount = trip.documents
        .where((document) => document.isFavorite)
        .length;
    final photoCount = _photoDocumentCount(trip.documents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocumentsOverviewCard(
          documentCount: trip.documentCount,
          photoCount: photoCount,
          favoriteCount: favoriteCount,
          onAddDocument: onAddDocument,
        ),
        if (trip.documents.isNotEmpty) ...[
          const SizedBox(height: 14),
          TripDocumentToolsCard(
            controller: searchController,
            query: query,
            onSearchChanged: onSearchChanged,
            onCategoryChanged: onCategoryChanged,
            onSortChanged: onSortChanged,
            onFavoritesChanged: onFavoritesChanged,
            onResetFilters: onResetFilters,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gespeicherte Dateien',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${visibleDocuments.length} von ${trip.documents.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (trip.documents.isEmpty)
          _EmptyDocumentsCard(onAddDocument: onAddDocument)
        else if (visibleDocuments.isEmpty)
          _NoResultsCard(onResetFilters: onResetFilters)
        else
          ...visibleDocuments.map(
            (document) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TravelDocumentCard(
                document: document,
                onTap: () => onDocumentTap(document),
                onFavoriteToggle: () => onFavoriteToggle(document),
              ),
            ),
          ),
      ],
    );
  }

  static int _photoDocumentCount(List<TravelDocument> documents) {
    return documents.where((document) {
      final extension = document.fileExtension.trim().toLowerCase();
      return document.categoryId == DocumentCategories.photo.id ||
          const <String>{
            'jpg',
            'jpeg',
            'png',
            'webp',
            'heic',
            'heif',
          }.contains(extension);
    }).length;
  }
}

class _DocumentsOverviewCard extends StatelessWidget {
  const _DocumentsOverviewCard({
    required this.documentCount,
    required this.photoCount,
    required this.favoriteCount,
    required this.onAddDocument,
  });

  final int documentCount;
  final int photoCount;
  final int favoriteCount;
  final VoidCallback onAddDocument;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.folder_copy_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dokumente',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tickets, Buchungen, Nachweise und Reisefotos an einem Ort.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OverviewMetric(
                    value: '$documentCount',
                    label: 'Dateien',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OverviewMetric(
                    value: '$photoCount',
                    label: 'Fotos',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OverviewMetric(
                    value: '$favoriteCount',
                    label: 'Favoriten',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddDocument,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Dokument oder Foto hinzufügen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyDocumentsCard extends StatelessWidget {
  const _EmptyDocumentsCard({required this.onAddDocument});

  final VoidCallback onAddDocument;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.folder_open_rounded,
              size: 42,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Noch keine Dateien gespeichert',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Füge zuerst ein Ticket, eine Buchung, einen Nachweis oder ein Reisefoto hinzu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onAddDocument,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Jetzt hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsCard extends StatelessWidget {
  const _NoResultsCard({required this.onResetFilters});

  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 42,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Keine passenden Dateien',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ändere die Suche oder setze die Filter zurück.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onResetFilters,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Alles anzeigen'),
            ),
          ],
        ),
      ),
    );
  }
}
