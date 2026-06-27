import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
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
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(document.category.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        if (document.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: AppColors.sand,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      document.category.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (document.fileName.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
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
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: meta.map(_DocumentMetaChip.new).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: document.isFavorite
                    ? 'Favorit entfernen'
                    : 'Als Favorit markieren',
                onPressed: onFavoriteToggle,
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
                color: AppColors.textMuted,
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

class _DocumentMetaChip extends StatelessWidget {
  const _DocumentMetaChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
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
