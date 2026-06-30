import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
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
enum _TripDetailSection { overview, planning, documents, memories }

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

  _TripDetailSection _section = _TripDetailSection.overview;
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
      backgroundColor: AppColors.background,
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
      body: Column(
        children: [
          _TripSectionNavigation(
            selected: _section,
            onSelected: (section) => setState(() => _section = section),
          ),
          Expanded(
            child: IndexedStack(
              index: _section.index,
              children: [
                _OverviewPage(
                  trip: currentTrip,
                  onReplay: () => _openReplay(context, currentTrip),
                  onEdit: () => _editTrip(context, currentTrip),
                  onExport: () => _exportTrip(context, currentTrip),
                  onOpenPlanning: () => _selectSection(
                    _TripDetailSection.planning,
                  ),
                  onOpenDocuments: () => _selectSection(
                    _TripDetailSection.documents,
                  ),
                  onOpenMemories: () => _selectSection(
                    _TripDetailSection.memories,
                  ),
                ),
                _SectionListView(
                  keyValue: 'planning-${currentTrip.id}',
                  child: TripChecklistSection(trip: currentTrip),
                ),
                _SectionListView(
                  keyValue: 'documents-${currentTrip.id}',
                  child: TripVaultSection(
                    trip: currentTrip,
                    visibleDocuments: visibleDocuments,
                    searchController: _searchController,
                    query: _documentQuery,
                    onAddDocument: () =>
                        _openDocumentEditor(context, currentTrip),
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
                      _updateDocumentQuery(
                        _documentQuery.copyWith(sortMode: value),
                      );
                    },
                    onFavoritesChanged: (value) {
                      _updateDocumentQuery(
                        _documentQuery.copyWith(favoritesOnly: value),
                      );
                    },
                    onResetFilters: _resetDocumentFilters,
                  ),
                ),
                _SectionListView(
                  keyValue: 'memories-${currentTrip.id}',
                  child: TripAlbumSection(trip: currentTrip),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectSection(_TripDetailSection section) {
    setState(() => _section = section);
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

class _TripSectionNavigation extends StatelessWidget {
  const _TripSectionNavigation({
    required this.selected,
    required this.onSelected,
  });

  final _TripDetailSection selected;
  final ValueChanged<_TripDetailSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SectionChip(
                icon: Icons.dashboard_outlined,
                label: 'Übersicht',
                selected: selected == _TripDetailSection.overview,
                onTap: () => onSelected(_TripDetailSection.overview),
              ),
              const SizedBox(width: 8),
              _SectionChip(
                icon: Icons.checklist_rounded,
                label: 'Planung',
                selected: selected == _TripDetailSection.planning,
                onTap: () => onSelected(_TripDetailSection.planning),
              ),
              const SizedBox(width: 8),
              _SectionChip(
                icon: Icons.folder_outlined,
                label: 'Dokumente',
                selected: selected == _TripDetailSection.documents,
                onTap: () => onSelected(_TripDetailSection.documents),
              ),
              const SizedBox(width: 8),
              _SectionChip(
                icon: Icons.favorite_border_rounded,
                label: 'Momente',
                selected: selected == _TripDetailSection.memories,
                onTap: () => onSelected(_TripDetailSection.memories),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({
    required this.trip,
    required this.onReplay,
    required this.onEdit,
    required this.onExport,
    required this.onOpenPlanning,
    required this.onOpenDocuments,
    required this.onOpenMemories,
  });

  final Trip trip;
  final VoidCallback onReplay;
  final VoidCallback onEdit;
  final VoidCallback onExport;
  final VoidCallback onOpenPlanning;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenMemories;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: PageStorageKey<String>('overview-${trip.id}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        TripDetailHeroCard(trip: trip),
        const SizedBox(height: 14),
        TripDetailQuickActions(
          onReplay: onReplay,
          onEdit: onEdit,
          onExport: onExport,
        ),
        const SizedBox(height: 20),
        Text('Reise vorbereiten', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        _OverviewDestinationCard(
          icon: Icons.checklist_rounded,
          title: 'Planung',
          subtitle: _planningLabel(trip),
          onTap: onOpenPlanning,
        ),
        const SizedBox(height: 10),
        _OverviewDestinationCard(
          icon: Icons.folder_outlined,
          title: 'Dokumente',
          subtitle: trip.documentCount == 1
              ? '1 Dokument gespeichert'
              : '${trip.documentCount} Dokumente gespeichert',
          onTap: onOpenDocuments,
        ),
        const SizedBox(height: 10),
        _OverviewDestinationCard(
          icon: Icons.favorite_border_rounded,
          title: 'Momente',
          subtitle: trip.albumEntryCount == 1
              ? '1 Moment im Reisealbum'
              : '${trip.albumEntryCount} Momente im Reisealbum',
          onTap: onOpenMemories,
        ),
        const SizedBox(height: 20),
        _NotesCard(trip: trip, onEdit: onEdit),
      ],
    );
  }

  static String _planningLabel(Trip trip) {
    final total = trip.checklistItems.length;
    if (total == 0) {
      return 'Noch keine Aufgaben angelegt';
    }
    return '${trip.checklistCompletedCount} von $total Aufgaben erledigt';
  }
}

class _OverviewDestinationCard extends StatelessWidget {
  const _OverviewDestinationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.trip, required this.onEdit});

  final Trip trip;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes_rounded, color: AppColors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Notizen',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(onPressed: onEdit, child: const Text('Bearbeiten')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              trip.notes.trim().isEmpty
                  ? 'Noch keine persönlichen Notizen gespeichert.'
                  : trip.notes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: trip.notes.trim().isEmpty
                    ? AppColors.textMuted
                    : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionListView extends StatelessWidget {
  const _SectionListView({required this.keyValue, required this.child});

  final String keyValue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: PageStorageKey<String>(keyValue),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [child],
    );
  }
}
