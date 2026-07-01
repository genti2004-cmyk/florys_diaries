import 'dart:async';

import 'package:flutter/material.dart';

import 'package:florys_diaries/features/search/application/global_search_engine.dart';
import 'package:florys_diaries/features/search/data/search_history_service.dart';
import 'package:florys_diaries/features/search/domain/global_search_result.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/screens/trip_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({
    this.engine = const GlobalSearchEngine(),
    this.historyService = const SearchHistoryService(),
    super.key,
  });

  final GlobalSearchEngine engine;
  final SearchHistoryService historyService;

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Set<GlobalSearchResultType> _selectedTypes =
      <GlobalSearchResultType>{};

  List<String> _history = const <String>[];
  String _query = '';
  String? _selectedTripId;
  int? _selectedYear;
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await widget.historyService.load();
    if (!mounted) {
      return;
    }
    setState(() => _history = history);
  }

  Future<void> _rememberQuery([String? value]) async {
    final query = (value ?? _query).trim();
    if (query.isEmpty) {
      return;
    }
    final history = await widget.historyService.add(query);
    if (!mounted) {
      return;
    }
    setState(() => _history = history);
  }

  Future<void> _clearHistory() async {
    await widget.historyService.clear();
    if (!mounted) {
      return;
    }
    setState(() => _history = const <String>[]);
  }

  void _applyHistory(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() => _query = value);
    _focusNode.requestFocus();
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  void _resetFilters() {
    setState(() {
      _selectedTypes.clear();
      _selectedTripId = null;
      _selectedYear = null;
    });
  }

  Future<void> _openResult(
    BuildContext context,
    GlobalSearchResult result,
    List<Trip> trips,
  ) async {
    final trip = trips.where((item) => item.id == result.tripId).firstOrNull;
    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Die zugehörige Reise wurde nicht gefunden.')),
      );
      return;
    }

    unawaited(_rememberQuery());
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripDetailScreen(
          trip: trip,
          initialSection: _sectionFor(result.target),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final trips = store.trips;
    final index = widget.engine.buildIndex(trips);
    final years = widget.engine.availableYears(index).toList(growable: false);
    final hasActiveFilters =
        _selectedTypes.isNotEmpty ||
        _selectedTripId != null ||
        _selectedYear != null;
    final shouldSearch = _query.trim().isNotEmpty || hasActiveFilters;
    final results = shouldSearch
        ? widget.engine.search(
            index,
            query: _query,
            types: _selectedTypes,
            tripId: _selectedTripId,
            year: _selectedYear,
          )
        : const <GlobalSearchResult>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Globale Suche'),
        actions: [
          IconButton(
            tooltip: _showAdvancedFilters ? 'Filter schließen' : 'Mehr Filter',
            onPressed: () {
              setState(() => _showAdvancedFilters = !_showAdvancedFilters);
            },
            icon: Badge(
              isLabelVisible:
                  _selectedTripId != null || _selectedYear != null,
              child: Icon(
                _showAdvancedFilters
                    ? Icons.filter_alt_rounded
                    : Icons.filter_alt_outlined,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _SearchControls(
              controller: _controller,
              focusNode: _focusNode,
              query: _query,
              selectedTypes: _selectedTypes,
              selectedTripId: _selectedTripId,
              selectedYear: _selectedYear,
              trips: trips,
              years: years,
              showAdvancedFilters: _showAdvancedFilters,
              onQueryChanged: (value) => setState(() => _query = value),
              onSubmitted: (value) => unawaited(_rememberQuery(value)),
              onClear: _clearSearch,
              onTypeChanged: (type) {
                setState(() {
                  if (!_selectedTypes.add(type)) {
                    _selectedTypes.remove(type);
                  }
                });
              },
              onAllTypesSelected: () {
                setState(() => _selectedTypes.clear());
              },
              onTripChanged: (value) {
                setState(() => _selectedTripId = value);
              },
              onYearChanged: (value) {
                setState(() => _selectedYear = value);
              },
              onResetFilters: _resetFilters,
            ),
            Expanded(
              child: _SearchBody(
                query: _query,
                history: _history,
                hasActiveFilters: hasActiveFilters,
                totalIndexedItems: index.length,
                results: results,
                onHistorySelected: _applyHistory,
                onClearHistory: () => unawaited(_clearHistory()),
                onResultTap: (result) {
                  unawaited(_openResult(context, result, trips));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TripDetailSection _sectionFor(GlobalSearchTarget target) {
    return switch (target) {
      GlobalSearchTarget.overview => TripDetailSection.overview,
      GlobalSearchTarget.planning => TripDetailSection.planning,
      GlobalSearchTarget.documents => TripDetailSection.documents,
      GlobalSearchTarget.memories => TripDetailSection.memories,
    };
  }
}

class _SearchControls extends StatelessWidget {
  const _SearchControls({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.selectedTypes,
    required this.selectedTripId,
    required this.selectedYear,
    required this.trips,
    required this.years,
    required this.showAdvancedFilters,
    required this.onQueryChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onTypeChanged,
    required this.onAllTypesSelected,
    required this.onTripChanged,
    required this.onYearChanged,
    required this.onResetFilters,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final Set<GlobalSearchResultType> selectedTypes;
  final String? selectedTripId;
  final int? selectedYear;
  final List<Trip> trips;
  final List<int> years;
  final bool showAdvancedFilters;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final ValueChanged<GlobalSearchResultType> onTypeChanged;
  final VoidCallback onAllTypesSelected;
  final ValueChanged<String?> onTripChanged;
  final ValueChanged<int?> onYearChanged;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;
    final hasAdvancedFilter = selectedTripId != null || selectedYear != null;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey<String>('global-search-field'),
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Reisen, Dokumente, Orte, Ausgaben …',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Suche löschen',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: onQueryChanged,
              onSubmitted: onSubmitted,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    selected: selectedTypes.isEmpty,
                    onSelected: (_) => onAllTypesSelected(),
                    avatar: const Icon(Icons.apps_rounded, size: 16),
                    label: const Text('Alle'),
                  ),
                  const SizedBox(width: 8),
                  ...GlobalSearchResultType.values.expand(
                    (type) => <Widget>[
                      FilterChip(
                        selected: selectedTypes.contains(type),
                        onSelected: (_) => onTypeChanged(type),
                        avatar: Icon(_iconForType(type), size: 16),
                        label: Text(type.label),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: showAdvancedFilters
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: palette.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String?>(
                        key: ValueKey<String>(
                          'global-search-trip-${selectedTripId ?? "all"}',
                        ),
                        initialValue: selectedTripId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Reise',
                          prefixIcon: Icon(Icons.luggage_outlined),
                        ),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Alle Reisen'),
                          ),
                          ...trips.map(
                            (trip) => DropdownMenuItem<String?>(
                              value: trip.id,
                              child: Text(
                                trip.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: onTripChanged,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int?>(
                        key: ValueKey<String>(
                          'global-search-year-${selectedYear ?? "all"}',
                        ),
                        initialValue: selectedYear,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Jahr',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        items: <DropdownMenuItem<int?>>[
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Alle Jahre'),
                          ),
                          ...years.map(
                            (year) => DropdownMenuItem<int?>(
                              value: year,
                              child: Text(year.toString()),
                            ),
                          ),
                        ],
                        onChanged: onYearChanged,
                      ),
                      if (hasAdvancedFilter || selectedTypes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: onResetFilters,
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text('Filter zurücksetzen'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.query,
    required this.history,
    required this.hasActiveFilters,
    required this.totalIndexedItems,
    required this.results,
    required this.onHistorySelected,
    required this.onClearHistory,
    required this.onResultTap,
  });

  final String query;
  final List<String> history;
  final bool hasActiveFilters;
  final int totalIndexedItems;
  final List<GlobalSearchResult> results;
  final ValueChanged<String> onHistorySelected;
  final VoidCallback onClearHistory;
  final ValueChanged<GlobalSearchResult> onResultTap;

  @override
  Widget build(BuildContext context) {
    final shouldSearch = query.trim().isNotEmpty || hasActiveFilters;
    if (!shouldSearch) {
      return _SearchWelcome(
        history: history,
        totalIndexedItems: totalIndexedItems,
        onHistorySelected: onHistorySelected,
        onClearHistory: onClearHistory,
      );
    }

    if (results.isEmpty) {
      return _NoSearchResults(query: query);
    }

    return ListView(
      key: const PageStorageKey<String>('global-search-results'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _ResultSummary(count: results.length, query: query),
        const SizedBox(height: 14),
        for (final type in GlobalSearchResultType.values)
          if (results.any((result) => result.type == type)) ...[
            _ResultGroupHeader(
              type: type,
              count: results.where((result) => result.type == type).length,
            ),
            const SizedBox(height: 8),
            ...results
                .where((result) => result.type == type)
                .map(
                  (result) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SearchResultCard(
                      result: result,
                      onTap: () => onResultTap(result),
                    ),
                  ),
                ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _SearchWelcome extends StatelessWidget {
  const _SearchWelcome({
    required this.history,
    required this.totalIndexedItems,
    required this.onHistorySelected,
    required this.onClearHistory,
  });

  final List<String> history;
  final int totalIndexedItems;
  final ValueChanged<String> onHistorySelected;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.primaryContainer,
                palette.secondaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: palette.surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.manage_search_rounded,
                  color: palette.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Alles in FlorysDiaries finden',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 7),
              Text(
                'Durchsuche Reisen, Programmpunkte, Dokumente, Momente, Ausgaben, Erinnerungen und Orte – vollständig offline.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Text(
                '$totalIndexedItems Inhalte sind lokal durchsuchbar.',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: palette.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Letzte Suchanfragen',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: onClearHistory,
                child: const Text('Löschen'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history
                .map(
                  (value) => ActionChip(
                    avatar: const Icon(Icons.history_rounded, size: 16),
                    label: Text(value),
                    onPressed: () => onHistorySelected(value),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 22),
        Text('Suchbeispiele', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        const _SearchHint(
          icon: Icons.flight_rounded,
          title: 'Flug oder Hotel',
          subtitle: 'Findet Buchungen, Dokumente und Programmpunkte.',
        ),
        const SizedBox(height: 10),
        const _SearchHint(
          icon: Icons.place_rounded,
          title: 'Paris, Berlin oder Lieblingsrestaurant',
          subtitle: 'Findet Reiseziele und gespeicherte Orte.',
        ),
        const SizedBox(height: 10),
        const _SearchHint(
          icon: Icons.receipt_long_rounded,
          title: 'Museum oder 2026',
          subtitle: 'Findet Ausgaben und Inhalte aus einem bestimmten Jahr.',
        ),
      ],
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: palette.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.count, required this.query});

  final int count;
  final String query;

  @override
  Widget build(BuildContext context) {
    final label = query.trim().isEmpty
        ? '$count gefilterte Treffer'
        : '$count Treffer für „${query.trim()}“';
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ResultGroupHeader extends StatelessWidget {
  const _ResultGroupHeader({required this.type, required this.count});

  final GlobalSearchResultType type;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(_iconForType(type), size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(type.label, style: theme.textTheme.titleMedium),
        ),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.result, required this.onTap});

  final GlobalSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;

    return Card(
      child: InkWell(
        key: ValueKey<String>('global-search-result-${result.id}'),
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _colorForType(result.type, palette)
                      .withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconForType(result.type),
                  color: _colorForType(result.type, palette),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (result.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.luggage_outlined,
                          size: 14,
                          color: palette.primary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            result.tripTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: palette.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(result.date),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: palette.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 42),
        Icon(
          Icons.search_off_rounded,
          size: 58,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          'Keine Treffer gefunden',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          query.trim().isEmpty
              ? 'Passe die ausgewählten Filter an.'
              : 'Prüfe die Schreibweise oder wähle weniger Filter.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

IconData _iconForType(GlobalSearchResultType type) {
  return switch (type) {
    GlobalSearchResultType.trip => Icons.flight_takeoff_rounded,
    GlobalSearchResultType.planItem => Icons.event_note_rounded,
    GlobalSearchResultType.document => Icons.description_rounded,
    GlobalSearchResultType.memory => Icons.favorite_rounded,
    GlobalSearchResultType.expense => Icons.receipt_long_rounded,
    GlobalSearchResultType.reminder => Icons.notifications_active_rounded,
    GlobalSearchResultType.place => Icons.place_rounded,
  };
}

Color _colorForType(GlobalSearchResultType type, ColorScheme palette) {
  return switch (type) {
    GlobalSearchResultType.trip => palette.primary,
    GlobalSearchResultType.planItem => palette.secondary,
    GlobalSearchResultType.document => const Color(0xFF6E76C9),
    GlobalSearchResultType.memory => const Color(0xFFB65D7D),
    GlobalSearchResultType.expense => const Color(0xFFC1812C),
    GlobalSearchResultType.reminder => const Color(0xFFCE5D55),
    GlobalSearchResultType.place => const Color(0xFF348D7F),
  };
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
