import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/core/widgets/app_section_title.dart';
import 'package:florys_diaries/features/documents/application/trip_document_query.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionTitle(
          title: 'Travel Vault',
          subtitle: 'Tickets, Buchungen, Screenshots und wichtige Notizen.',
        ),
        _VaultOverview(
          trip: trip,
          favoriteCount: trip.documents
              .where((document) => document.isFavorite)
              .length,
          onAddDocument: onAddDocument,
        ),
        const SizedBox(height: 16),
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
          AppSectionCard(
            icon: Icons.add_circle_outline_rounded,
            title: 'Noch keine Dokumente',
            subtitle:
                'Lege Flugtickets, Hotelbuchungen, Bahnfahrten oder Notizen an.',
            onTap: onAddDocument,
          )
        else if (visibleDocuments.isEmpty)
          AppSectionCard(
            icon: Icons.search_off_rounded,
            title: 'Keine passenden Dokumente',
            subtitle: 'Ändere Suche, Kategorie oder Favoritenfilter.',
            onTap: onResetFilters,
          )
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
}

class _VaultOverview extends StatelessWidget {
  const _VaultOverview({
    required this.trip,
    required this.favoriteCount,
    required this.onAddDocument,
  });

  final Trip trip;
  final int favoriteCount;
  final VoidCallback onAddDocument;

  @override
  Widget build(BuildContext context) {
    final documentsCard = AppSectionCard(
      icon: Icons.description_outlined,
      title: '${trip.documentCount} Dokumente',
      subtitle: '$favoriteCount Favoriten',
      onTap: onAddDocument,
    );
    final photosCard = AppSectionCard(
      icon: Icons.photo_library_outlined,
      title: '${trip.photoCount} Fotos',
      subtitle: 'Galerie folgt im nächsten Ausbau.',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [documentsCard, const SizedBox(height: 12), photosCard],
          );
        }

        return Row(
          children: [
            Expanded(child: documentsCard),
            const SizedBox(width: 12),
            Expanded(child: photosCard),
          ],
        );
      },
    );
  }
}
