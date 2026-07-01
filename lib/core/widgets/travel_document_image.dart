import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';

/// Loads a managed travel document image without doing synchronous file I/O
/// during widget layout. The resolved file future is retained until the
/// document path changes, which prevents repeated path-provider and disk work
/// when parent widgets rebuild.
class TravelDocumentImage extends StatefulWidget {
  const TravelDocumentImage({
    required this.document,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.filterQuality = FilterQuality.low,
    this.fileService = const TravelFileService(),
    this.semanticLabel,
    super.key,
  });

  final TravelDocument document;
  final Widget placeholder;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final FilterQuality filterQuality;
  final TravelFileService fileService;
  final String? semanticLabel;

  @override
  State<TravelDocumentImage> createState() => _TravelDocumentImageState();
}

class _TravelDocumentImageState extends State<TravelDocumentImage> {
  late Future<File?> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = _resolveFile();
  }

  @override
  void didUpdateWidget(covariant TravelDocumentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id ||
        oldWidget.document.relativePath != widget.document.relativePath ||
        oldWidget.fileService != widget.fileService) {
      _fileFuture = _resolveFile();
    }
  }

  Future<File?> _resolveFile() {
    return widget.fileService.resolveExistingDocumentFile(widget.document);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _fileFuture,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return widget.placeholder;
        }

        return RepaintBoundary(
          child: Image.file(
            file,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
            cacheWidth: widget.cacheWidth,
            cacheHeight: widget.cacheHeight,
            filterQuality: widget.filterQuality,
            gaplessPlayback: true,
            semanticLabel: widget.semanticLabel,
            errorBuilder: (context, error, stackTrace) => widget.placeholder,
          ),
        );
      },
    );
  }
}
