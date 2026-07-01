import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_document_image.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/documents/presentation/screens/document_file_viewer_screen.dart';

class ReplayDocumentMoment extends StatelessWidget {
  const ReplayDocumentMoment({required this.document, super.key});

  final TravelDocument document;
  @override
  Widget build(BuildContext context) {
    final isImage = _isImage(document.fileExtension);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: TravelDocumentImage(
                key: ValueKey<String>(
                  'replay-document-${document.id}-${document.relativePath}',
                ),
                document: document,
                fit: BoxFit.cover,
                cacheWidth: 1200,
                filterQuality: FilterQuality.medium,
                placeholder: _DocumentFallback(document: document),
                semanticLabel: document.title.trim().isEmpty
                    ? 'Fotomoment'
                    : document.title,
              ),
            )
          else
            _DocumentFallback(document: document),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isImage ? 'Fotomoment' : 'Reisedokument',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    if (document.isFavorite)
                      const Icon(Icons.star_rounded, color: AppColors.sand),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  document.fileName.trim().isEmpty
                      ? document.title
                      : document.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                if (document.hasFile) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openPreview(context),
                      icon: Icon(
                        isImage
                            ? Icons.photo_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(isImage ? 'Foto öffnen' : 'Dokument öffnen'),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  const ReplayMemoryInfoLine(
                    icon: Icons.info_outline_rounded,
                    text: 'Für diesen Eintrag ist keine Datei hinterlegt.',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPreview(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentFileViewerScreen(document: document),
      ),
    );
  }

  static bool _isImage(String extension) {
    final value = extension.toLowerCase().trim();
    return value == 'jpg' ||
        value == 'jpeg' ||
        value == 'png' ||
        value == 'webp' ||
        value == 'heic' ||
        value == 'heif';
  }
}

class _DocumentFallback extends StatelessWidget {
  const _DocumentFallback({required this.document});

  final TravelDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      color: AppColors.primarySoft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(document.category.icon, size: 46, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            document.fileTypeLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ReplayMemoryInfoLine extends StatelessWidget {
  const ReplayMemoryInfoLine({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }
}
