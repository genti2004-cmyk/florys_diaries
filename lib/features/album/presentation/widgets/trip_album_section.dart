import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/core/widgets/app_section_title.dart';
import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/album/presentation/screens/album_entry_editor_screen.dart';
import 'package:florys_diaries/features/album/presentation/widgets/album_entry_card.dart';
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
                title: '${widget.trip.albumEntryCount} Einträge',
                subtitle: '$favoriteCount Lieblingsmomente',
                onTap: () => _openEditor(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppSectionCard(
                icon: Icons.photo_library_outlined,
                title: '${photos.length} Fotos',
                subtitle: photos.isEmpty
                    ? 'Noch keine Foto-Dateien'
                    : 'Aus Travel Vault',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (photos.isNotEmpty) ...[
          _PhotoPreviewStrip(photos: photos),
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
              const ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
        })
        .toList(growable: false);
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: favoritesOnly,
                onChanged: onFavoritesChanged,
                title: const Text('Nur Lieblingsmomente'),
                secondary: const Icon(Icons.favorite_border_rounded),
              ),
            ),
            const SizedBox(width: 8),
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
  const _PhotoPreviewStrip({required this.photos});

  final List<TravelDocument> photos;

  @override
  Widget build(BuildContext context) {
    final visibleCount = photos.length > 8 ? 8 : photos.length;

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleCount,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return Container(
            width: 86,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_outlined, color: AppColors.primary),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    photo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
