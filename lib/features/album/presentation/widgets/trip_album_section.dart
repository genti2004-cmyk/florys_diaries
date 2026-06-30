import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/album/presentation/screens/album_entry_editor_screen.dart';
import 'package:florys_diaries/features/album/presentation/screens/trip_photo_gallery_screen.dart';
import 'package:florys_diaries/features/album/presentation/widgets/album_entry_card.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripAlbumSection extends StatefulWidget {
  const TripAlbumSection({required this.trip, super.key});

  final Trip trip;

  @override
  State<TripAlbumSection> createState() => _TripAlbumSectionState();
}

class _TripAlbumSectionState extends State<TripAlbumSection> {
  bool _showFavoritesOnly = false;

  Future<void> _openEditor({TripAlbumEntry? entry}) async {
    final store = TripStoreScope.of(context);
    final result = await Navigator.of(context).push<AlbumEntryEditorResult>(
      MaterialPageRoute<AlbumEntryEditorResult>(
        builder: (_) => AlbumEntryEditorScreen(
          tripStartDate: widget.trip.startDate,
          entry: entry,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final entries = List<TripAlbumEntry>.from(widget.trip.albumEntries);
    if (result.delete) {
      entries.removeWhere((item) => item.id == result.entry.id);
    } else {
      final index = entries.indexWhere((item) => item.id == result.entry.id);
      if (index == -1) {
        entries.add(result.entry);
      } else {
        entries[index] = result.entry;
      }
    }

    await store.updateTrip(widget.trip.copyWith(albumEntries: entries));
  }

  Future<void> _toggleFavorite(TripAlbumEntry entry) async {
    final store = TripStoreScope.of(context);
    final entries = widget.trip.albumEntries
        .map(
          (item) => item.id == entry.id
              ? item.copyWith(isFavorite: !item.isFavorite)
              : item,
        )
        .toList(growable: false);
    await store.updateTrip(widget.trip.copyWith(albumEntries: entries));
  }

  void _openGallery(List<TravelDocument> photos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripPhotoGalleryScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photoDocuments(widget.trip.documents);
    final entries = _visibleEntries(widget.trip.albumEntries);
    final favoriteCount = widget.trip.albumEntries
        .where((entry) => entry.isFavorite)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Momente', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Fotos, Highlights, Orte und persönliche Momente.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Eintrag'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryChip(
              icon: Icons.auto_stories_outlined,
              label: _entryCountLabel(widget.trip.albumEntryCount),
            ),
            _SummaryChip(
              icon: Icons.photo_library_outlined,
              label: photos.length == 1 ? '1 Foto' : '${photos.length} Fotos',
              onTap: photos.isEmpty ? null : () => _openGallery(photos, 0),
            ),
            _SummaryChip(
              icon: Icons.favorite_outline_rounded,
              label: favoriteCount == 1
                  ? '1 Favorit'
                  : '$favoriteCount Favoriten',
            ),
          ],
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PhotoPreviewStrip(
            photos: photos,
            onPhotoTap: (index) => _openGallery(photos, index),
          ),
        ],
        if (widget.trip.albumEntries.isNotEmpty) ...[
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              selected: _showFavoritesOnly,
              onSelected: (value) {
                setState(() => _showFavoritesOnly = value);
              },
              avatar: Icon(
                _showFavoritesOnly
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 17,
              ),
              label: const Text('Nur Favoriten'),
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (widget.trip.albumEntries.isEmpty)
          AppSectionCard(
            icon: Icons.add_circle_outline_rounded,
            title: 'Noch keine Momente',
            subtitle: 'Halte Tagesnotizen, Highlights und Orte fest.',
            onTap: () => _openEditor(),
          )
        else if (entries.isEmpty)
          AppSectionCard(
            icon: Icons.favorite_border_rounded,
            title: 'Keine Favoriten vorhanden',
            subtitle: 'Deaktiviere den Filter oder markiere einen Moment.',
            onTap: () => setState(() => _showFavoritesOnly = false),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AlbumEntryCard(
                entry: entry,
                onTap: () => _openEditor(entry: entry),
                onFavoriteToggle: () => _toggleFavorite(entry),
              ),
            ),
          ),
      ],
    );
  }

  List<TripAlbumEntry> _visibleEntries(List<TripAlbumEntry> entries) {
    final visible = entries
        .where((entry) => !_showFavoritesOnly || entry.isFavorite)
        .toList(growable: true);
    visible.sort((left, right) => right.date.compareTo(left.date));
    return visible;
  }

  static List<TravelDocument> _photoDocuments(List<TravelDocument> documents) {
    return documents
        .where((document) {
          final extension = document.fileExtension.toLowerCase();
          return document.categoryId == DocumentCategories.photo.id ||
              const <String>{
                'jpg',
                'jpeg',
                'png',
                'webp',
                'heic',
                'heif',
              }.contains(extension);
        })
        .toList(growable: false);
  }

  static String _entryCountLabel(int count) {
    return count == 1 ? '1 Eintrag' : '$count Einträge';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: content,
    );
  }
}

class _PhotoPreviewStrip extends StatelessWidget {
  const _PhotoPreviewStrip({
    required this.photos,
    required this.onPhotoTap,
  });

  final List<TravelDocument> photos;
  final ValueChanged<int> onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final visibleCount = photos.length > 10 ? 10 : photos.length;

    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleCount,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _PhotoPreviewTile(
            photo: photos[index],
            index: index,
            totalCount: photos.length,
            onTap: () => onPhotoTap(index),
          );
        },
      ),
    );
  }
}

class _PhotoPreviewTile extends StatelessWidget {
  const _PhotoPreviewTile({
    required this.photo,
    required this.index,
    required this.totalCount,
    required this.onTap,
  });

  final TravelDocument photo;
  final int index;
  final int totalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: const TravelFileService().resolveDocumentFile(photo),
      builder: (context, snapshot) {
        final file = snapshot.data;
        final hasPreview = file != null && file.existsSync();

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              width: 202,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasPreview)
                      Image.file(
                        file,
                        fit: BoxFit.cover,
                        cacheWidth: 900,
                        errorBuilder: (context, error, stackTrace) {
                          return const _PhotoPlaceholder();
                        },
                      )
                    else
                      const _PhotoPlaceholder(),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xD9000000)],
                          stops: [0.42, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.46),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${index + 1}/$totalCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          photo.title.trim().isEmpty
                              ? 'Reisefoto ${index + 1}'
                              : photo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.primary,
          size: 42,
        ),
      ),
    );
  }
}
