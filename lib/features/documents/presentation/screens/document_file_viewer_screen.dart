import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfx/pdfx.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';

class DocumentFileViewerScreen extends StatelessWidget {
  const DocumentFileViewerScreen({required this.document, super.key});

  final TravelDocument document;
  static const _fileService = TravelFileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: [
          IconButton(
            tooltip: 'Extern öffnen',
            onPressed: () => _openExternal(context),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: FutureBuilder<File?>(
        future: _fileService.resolveExistingDocumentFile(document),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final file = snapshot.data;
          if (file == null) {
            return const _MissingFileView();
          }

          if (_isImage(document.fileExtension)) {
            return _ImageViewer(file: file, document: document);
          }

          if (_isPdf(document.fileExtension)) {
            return _PdfViewer(file: file);
          }

          return _ExternalOnlyView(
            document: document,
            onOpen: () => _openExternal(context),
          );
        },
      ),
    );
  }

  Future<void> _openExternal(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await _fileService.resolveExistingDocumentFile(document);
    if (!context.mounted) {
      return;
    }

    if (file == null) {
      _showMessage(messenger, 'Die Datei wurde nicht gefunden oder gelöscht.');
      return;
    }

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      _showMessage(messenger, result.message);
    }
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

  static bool _isPdf(String extension) {
    return extension.toLowerCase().trim() == 'pdf';
  }

  static void _showMessage(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.file, required this.document});

  final File file;
  final TravelDocument document;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  cacheWidth: (MediaQuery.sizeOf(context).width *
                          MediaQuery.devicePixelRatioOf(context) *
                          2)
                      .round()
                      .clamp(1200, 3200)
                      .toInt(),
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    return const _MissingFileView(dark: true);
                  },
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _ViewerInfoBar(document: document),
        ),
      ],
    );
  }
}

class _PdfViewer extends StatefulWidget {
  const _PdfViewer({required this.file});

  final File file;

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openFile(widget.file.path),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(
      controller: _controller,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        pageLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, error) {
          return _ViewerError(
            message: 'PDF konnte nicht angezeigt werden. $error',
          );
        },
      ),
    );
  }
}

class _ViewerInfoBar extends StatelessWidget {
  const _ViewerInfoBar({required this.document});

  final TravelDocument document;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(document.category.icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${document.fileTypeLabel} • ${document.sizeLabel.isEmpty ? 'Größe unbekannt' : document.sizeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
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

class _ExternalOnlyView extends StatelessWidget {
  const _ExternalOnlyView({required this.document, required this.onOpen});

  final TravelDocument document;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(document.category.icon, size: 72, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Keine integrierte Vorschau',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${document.fileTypeLabel}-Dateien werden über eine passende externe App geöffnet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Extern öffnen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingFileView extends StatelessWidget {
  const _MissingFileView({this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? Colors.white : AppColors.text;
    final mutedColor = dark ? Colors.white70 : AppColors.textMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 72, color: mutedColor),
            const SizedBox(height: 16),
            Text(
              'Datei nicht gefunden',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Die Datei wurde wahrscheinlich außerhalb der App gelöscht oder verschoben.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerError extends StatelessWidget {
  const _ViewerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
