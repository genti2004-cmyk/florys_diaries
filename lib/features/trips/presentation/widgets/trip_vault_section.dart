import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
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
    final favoriteCount = trip.documents
        .where((document) => document.isFavorite)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionTitle(
          title: 'Dokumente & Reiseunterlagen',
          subtitle: 'Tickets, Buchungen, Nachweise und wichtige Dateien.',
        ),
        _VaultOverview(
          documentCount: trip.documentCount,
          favoriteCount: favoriteCount,
          photoCount: trip.photoCount,
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
            title: 'Noch keine Reiseunterlagen',
            subtitle:
                'Füge Flugtickets, Hotelbuchungen, Bahnfahrten oder Notizen hinzu.',
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
    required this.documentCount,
    required this.favoriteCount,
    required this.photoCount,
    required this.onAddDocument,
  });

  final int documentCount;
  final int favoriteCount;
  final int photoCount;
  final VoidCallback onAddDocument;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        final documents = _VaultMetricCard(
          icon: Icons.description_outlined,
          value: documentCount.toString(),
          label: documentCount == 1 ? 'Dokument' : 'Dokumente',
          detail: '$favoriteCount Favoriten',
          onTap: onAddDocument,
        );
        final photos = _VaultMetricCard(
          icon: Icons.photo_library_outlined,
          value: photoCount.toString(),
          label: photoCount == 1 ? 'Foto' : 'Fotos',
          detail: 'Im Reisealbum',
        );

        if (stacked) {
          return Column(
            children: [documents, const SizedBox(height: 10), photos],
          );
        }

        return Row(
          children: [
            Expanded(child: documents),
            const SizedBox(width: 10),
            Expanded(child: photos),
          ],
        );
      },
    );
  }
}

class _VaultMetricCard extends StatelessWidget {
  const _VaultMetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value $label',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
