import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripCoverImage extends StatefulWidget {
  const TripCoverImage({
    required this.trip,
    required this.borderRadius,
    this.fit = BoxFit.cover,
    this.overlay,
    this.child,
    this.showFallbackIcon = true,
    super.key,
  });

  final Trip trip;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final Gradient? overlay;
  final Widget? child;
  final bool showFallbackIcon;

  static List<TravelDocument> photoDocuments(Trip trip) {
    return trip.documents.where(_isPhoto).toList(growable: false);
  }

  static TravelDocument? firstPhotoDocument(Trip trip) {
    for (final document in trip.documents) {
      if (_isPhoto(document)) {
        return document;
      }
    }
    return null;
  }

  static bool _isPhoto(TravelDocument document) {
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

  @override
  State<TripCoverImage> createState() => _TripCoverImageState();
}

class _TripCoverImageState extends State<TripCoverImage> {
  Future<File?>? _fileFuture;
  TravelDocument? _photo;

  @override
  void initState() {
    super.initState();
    _refreshPhoto();
  }

  @override
  void didUpdateWidget(covariant TripCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.id != widget.trip.id ||
        oldWidget.trip.documents != widget.trip.documents) {
      _refreshPhoto();
    }
  }

  void _refreshPhoto() {
    _photo = TripCoverImage.firstPhotoDocument(widget.trip);
    final photo = _photo;
    _fileFuture = photo == null
        ? null
        : const TravelFileService().resolveDocumentFile(photo);
  }

  @override
  Widget build(BuildContext context) {
    final palette = TravelVisuals.forText(
      '${widget.trip.title} ${widget.trip.destination} ${widget.trip.country}',
    );

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.gradient,
              ),
            ),
          ),
          if (_fileFuture != null)
            FutureBuilder<File?>(
              future: _fileFuture,
              builder: (context, snapshot) {
                final file = snapshot.data;
                if (file == null) {
                  return const SizedBox.shrink();
                }
                return FutureBuilder<bool>(
                  future: file.exists(),
                  builder: (context, existsSnapshot) {
                    if (existsSnapshot.data != true) {
                      return const SizedBox.shrink();
                    }
                    return Image.file(
                      file,
                      fit: widget.fit,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    );
                  },
                );
              },
            ),
          if (widget.overlay != null)
            DecoratedBox(decoration: BoxDecoration(gradient: widget.overlay)),
          if (_photo == null && widget.showFallbackIcon)
            Center(
              child: Icon(
                palette.icon,
                color: Colors.white.withValues(alpha: 0.88),
                size: 30,
              ),
            ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}
