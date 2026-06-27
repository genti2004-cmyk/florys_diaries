import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'document_file_viewer_screen.dart';

enum DocumentDetailAction { edit, delete }

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({required this.document, super.key});

  final TravelDocument document;
  static const _fileService = TravelFileService();

  Future<void> _openFile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await _fileService.resolveDocumentFile(document);
    if (!context.mounted) {
      return;
    }

    if (file == null || !file.existsSync()) {
      _showMissingFileMessage(messenger);
      return;
    }

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      messenger.showSnackBar(SnackBar(content: Text(result.message)));
    }
  }


  Future<void> _shareFile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final file = await _fileService.resolveDocumentFile(document);
    if (!context.mounted) {
      return;
    }

    if (file == null || !file.existsSync()) {
      _showMissingFileMessage(messenger);
      return;
    }

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: document.title,
        text: 'Dokument aus FlorysDiaries: ${document.title}',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );

    if (result.status == ShareResultStatus.unavailable) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Teilen ist auf diesem Gerät nicht verfügbar.')),
      );
    }
  }

  Future<void> _showIntegratedPreview(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await _fileService.resolveDocumentFile(document);
    if (!context.mounted) {
      return;
    }

    if (file == null || !file.existsSync()) {
      _showMissingFileMessage(messenger);
      return;
    }

    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentFileViewerScreen(document: document),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Dokument löschen?'),
          content: Text('${document.title} wird aus dieser Reise entfernt.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || confirmed != true) {
      return;
    }
    Navigator.of(context).pop(DocumentDetailAction.delete);
  }

  @override
  Widget build(BuildContext context) {
    final createdText = _formatDate(document.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: [
          IconButton(
            tooltip: 'Bearbeiten',
            onPressed: () {
              Navigator.of(context).pop(DocumentDetailAction.edit);
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Löschen',
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DocumentPreview(document: document),
            const SizedBox(height: 16),
            AppSectionCard(
              icon: document.category.icon,
              title: document.category.label,
              subtitle: document.fileName.trim().isEmpty
                  ? 'Kein Dateiname gespeichert.'
                  : document.fileName,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetaCard(
                    label: 'Typ',
                    value: document.fileTypeLabel,
                    icon: Icons.insert_drive_file_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetaCard(
                    label: 'Größe',
                    value: document.sizeLabel.isEmpty ? '—' : document.sizeLabel,
                    icon: Icons.storage_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetaCard(
              label: 'Gespeichert am',
              value: createdText,
              icon: Icons.calendar_today_outlined,
            ),
            if (document.description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notiz',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        document.description,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: document.hasFile ? () => _showIntegratedPreview(context) : null,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Vorschau öffnen'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: document.hasFile ? () => _openFile(context) : null,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Extern öffnen'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: document.hasFile ? () => _shareFile(context) : null,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Teilen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMissingFileMessage(ScaffoldMessengerState messenger) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Die Datei wurde nicht gefunden oder gelöscht.'),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.document});

  final TravelDocument document;
  static const _fileService = TravelFileService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _fileService.resolveDocumentFile(document),
      builder: (context, snapshot) {
        final file = snapshot.data;
        final showImage = file != null && _isImage(document.fileExtension);

        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 230,
            width: double.infinity,
            child: showImage
                ? Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _PreviewFallback(document: document);
                    },
                  )
                : _PreviewFallback(document: document),
          ),
        );
      },
    );
  }

  static bool _isImage(String extension) {
    final value = extension.toLowerCase().trim();
    return value == 'jpg' || value == 'jpeg' || value == 'png' || value == 'webp';
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.document});

  final TravelDocument document;

  static String _previewFallbackText(String extension) {
    final value = extension.toLowerCase().trim();
    if (value == 'pdf') {
      return 'PDF kann direkt in FlorysDiaries angezeigt werden.';
    }
    return 'Vorschau wird über passende Ansicht oder externe App geöffnet.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySoft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(document.category.icon, size: 54, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            document.fileTypeLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _previewFallbackText(document.fileExtension),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
