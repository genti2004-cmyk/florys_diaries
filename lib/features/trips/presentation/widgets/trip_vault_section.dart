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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Travel Vault',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tickets, Buchungen, Nachweise und wichtige Dateien.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: onAddDocument,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Dokument'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _VaultOverview(
          documentCount: trip.documentCount,
          favoriteCount: favoriteCount,
          photoCount: _photoDocumentCount(trip.documents),
        ),
        const SizedBox(height: 14),
        if (trip.documents.isNotEmpty) ...[
          TripDocumentToolsCard(
            controller: searchController,
            query: query,
            onSearchChanged: onSearchChanged,
            onCategoryChanged: onCategoryChanged,
            onSortChanged: onSortChanged,
            onFavoritesChanged: onFavoritesChanged,
          ),
          const SizedBox(height: 12),
        ],
        if (trip.documents.isEmpty)
          _EmptyVaultCard(onAddDocument: onAddDocument)
        else if (visibleDocuments.isEmpty)
          _NoResultsCard(onResetFilters: onResetFilters)
        else
          ...visibleDocuments.map(
            (document) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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

class _VaultOverview extends StatelessWidget {
  const _VaultOverview({
    required this.documentCount,
    required this.favoriteCount,
    required this.photoCount,
  });

  final int documentCount;
  final int favoriteCount;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101F36), Color(0xFF1C3E6F)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160D1728),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _VaultMetric(
              icon: Icons.description_outlined,
              value: '$documentCount',
              label: 'Dokumente',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _VaultMetric(
              icon: Icons.star_outline_rounded,
              value: '$favoriteCount',
              label: 'Favoriten',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _VaultMetric(
              icon: Icons.photo_library_outlined,
              value: '$photoCount',
              label: 'Fotos',
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultMetric extends StatelessWidget {
  const _VaultMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVaultCard extends StatelessWidget {
  const _EmptyVaultCard({required this.onAddDocument});

  final VoidCallback onAddDocument;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Noch keine Reiseunterlagen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Füge Flugtickets, Hotelbuchungen, Bahnfahrten oder wichtige Nachweise hinzu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAddDocument,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Dokument hinzufügen'),
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
              'Keine passenden Dokumente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ändere Suche, Kategorie oder Favoritenfilter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onResetFilters,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Filter zurücksetzen'),
            ),
          ],
        ),
      ),
    );
  }
}
