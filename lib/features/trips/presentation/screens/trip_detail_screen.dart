import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/album/presentation/widgets/trip_album_section.dart';
import 'package:florys_diaries/features/documents/application/trip_document_query.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/documents/presentation/screens/document_detail_screen.dart';
import 'package:florys_diaries/features/documents/presentation/screens/document_editor_screen.dart';
import 'package:florys_diaries/features/planner/presentation/widgets/trip_planning_section.dart';
import 'package:florys_diaries/features/replay/presentation/screens/travel_replay_screen.dart';
import 'package:florys_diaries/features/report/presentation/screens/travel_report_screen.dart';
import 'package:florys_diaries/features/templates/data/trip_template_service.dart';
import 'package:florys_diaries/features/templates/domain/trip_template.dart';
import 'package:florys_diaries/features/templates/presentation/screens/trip_duplicate_screen.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/data/trip_export_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_detail_hero_card.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_detail_quick_actions.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_detail_snapshot_card.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_detail_timeline.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_vault_section.dart';

import 'trip_editor_screen.dart';

enum _TripDetailMenuAction {
  edit,
  report,
  export,
  duplicate,
  saveTemplate,
  delete,
}
enum TripDetailSection { overview, planning, documents, memories }

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({
    required this.trip,
    this.fileService = const TravelFileService(),
    this.exportService = const TripExportService(),
    this.initialSection = TripDetailSection.overview,
    super.key,
  });

  final Trip trip;
  final TravelFileService fileService;
  final TripExportService exportService;
  final TripDetailSection initialSection;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  late TripDetailSection _section;
  TripDocumentQuery _documentQuery = const TripDocumentQuery();
  List<TravelDocument>? _lastDocumentSource;
  TripDocumentQuery? _lastAppliedQuery;
  List<TravelDocument> _visibleDocuments = const <TravelDocument>[];

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _openReport(BuildContext context, Trip currentTrip) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TravelReportScreen(trip: currentTrip),
      ),
    );
  }

  Future<void> _duplicateTrip(BuildContext context, Trip currentTrip) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDuplicateScreen(sourceTrip: currentTrip),
      ),
    );
  }

  Future<void> _saveAsTemplate(
    BuildContext context,
    Trip currentTrip,
  ) async {
    final nameController = TextEditingController(
      text: '${currentTrip.title} Vorlage',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Als Vorlage speichern'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Vorlagenname'),
          onSubmitted: (value) =>
              Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(nameController.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (!context.mounted || name == null || name.trim().isEmpty) {
      return;
    }
    try {
      await const TripTemplateService().add(
        TripTemplate(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name.trim(),
          createdAt: DateTime.now(),
          sourceTrip: currentTrip,
        ),
      );
      if (context.mounted) {
        _showMessage(context, 'Reisevorlage wurde gespeichert.');
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Die Reisevorlage konnte nicht gespeichert werden.');
      }
    }
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
                case _TripDetailMenuAction.report:
                  unawaited(_openReport(context, currentTrip));
                  break;
                case _TripDetailMenuAction.export:
                  unawaited(_exportTrip(context, currentTrip));
                  break;
                case _TripDetailMenuAction.duplicate:
                  unawaited(_duplicateTrip(context, currentTrip));
                  break;
                case _TripDetailMenuAction.saveTemplate:
                  unawaited(_saveAsTemplate(context, currentTrip));
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
                value: _TripDetailMenuAction.report,
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Reisebericht & PDF'),
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
              PopupMenuItem(
                value: _TripDetailMenuAction.duplicate,
                child: ListTile(
                  leading: Icon(Icons.copy_all_outlined),
                  title: Text('Reise duplizieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _TripDetailMenuAction.saveTemplate,
                child: ListTile(
                  leading: Icon(Icons.collections_bookmark_outlined),
                  title: Text('Als Vorlage speichern'),
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
                    TripDetailSection.planning,
                  ),
                  onOpenDocuments: () => _selectSection(
                    TripDetailSection.documents,
                  ),
                  onOpenMemories: () => _selectSection(
                    TripDetailSection.memories,
                  ),
                ),
                _SectionListView(
                  keyValue: 'planning-${currentTrip.id}',
                  child: TripPlanningSection(trip: currentTrip),
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

  void _selectSection(TripDetailSection section) {
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

  final TripDetailSection selected;
  final ValueChanged<TripDetailSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SectionTab(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Übersicht',
                selected: selected == TripDetailSection.overview,
                onTap: () => onSelected(TripDetailSection.overview),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SectionTab(
                icon: Icons.event_note_outlined,
                selectedIcon: Icons.event_note_rounded,
                label: 'Planung',
                selected: selected == TripDetailSection.planning,
                onTap: () => onSelected(TripDetailSection.planning),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SectionTab(
                icon: Icons.folder_outlined,
                selectedIcon: Icons.folder_rounded,
                label: 'Dokumente',
                selected: selected == TripDetailSection.documents,
                onTap: () => onSelected(TripDetailSection.documents),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SectionTab(
                icon: Icons.favorite_border_rounded,
                selectedIcon: Icons.favorite_rounded,
                label: 'Momente',
                selected: selected == TripDetailSection.memories,
                onTap: () => onSelected(TripDetailSection.memories),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 21,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
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
        const SizedBox(height: 14),
        TripDetailSnapshotCard(trip: trip),
        const SizedBox(height: 24),
        Text(
          'Dein Reiseverlauf',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        Text(
          'Programmpunkte, Momente und Ausgaben chronologisch verbunden.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        TripDetailTimeline(
          trip: trip,
          onOpenPlanning: onOpenPlanning,
          onOpenMemories: onOpenMemories,
        ),
        const SizedBox(height: 24),
        Text(
          'Reise organisieren',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        Text(
          'Planung, Dateien und Momente sind hier direkt erreichbar.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        _JourneyHubCard(
          trip: trip,
          onOpenPlanning: onOpenPlanning,
          onOpenDocuments: onOpenDocuments,
          onOpenMemories: onOpenMemories,
        ),
        const SizedBox(height: 18),
        _NotesCard(trip: trip, onEdit: onEdit),
      ],
    );
  }
}

class _JourneyHubCard extends StatelessWidget {
  const _JourneyHubCard({
    required this.trip,
    required this.onOpenPlanning,
    required this.onOpenDocuments,
    required this.onOpenMemories,
  });

  final Trip trip;
  final VoidCallback onOpenPlanning;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenMemories;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _JourneyHubRow(
            icon: Icons.calendar_view_day_rounded,
            title: 'Planung',
            subtitle: _planningLabel(trip),
            status: trip.planItemCount == 0
                ? 'Starten'
                : '${trip.planItemCount}',
            onTap: onOpenPlanning,
          ),
          const Divider(height: 1),
          _JourneyHubRow(
            icon: Icons.folder_outlined,
            title: 'Dokumente',
            subtitle: trip.documentCount == 1
                ? '1 Datei sicher gespeichert'
                : '${trip.documentCount} Dateien sicher gespeichert',
            status: '${trip.documentCount}',
            onTap: onOpenDocuments,
          ),
          const Divider(height: 1),
          _JourneyHubRow(
            icon: Icons.favorite_border_rounded,
            title: 'Momente',
            subtitle: trip.albumEntryCount == 1
                ? '1 Eintrag im Reisetagebuch'
                : '${trip.albumEntryCount} Einträge im Reisetagebuch',
            status: '${trip.albumEntryCount}',
            onTap: onOpenMemories,
          ),
        ],
      ),
    );
  }

  static String _planningLabel(Trip trip) {
    final programCount = trip.planItemCount;
    final taskCount = trip.checklistItems.length;
    if (programCount == 0 && taskCount == 0) {
      return 'Tagesplan und Checkliste vorbereiten';
    }
    if (programCount == 0) {
      return '${trip.checklistCompletedCount} von $taskCount Aufgaben erledigt';
    }
    if (taskCount == 0) {
      return programCount == 1
          ? '1 Programmpunkt im Tagesplan'
          : '$programCount Programmpunkte im Tagesplan';
    }
    return '$programCount Programmpunkte · $taskCount Aufgaben';
  }
}

class _JourneyHubRow extends StatelessWidget {
  const _JourneyHubRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.primary, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
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
