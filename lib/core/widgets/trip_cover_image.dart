import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/travel_document_image.dart';
import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripCoverImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = TravelVisuals.forText(
      '${trip.title} ${trip.destination} ${trip.country}',
    );
    final photo = firstPhotoDocument(trip);
    final fallback = showFallbackIcon
        ? Center(
            child: Icon(
              palette.icon,
              color: Colors.white.withValues(alpha: 0.88),
              size: 30,
            ),
          )
        : const SizedBox.shrink();

    return ClipRRect(
      borderRadius: borderRadius,
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
          if (photo != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
                final logicalWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.sizeOf(context).width;
                final cacheWidth = (logicalWidth * devicePixelRatio)
                    .round()
                    .clamp(360, 1600)
                    .toInt();

                return TravelDocumentImage(
                  key: ValueKey<String>(
                    'trip-cover-${photo.id}-${photo.relativePath}',
                  ),
                  document: photo,
                  fit: fit,
                  cacheWidth: cacheWidth,
                  filterQuality: FilterQuality.medium,
                  placeholder: fallback,
                  semanticLabel: photo.title.trim().isEmpty
                      ? 'Reisefoto'
                      : photo.title,
                );
              },
            )
          else
            fallback,
          if (overlay != null)
            DecoratedBox(decoration: BoxDecoration(gradient: overlay)),
          ?child,
        ],
      ),
    );
  }
}
