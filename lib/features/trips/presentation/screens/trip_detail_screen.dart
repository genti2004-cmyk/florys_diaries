import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:florys_diaries/features/album/presentation/widgets/trip_album_section.dart';
import 'package:florys_diaries/features/checklist/presentation/widgets/trip_checklist_section.dart';
import 'package:florys_diaries/features/documents/application/trip_document_query.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/documents/presentation/screens/document_detail_screen.dart';
import 'package:florys_diaries/features/documents/presentation/screens/document_editor_screen.dart';
import 'package:florys_diaries/features/replay/presentation/screens/travel_replay_screen.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/data/trip_export_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_detail_hero_card.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_detail_quick_actions.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_vault_section.dart';

import 'trip_editor_screen.dart';

enum _TripDetailMenuAction { edit, export, delete }

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({
    required this.trip,
    this.fileService = const TravelFileService(),
    this.exportService = const TripExportService(),
    super.key,
  });

  final Trip trip;
  final TravelFileService fileService;
  final TripExportService exportService;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  TripDocumentQuery _documentQuery = const TripDocumentQuery();
  List<TravelDocument>? _lastDocumentSource;
  TripDocumentQuery? _lastAppliedQuery;
  List<TravelDocument> _visibleDocuments = const <TravelDocument>[];

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
        builder: (_) =>
            DocumentEditorScreen(tripId: currentTrip.id, document: document),
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }

    final documents = List<TravelDocument>.from(currentTrip.documents);
    if (result.delete) {
      documents.removeWhere((item) => item.id == result.document.id);
    } else {
      final index = documents.indexWhere(
        (item) => item.id == result.document.id,
      );
      if (index == -1) {
        documents.add(result.document);
      } else {
        documents[index] = result.document;
      }
    }

    try {
      await store.updateTrip(currentTrip.copyWith(documents: documents));
    } catch (_) {
      if (!result.delete && _fileWasReplaced(document, result.document)) {
        await _deleteDocumentFileSilently(result.document);
      }
      if (context.mounted) {
        _showMessage(
          context,
          'Das Dokument konnte nicht sicher gespeichert werden.',
        );
      }
      return;
    }

    if (result.delete) {
      final cleaned = await _deleteDocumentFileSilently(result.document);
      if (!cleaned && context.mounted) {
        _showMessage(
          context,
          'Dokument entfernt. Die lokale Datei konnte nicht bereinigt werden.',
        );
      }
      return;
    }

    if (_fileWasReplaced(document, result.document) && document != null) {
      final cleaned = await _deleteDocumentFileSilently(document);
      if (!cleaned && context.mounted) {
        _showMessage(
          context,
          'Dokument gespeichert. Die vorherige Datei konnte nicht bereinigt werden.',
        );
      }
    }
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

    final documents = List<TravelDocument>.from(currentTrip.documents)
      ..removeWhere((item) => item.id == document.id);

    try {
      await store.updateTrip(currentTrip.copyWith(documents: documents));
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Das Dokument konnte nicht gelöscht werden.');
      }
      return;
    }

    final cleaned = await _deleteDocumentFileSilently(document);
    if (!cleaned && context.mounted) {
      _showMessage(
        context,
        'Dokument entfernt. Die lokale Datei konnte nicht bereinigt werden.',
      );
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

    try {
      await store.updateTrip(currentTrip.copyWith(documents: documents));
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Der Favorit konnte nicht gespeichert werden.');
      }
    }
  }

  Future<void> _exportTrip(BuildContext context, Trip currentTrip) async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;

    messenger.showSnackBar(
      const SnackBar(content: Text('Reise-Export wird vorbereitet ...')),
    );

    try {
      final zipFile = await widget.exportService.exportTripAsZip(currentTrip);
      if (!context.mounted) {
        return;
      }

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(zipFile.path)],
          subject: 'FlorysDiaries Export: ${currentTrip.title}',
          text: 'Reise-Export aus FlorysDiaries: ${currentTrip.title}',
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
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Der Reise-Export konnte nicht erstellt werden.');
      }
    }
  }

  Future<void> _deleteTrip(BuildContext context, Trip currentTrip) async {
    final store = TripStoreScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reise löschen?'),
          content: Text(
            '${currentTrip.title} wird aus FlorysDiaries entfernt.',
          ),
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

    try {
      await store.deleteTrip(currentTrip.id);
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Die Reise konnte nicht gelöscht werden.');
      }
      return;
    }

    final filesCleaned = await _deleteTripFilesSilently(currentTrip.id);
    if (!context.mounted) {
      return;
    }

    navigator.pop();
    if (!filesCleaned) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Reise gelöscht. Einige lokale Dateien konnten nicht bereinigt werden.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final currentTrip = store.trips.firstWhere(
      (item) => item.id == widget.trip.id,
      orElse: () => widget.trip,
    );
    final visibleDocuments = _documentsFor(currentTrip.documents);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentTrip.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<_TripDetailMenuAction>(
            tooltip: 'Weitere Reiseaktionen',
            onSelected: (action) {
              switch (action) {
                case _TripDetailMenuAction.edit:
                  unawaited(_editTrip(context, currentTrip));
                  break;
                case _TripDetailMenuAction.export:
                  unawaited(_exportTrip(context, currentTrip));
                  break;
                case _TripDetailMenuAction.delete:
                  unawaited(_deleteTrip(context, currentTrip));
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _TripDetailMenuAction.edit,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Reise bearbeiten'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _TripDetailMenuAction.export,
                child: ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Reise exportieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _TripDetailMenuAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Reise löschen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDocumentEditor(context, currentTrip),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Dokument'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: PageStorageKey<String>('trip-detail-${currentTrip.id}'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
          children: [
            TripDetailHeroCard(trip: currentTrip),
            const SizedBox(height: 14),
            TripDetailQuickActions(
              onReplay: () => _openReplay(context, currentTrip),
              onEdit: () => _editTrip(context, currentTrip),
              onExport: () => _exportTrip(context, currentTrip),
            ),
            const SizedBox(height: 18),
            TripChecklistSection(trip: currentTrip),
            const SizedBox(height: 18),
            TripAlbumSection(trip: currentTrip),
            const SizedBox(height: 18),
            TripVaultSection(
              trip: currentTrip,
              visibleDocuments: visibleDocuments,
              searchController: _searchController,
              query: _documentQuery,
              onAddDocument: () => _openDocumentEditor(context, currentTrip),
              onDocumentTap: (document) {
                _openDocumentDetail(context, currentTrip, document);
              },
              onFavoriteToggle: (document) {
                _toggleFavorite(context, currentTrip, document);
              },
              onSearchChanged: (value) {
                _updateDocumentQuery(
                  _documentQuery.copyWith(searchText: value),
                );
              },
              onCategoryChanged: (value) {
                _updateDocumentQuery(
                  _documentQuery.copyWith(categoryId: value),
                );
              },
              onSortChanged: (value) {
                _updateDocumentQuery(_documentQuery.copyWith(sortMode: value));
              },
              onFavoritesChanged: (value) {
                _updateDocumentQuery(
                  _documentQuery.copyWith(favoritesOnly: value),
                );
              },
              onResetFilters: _resetDocumentFilters,
            ),
          ],
        ),
      ),
    );
  }

  List<TravelDocument> _documentsFor(List<TravelDocument> documents) {
    if (!identical(_lastDocumentSource, documents) ||
        _lastAppliedQuery == null ||
        !_lastAppliedQuery!.hasSameValues(_documentQuery)) {
      _lastDocumentSource = documents;
      _lastAppliedQuery = _documentQuery;
      _visibleDocuments = _documentQuery.apply(documents);
    }
    return _visibleDocuments;
  }

  void _updateDocumentQuery(TripDocumentQuery query) {
    setState(() => _documentQuery = query);
  }

  void _resetDocumentFilters() {
    _searchController.clear();
    _updateDocumentQuery(const TripDocumentQuery());
  }

  bool _fileWasReplaced(TravelDocument? previous, TravelDocument current) {
    final currentPath = current.relativePath.trim();
    if (currentPath.isEmpty) {
      return false;
    }
    return previous?.relativePath.trim() != currentPath;
  }

  Future<bool> _deleteDocumentFileSilently(TravelDocument document) async {
    try {
      await widget.fileService.deleteDocumentFile(document);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteTripFilesSilently(String tripId) async {
    try {
      await widget.fileService.deleteTripFiles(tripId);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
