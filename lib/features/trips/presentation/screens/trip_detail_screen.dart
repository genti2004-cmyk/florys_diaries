import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/core/widgets/app_section_title.dart';
import 'package:florys_diaries/features/album/presentation/widgets/trip_album_section.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/documents/presentation/screens/document_detail_screen.dart';
import 'package:florys_diaries/features/documents/presentation/screens/document_editor_screen.dart';
import 'package:florys_diaries/features/documents/presentation/widgets/travel_document_card.dart';
import 'package:florys_diaries/features/replay/presentation/screens/travel_replay_screen.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/data/trip_export_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

import 'trip_editor_screen.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({required this.trip, super.key});

  final Trip trip;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoryId = _allCategoriesId;
  _DocumentSortMode _sortMode = _DocumentSortMode.newest;
  bool _favoritesOnly = false;

  static const String _allCategoriesId = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _openReplay(BuildContext context, Trip currentTrip) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TravelReplayScreen(trip: currentTrip),
      ),
    );
  }

  Future<void> _editTrip(BuildContext context, Trip currentTrip) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripEditorScreen(trip: currentTrip),
      ),
    );
  }

  Future<void> _openDocumentEditor(
    BuildContext context,
    Trip currentTrip, {
    TravelDocument? document,
  }) async {
    final store = TripStoreScope.of(context);
    final result = await Navigator.of(context).push<DocumentEditorResult>(
      MaterialPageRoute<DocumentEditorResult>(
        builder: (_) => DocumentEditorScreen(
          tripId: currentTrip.id,
          document: document,
        ),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    final documents = List<TravelDocument>.from(currentTrip.documents);
    if (result.delete) {
      await const TravelFileService().deleteDocumentFile(result.document);
      documents.removeWhere((item) => item.id == result.document.id);
    } else {
      final index = documents.indexWhere((item) => item.id == result.document.id);
      if (index == -1) {
        documents.add(result.document);
      } else {
        documents[index] = result.document;
      }
    }

    await store.updateTrip(currentTrip.copyWith(documents: documents));
  }

  Future<void> _openDocumentDetail(
    BuildContext context,
    Trip currentTrip,
    TravelDocument document,
  ) async {
    final store = TripStoreScope.of(context);
    final action = await Navigator.of(context).push<DocumentDetailAction>(
      MaterialPageRoute<DocumentDetailAction>(
        builder: (_) => DocumentDetailScreen(document: document),
      ),
    );

    if (!context.mounted || action == null) {
      return;
    }

    if (action == DocumentDetailAction.edit) {
      await _openDocumentEditor(context, currentTrip, document: document);
      return;
    }

    if (action == DocumentDetailAction.delete) {
      final documents = List<TravelDocument>.from(currentTrip.documents)
        ..removeWhere((item) => item.id == document.id);
      await const TravelFileService().deleteDocumentFile(document);
      if (!context.mounted) {
        return;
      }
      await store.updateTrip(currentTrip.copyWith(documents: documents));
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    Trip currentTrip,
    TravelDocument document,
  ) async {
    final store = TripStoreScope.of(context);
    final documents = currentTrip.documents
        .map(
          (item) => item.id == document.id
              ? item.copyWith(isFavorite: !item.isFavorite)
              : item,
        )
        .toList(growable: false);
    await store.updateTrip(currentTrip.copyWith(documents: documents));
  }


  Future<void> _exportTrip(BuildContext context, Trip currentTrip) async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;

    messenger.showSnackBar(
      const SnackBar(content: Text('Reise-Export wird vorbereitet ...')),
    );

    final zipFile = await const TripExportService().exportTripAsZip(currentTrip);
    if (!context.mounted) {
      return;
    }

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zipFile.path)],
        subject: 'FlorysDiaries Export: ${currentTrip.title}',
        text: 'Reise-Export aus FlorysDiaries: ${currentTrip.title}',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );

    if (result.status == ShareResultStatus.unavailable) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Teilen ist auf diesem Gerät nicht verfügbar.')),
      );
    }
  }

  Future<void> _deleteTrip(BuildContext context, Trip currentTrip) async {
    final store = TripStoreScope.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reise löschen?'),
          content: Text('${currentTrip.title} wird aus FlorysDiaries entfernt.'),
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

    await const TravelFileService().deleteTripFiles(currentTrip.id);
    await store.deleteTrip(currentTrip.id);
    if (!context.mounted) {
      return;
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final currentTrip = store.trips.firstWhere(
      (item) => item.id == widget.trip.id,
      orElse: () => widget.trip,
    );
    final dateText =
        '${_formatDate(currentTrip.startDate)} – ${_formatDate(currentTrip.endDate)}';
    final visibleDocuments = _filteredDocuments(currentTrip.documents);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTrip.title),
        actions: [
          IconButton(
            tooltip: 'Reise exportieren',
            onPressed: () => _exportTrip(context, currentTrip),
            icon: const Icon(Icons.archive_outlined),
          ),
          IconButton(
            tooltip: 'Bearbeiten',
            onPressed: () => _editTrip(context, currentTrip),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Löschen',
            onPressed: () => _deleteTrip(context, currentTrip),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDocumentEditor(context, currentTrip),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Dokument'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _TripHeroCard(currentTrip: currentTrip, dateText: dateText),
            const SizedBox(height: 16),
            AppSectionCard(
              icon: Icons.play_circle_outline_rounded,
              title: 'Reise abspielen',
              subtitle: 'Starte den interaktiven Travel Replay dieser Reise.',
              onTap: () => _openReplay(context, currentTrip),
            ),
            const SizedBox(height: 16),
            TripAlbumSection(trip: currentTrip),
            const SizedBox(height: 16),
            const AppSectionTitle(
              title: 'Travel Vault',
              subtitle: 'Tickets, Buchungen, Screenshots und wichtige Notizen.',
            ),
            Row(
              children: [
                Expanded(
                  child: AppSectionCard(
                    icon: Icons.description_outlined,
                    title: '${currentTrip.documentCount} Dokumente',
                    subtitle: '${_favoriteCount(currentTrip.documents)} Favoriten',
                    onTap: () => _openDocumentEditor(context, currentTrip),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppSectionCard(
                    icon: Icons.photo_library_outlined,
                    title: '${currentTrip.photoCount} Fotos',
                    subtitle: 'Galerie folgt im nächsten Ausbau.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (currentTrip.documents.isNotEmpty) ...[
              _DocumentToolsCard(
                controller: _searchController,
                categoryId: _categoryId,
                sortMode: _sortMode,
                favoritesOnly: _favoritesOnly,
                onSearchChanged: (value) => setState(() => _query = value),
                onCategoryChanged: (value) {
                  setState(() => _categoryId = value ?? _allCategoriesId);
                },
                onSortChanged: (value) {
                  setState(() => _sortMode = value ?? _DocumentSortMode.newest);
                },
                onFavoritesChanged: (value) {
                  setState(() => _favoritesOnly = value);
                },
              ),
              const SizedBox(height: 12),
            ],
            if (currentTrip.documents.isEmpty)
              AppSectionCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'Noch keine Dokumente',
                subtitle:
                    'Lege Flugtickets, Hotelbuchungen, Bahnfahrten oder Notizen an.',
                onTap: () => _openDocumentEditor(context, currentTrip),
              )
            else if (visibleDocuments.isEmpty)
              AppSectionCard(
                icon: Icons.search_off_rounded,
                title: 'Keine passenden Dokumente',
                subtitle: 'Ändere Suche, Kategorie oder Favoritenfilter.',
                onTap: _resetDocumentFilters,
              )
            else
              ...visibleDocuments.map(
                (document) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TravelDocumentCard(
                    document: document,
                    onTap: () => _openDocumentDetail(
                      context,
                      currentTrip,
                      document,
                    ),
                    onFavoriteToggle: () => _toggleFavorite(
                      context,
                      currentTrip,
                      document,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<TravelDocument> _filteredDocuments(List<TravelDocument> documents) {
    final lowerQuery = _query.trim().toLowerCase();
    final filtered = documents.where((document) {
      final matchesFavorite = !_favoritesOnly || document.isFavorite;
      final matchesCategory =
          _categoryId == _allCategoriesId || document.categoryId == _categoryId;
      final searchableText = [
        document.title,
        document.category.label,
        document.fileName,
        document.fileExtension,
        document.description,
      ].join(' ').toLowerCase();
      final matchesQuery = lowerQuery.isEmpty || searchableText.contains(lowerQuery);
      return matchesFavorite && matchesCategory && matchesQuery;
    }).toList();

    filtered.sort((left, right) {
      switch (_sortMode) {
        case _DocumentSortMode.newest:
          return right.createdAt.compareTo(left.createdAt);
        case _DocumentSortMode.oldest:
          return left.createdAt.compareTo(right.createdAt);
        case _DocumentSortMode.title:
          return left.title.toLowerCase().compareTo(right.title.toLowerCase());
        case _DocumentSortMode.category:
          return left.category.label.compareTo(right.category.label);
      }
    });
    return filtered;
  }

  void _resetDocumentFilters() {
    setState(() {
      _query = '';
      _categoryId = _allCategoriesId;
      _sortMode = _DocumentSortMode.newest;
      _favoritesOnly = false;
      _searchController.clear();
    });
  }

  static int _favoriteCount(List<TravelDocument> documents) {
    return documents.where((document) => document.isFavorite).length;
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _DocumentToolsCard extends StatelessWidget {
  const _DocumentToolsCard({
    required this.controller,
    required this.categoryId,
    required this.sortMode,
    required this.favoritesOnly,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onFavoritesChanged,
  });

  final TextEditingController controller;
  final String categoryId;
  final _DocumentSortMode sortMode;
  final bool favoritesOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<_DocumentSortMode?> onSortChanged;
  final ValueChanged<bool> onFavoritesChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                labelText: 'Dokumente suchen',
                hintText: 'Titel, Datei, Kategorie oder Notiz',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: categoryId,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem(
                  value: _TripDetailScreenState._allCategoriesId,
                  child: Text('Alle Kategorien'),
                ),
                ...DocumentCategories.values.map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.label),
                  ),
                ),
              ],
              onChanged: onCategoryChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_DocumentSortMode>(
              initialValue: sortMode,
              decoration: const InputDecoration(
                labelText: 'Sortierung',
                prefixIcon: Icon(Icons.sort_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: _DocumentSortMode.newest,
                  child: Text('Neueste zuerst'),
                ),
                DropdownMenuItem(
                  value: _DocumentSortMode.oldest,
                  child: Text('Älteste zuerst'),
                ),
                DropdownMenuItem(
                  value: _DocumentSortMode.title,
                  child: Text('Titel A–Z'),
                ),
                DropdownMenuItem(
                  value: _DocumentSortMode.category,
                  child: Text('Kategorie A–Z'),
                ),
              ],
              onChanged: onSortChanged,
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: favoritesOnly,
              onChanged: onFavoritesChanged,
              title: const Text('Nur Favoriten anzeigen'),
              secondary: const Icon(Icons.star_border_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripHeroCard extends StatelessWidget {
  const _TripHeroCard({required this.currentTrip, required this.dateText});

  final Trip currentTrip;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    currentTrip.isPast
                        ? Icons.luggage_rounded
                        : Icons.flight_takeoff_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTrip.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentTrip.destination}, ${currentTrip.country}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailChip(icon: Icons.calendar_today_outlined, label: dateText),
            const SizedBox(height: 10),
            _DetailChip(
              icon: Icons.timelapse_rounded,
              label: '${currentTrip.durationDays} Reisetage',
            ),
            const SizedBox(height: 16),
            Text(
              currentTrip.notes.trim().isEmpty
                  ? 'Keine Notizen gespeichert.'
                  : currentTrip.notes,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.text,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

enum _DocumentSortMode { newest, oldest, title, category }
