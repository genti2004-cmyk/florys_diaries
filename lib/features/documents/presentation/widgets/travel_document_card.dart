import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_document_image.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';

class TravelDocumentCard extends StatelessWidget {
  const TravelDocumentCard({
    required this.document,
    required this.onTap,
    this.onFavoriteToggle,
    super.key,
  });

  final TravelDocument document;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _DocumentLeading(document: document),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title.trim().isEmpty
                          ? 'Dokument'
                          : document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _subtitle(document),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (document.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        document.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: document.isFavorite
                        ? 'Favorit entfernen'
                        : 'Als Favorit markieren',
                    onPressed: onFavoriteToggle,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      document.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: document.isFavorite
                          ? AppColors.sand
                          : AppColors.textMuted,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _subtitle(TravelDocument document) {
    final parts = <String>[document.category.label];
    if (document.hasFile && document.fileTypeLabel.trim().isNotEmpty) {
      parts.add(document.fileTypeLabel);
    }
    if (document.sizeLabel.trim().isNotEmpty) {
      parts.add(document.sizeLabel);
    }
    if (document.fileName.trim().isNotEmpty) {
      parts.add(document.fileName.trim());
    }
    return parts.join(' · ');
  }
}

class _DocumentLeading extends StatelessWidget {
  const _DocumentLeading({required this.document});

  final TravelDocument document;

  @override
  Widget build(BuildContext context) {
    if (!_isImageDocument(document)) {
      return _DocumentIcon(document: document);
    }

    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: TravelDocumentImage(
        key: ValueKey<String>(
          'document-card-${document.id}-${document.relativePath}',
        ),
        document: document,
        fit: BoxFit.cover,
        cacheWidth: 320,
        cacheHeight: 320,
        placeholder: _DocumentIcon(document: document, compact: true),
        semanticLabel: document.title.trim().isEmpty
            ? 'Dokumentvorschau'
            : document.title,
      ),
    );
  }

  static bool _isImageDocument(TravelDocument document) {
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
  }
}

class _DocumentIcon extends StatelessWidget {
  const _DocumentIcon({required this.document, this.compact = false});

  final TravelDocument document;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? double.infinity : 66,
      height: compact ? double.infinity : 66,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF1FF), Color(0xFFDCE8FF)],
        ),
        borderRadius: compact ? BorderRadius.zero : BorderRadius.circular(20),
      ),
      child: Icon(
        document.category.icon,
        color: AppColors.primary,
        size: compact ? 26 : 28,
      ),
    );
  }
}
