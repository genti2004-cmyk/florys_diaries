import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MomentsOverviewCard(
          momentCount: widget.trip.albumEntryCount,
          photoCount: photos.length,
          favoriteCount: favoriteCount,
          onAddMoment: () => _openEditor(),
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reisefotos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openGallery(photos, 0),
                child: Text('Alle ${photos.length}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PhotoMosaic(
            photos: photos,
            onPhotoTap: (index) => _openGallery(photos, index),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reisetagebuch',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Notizen, Orte und besondere Erlebnisse.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (widget.trip.albumEntries.isNotEmpty)
              FilterChip(
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
                label: const Text('Favoriten'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.trip.albumEntries.isEmpty)
          _EmptyMomentsCard(onAddMoment: () => _openEditor())
        else if (entries.isEmpty)
          _NoFavoriteMomentsCard(
            onShowAll: () => setState(() => _showFavoritesOnly = false),
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
}

class _MomentsOverviewCard extends StatelessWidget {
  const _MomentsOverviewCard({
    required this.momentCount,
    required this.photoCount,
    required this.favoriteCount,
    required this.onAddMoment,
  });

  final int momentCount;
  final int photoCount;
  final int favoriteCount;
  final VoidCallback onAddMoment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Momente',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fotos, Erlebnisse und Lieblingsorte aus dieser Reise.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OverviewMetric(
                    value: '$momentCount',
                    label: 'Einträge',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OverviewMetric(
                    value: '$photoCount',
                    label: 'Fotos',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OverviewMetric(
                    value: '$favoriteCount',
                    label: 'Favoriten',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddMoment,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Moment hinzufügen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PhotoMosaic extends StatelessWidget {
  const _PhotoMosaic({required this.photos, required this.onPhotoTap});

  final List<TravelDocument> photos;
  final ValueChanged<int> onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final visible = photos.take(3).toList(growable: false);

    if (visible.length == 1) {
      return SizedBox(
        height: 190,
        child: _PhotoTile(
          photo: visible.first,
          onTap: () => onPhotoTap(0),
          remainingCount: photos.length - 1,
        ),
      );
    }

    if (visible.length == 2) {
      return SizedBox(
        height: 176,
        child: Row(
          children: [
            Expanded(
              child: _PhotoTile(
                photo: visible[0],
                onTap: () => onPhotoTap(0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PhotoTile(
                photo: visible[1],
                onTap: () => onPhotoTap(1),
                remainingCount: photos.length - 2,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 196,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _PhotoTile(
              photo: visible[0],
              onTap: () => onPhotoTap(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _PhotoTile(
                    photo: visible[1],
                    onTap: () => onPhotoTap(1),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _PhotoTile(
                    photo: visible[2],
                    onTap: () => onPhotoTap(2),
                    remainingCount: photos.length - 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.onTap,
    this.remainingCount = 0,
  });

  final TravelDocument photo;
  final VoidCallback onTap;
  final int remainingCount;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: const TravelFileService().resolveDocumentFile(photo),
      builder: (context, snapshot) {
        final file = snapshot.data;
        final hasPreview = file != null && file.existsSync();

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
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
                        colors: [Colors.transparent, Color(0xB8000000)],
                        stops: [0.5, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 9,
                    child: Text(
                      photo.title.trim().isEmpty ? 'Reisefoto' : photo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (remainingCount > 0)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+$remainingCount',
                          style: const TextStyle(
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
          size: 38,
        ),
      ),
    );
  }
}

class _EmptyMomentsCard extends StatelessWidget {
  const _EmptyMomentsCard({required this.onAddMoment});

  final VoidCallback onAddMoment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              size: 42,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Noch kein Reisetagebuch',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Halte einen besonderen Ort, ein Essen, ein Highlight oder eine Tagesnotiz fest.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onAddMoment,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ersten Moment anlegen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoFavoriteMomentsCard extends StatelessWidget {
  const _NoFavoriteMomentsCard({required this.onShowAll});

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              size: 42,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Noch keine Favoriten',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Markiere einen Moment als Favorit oder zeige wieder alle Einträge.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onShowAll,
              child: const Text('Alle Momente anzeigen'),
            ),
          ],
        ),
      ),
    );
  }
}
