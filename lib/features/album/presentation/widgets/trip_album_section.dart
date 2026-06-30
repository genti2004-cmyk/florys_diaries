import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/core/widgets/app_section_title.dart';
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
        const AppSectionTitle(
          title: 'Reisealbum',
          subtitle: 'Highlights, Orte, Tagesnotizen und Lieblingsmomente.',
        ),
        Row(
          children: [
            Expanded(
              child: AppSectionCard(
                icon: Icons.auto_stories_outlined,
                title: _entryCountLabel(widget.trip.albumEntryCount),
                subtitle: favoriteCount == 1
                    ? '1 Lieblingsmoment'
                    : '$favoriteCount Lieblingsmomente',
                onTap: () => _openEditor(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppSectionCard(
                icon: Icons.photo_library_outlined,
                title: photos.length == 1 ? '1 Foto' : '${photos.length} Fotos',
                subtitle: photos.isEmpty
                    ? 'Noch keine Foto-Dateien'
                    : 'Zum Vergrößern antippen',
                onTap: photos.isEmpty ? null : () => _openGallery(photos, 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (photos.isNotEmpty) ...[
          _PhotoPreviewStrip(
            photos: photos,
            onPhotoTap: (index) => _openGallery(photos, index),
          ),
          const SizedBox(height: 12),
        ],
        _AlbumToolsRow(
          favoritesOnly: _showFavoritesOnly,
          onAdd: () => _openEditor(),
          onFavoritesChanged: (value) {
            setState(() => _showFavoritesOnly = value);
          },
        ),
        const SizedBox(height: 12),
        if (widget.trip.albumEntries.isEmpty)
          AppSectionCard(
            icon: Icons.add_circle_outline_rounded,
            title: 'Noch kein Reisealbum',
            subtitle: 'Halte Tagesnotizen, Highlights und Orte fest.',
            onTap: () => _openEditor(),
          )
        else if (entries.isEmpty)
          AppSectionCard(
            icon: Icons.favorite_border_rounded,
            title: 'Keine Lieblingsmomente sichtbar',
            subtitle:
                'Schalte den Filter aus oder markiere Einträge als Favorit.',
            onTap: () => setState(() => _showFavoritesOnly = false),
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
    visible.sort((left, right) => left.date.compareTo(right.date));
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

class _AlbumToolsRow extends StatelessWidget {
  const _AlbumToolsRow({
    required this.favoritesOnly,
    required this.onAdd,
    required this.onFavoritesChanged,
  });

  final bool favoritesOnly;
  final VoidCallback onAdd;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          children: [
            const Icon(Icons.favorite_border_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nur Favoriten',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Switch.adaptive(
              value: favoritesOnly,
              onChanged: onFavoritesChanged,
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Eintrag'),
            ),
          ],
        ),
      ),
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
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleCount,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
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
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: Ink(
              width: 222,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x100D1728),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
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
                          stops: [0.38, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.46),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.fullscreen_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${index + 1}/$totalCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photo.title.trim().isEmpty
                                  ? 'Reisefoto ${index + 1}'
                                  : photo.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            if (photo.fileName.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                photo.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ],
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
