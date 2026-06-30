import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
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
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );

    if (result.status == ShareResultStatus.unavailable) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Teilen ist auf diesem Gerät nicht verfügbar.'),
        ),
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

    await Navigator.of(context).push(
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dokument'),
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
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _DocumentHero(document: document),
            const SizedBox(height: 14),
            _DocumentPreview(document: document),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetaCard(
                    label: 'Typ',
                    value: document.fileTypeLabel,
                    icon: Icons.insert_drive_file_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetaCard(
                    label: 'Größe',
                    value: document.sizeLabel.isEmpty
                        ? '—'
                        : document.sizeLabel,
                    icon: Icons.storage_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MetaCard(
              label: 'Gespeichert am',
              value: createdText,
              icon: Icons.calendar_today_outlined,
            ),
            if (document.description.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.notes_rounded,
                              size: 19,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Notiz',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
              onPressed: document.hasFile
                  ? () => _showIntegratedPreview(context)
                  : null,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('In FlorysDiaries öffnen'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: document.hasFile
                        ? () => _openFile(context)
                        : null,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Extern'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: document.hasFile
                        ? () => _shareFile(context)
                        : null,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Teilen'),
                  ),
                ),
              ],
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

class _DocumentHero extends StatelessWidget {
  const _DocumentHero({required this.document});

  final TravelDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101F36), Color(0xFF2357D8)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A173B68),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Icon(document.category.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.category.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  document.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (document.fileName.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    document.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (document.isFavorite)
            const Icon(Icons.star_rounded, color: Color(0xFFFFD98B)),
        ],
      ),
    );
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
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 240,
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
    return value == 'jpg' ||
        value == 'jpeg' ||
        value == 'png' ||
        value == 'webp';
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
    return 'Vorschau wird über die passende Ansicht oder eine externe App geöffnet.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF1FF), Color(0xFFF7FAFF)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              document.category.icon,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            document.fileTypeLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _previewFallbackText(document.fileExtension),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 19, color: AppColors.primary),
            ),
            const SizedBox(width: 11),
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
