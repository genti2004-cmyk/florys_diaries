import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
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
    final meta = _metaText(document);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DocumentLeading(document: document),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                      ],
                    ),
                    Text(
                      document.category.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (document.fileName.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        document.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: meta.map(_DocumentMetaChip.new).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 22),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<String> _metaText(TravelDocument document) {
    final items = <String>[];
    if (document.hasFile) {
      items.add(document.fileTypeLabel);
    }
    if (document.sizeLabel.isNotEmpty) {
      items.add(document.sizeLabel);
    }
    return items;
  }
}

class _DocumentLeading extends StatelessWidget {
  const _DocumentLeading({required this.document});

  static const TravelFileService _fileService = TravelFileService();

  final TravelDocument document;

  @override
  Widget build(BuildContext context) {
    if (!_isImageDocument(document)) {
      return _DocumentIcon(document: document);
    }

    return FutureBuilder<File?>(
      future: _fileService.resolveDocumentFile(document),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null || !file.existsSync()) {
          return _DocumentIcon(document: document);
        }

        return Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            cacheWidth: 320,
            errorBuilder: (context, error, stackTrace) {
              return _DocumentIcon(document: document, compact: true);
            },
          ),
        );
      },
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
      width: compact ? double.infinity : 76,
      height: compact ? double.infinity : 76,
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
        size: compact ? 28 : 30,
      ),
    );
  }
}

class _DocumentMetaChip extends StatelessWidget {
  const _DocumentMetaChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
