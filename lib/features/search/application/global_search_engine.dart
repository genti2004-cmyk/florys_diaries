import 'dart:collection';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/search/domain/global_search_result.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class GlobalSearchEngine {
  const GlobalSearchEngine();

  List<GlobalSearchResult> buildIndex(Iterable<Trip> trips) {
    final results = <GlobalSearchResult>[];

    for (final trip in trips) {
      results
        ..add(_tripResult(trip))
        ..add(_tripPlaceResult(trip));

      for (final item in trip.planItems) {
        results.add(_planItemResult(trip, item));
        if (item.hasReminder) {
          results.add(_planReminderResult(trip, item));
        }
      }

      for (final document in trip.documents) {
        results.add(_documentResult(trip, document));
        if (document.hasExpiryReminder) {
          results.add(_documentReminderResult(trip, document));
        }
      }

      for (final entry in trip.albumEntries) {
        results.add(_memoryResult(trip, entry));
      }

      for (final expense in trip.budgetExpenses) {
        results.add(_expenseResult(trip, expense));
      }

      results.addAll(_locationResults(trip));
    }

    results.sort(_compareResults);
    return List<GlobalSearchResult>.unmodifiable(results);
  }

  List<GlobalSearchResult> search(
    Iterable<GlobalSearchResult> index, {
    String query = '',
    Set<GlobalSearchResultType> types = const <GlobalSearchResultType>{},
    String? tripId,
    int? year,
  }) {
    final normalizedQuery = normalize(query);
    final tokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    final matches = index.where((result) {
      if (types.isNotEmpty && !types.contains(result.type)) {
        return false;
      }
      if (tripId != null && tripId.isNotEmpty && result.tripId != tripId) {
        return false;
      }
      if (year != null && result.year != year) {
        return false;
      }
      if (tokens.isEmpty) {
        return true;
      }

      final haystack = normalize(result.searchableText);
      return tokens.every(haystack.contains);
    }).toList(growable: true);

    matches.sort((left, right) {
      final leftScore = _score(left, normalizedQuery, tokens);
      final rightScore = _score(right, normalizedQuery, tokens);
      final scoreComparison = rightScore.compareTo(leftScore);
      if (scoreComparison != 0) {
        return scoreComparison;
      }
      return _compareResults(left, right);
    });

    return List<GlobalSearchResult>.unmodifiable(matches);
  }

  Set<int> availableYears(Iterable<GlobalSearchResult> index) {
    final years = index.map((result) => result.year).toSet();
    return SplayTreeSet<int>.from(years, (left, right) => right.compareTo(left));
  }

  static String normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  static GlobalSearchResult _tripResult(Trip trip) {
    final subtitle = _joinNonEmpty(<String>[
      trip.destination,
      trip.country,
      _formatDateRange(trip.startDate, trip.endDate),
    ]);
    return GlobalSearchResult(
      id: 'trip:${trip.id}',
      type: GlobalSearchResultType.trip,
      target: GlobalSearchTarget.overview,
      tripId: trip.id,
      tripTitle: trip.title,
      title: _fallback(trip.title, 'Reise'),
      subtitle: subtitle,
      searchableText: _searchText(<String>[
        trip.title,
        trip.destination,
        trip.country,
        trip.notes,
        ...trip.participants.map((participant) => participant.name),
        subtitle,
        'Reise Urlaub Trip Reiseteilnehmer',
      ]),
      date: trip.startDate,
    );
  }

  static GlobalSearchResult _tripPlaceResult(Trip trip) {
    final title = _joinNonEmpty(<String>[trip.destination, trip.country]);
    return GlobalSearchResult(
      id: 'place:trip:${trip.id}',
      type: GlobalSearchResultType.place,
      target: GlobalSearchTarget.overview,
      tripId: trip.id,
      tripTitle: trip.title,
      title: title.isEmpty ? 'Reiseziel' : title,
      subtitle: 'Reiseziel · ${trip.title}',
      searchableText: _searchText(<String>[
        title,
        trip.destination,
        trip.country,
        trip.title,
        'Ort Land Reiseziel',
      ]),
      date: trip.startDate,
    );
  }

  static GlobalSearchResult _planItemResult(Trip trip, TripPlanItem item) {
    final time = _formatMinutes(item.startMinutes);
    final subtitle = _joinNonEmpty(<String>[
      item.type.label,
      '${_formatDate(item.date)} · $time',
      item.location,
    ]);
    return GlobalSearchResult(
      id: 'plan:${trip.id}:${item.id}',
      type: GlobalSearchResultType.planItem,
      target: GlobalSearchTarget.planning,
      tripId: trip.id,
      tripTitle: trip.title,
      title: _fallback(item.title, item.type.label),
      subtitle: subtitle,
      searchableText: _searchText(<String>[
        item.title,
        item.type.label,
        item.location,
        item.notes,
        item.reminderLabel,
        trip.title,
        trip.destination,
        trip.country,
        subtitle,
      ]),
      date: item.dateOnly,
    );
  }

  static GlobalSearchResult _documentResult(
    Trip trip,
    TravelDocument document,
  ) {
    final subtitle = _joinNonEmpty(<String>[
      document.category.label,
      document.fileTypeLabel,
      _formatDate(document.createdAt),
      trip.title,
    ]);
    return GlobalSearchResult(
      id: 'document:${trip.id}:${document.id}',
      type: GlobalSearchResultType.document,
      target: GlobalSearchTarget.documents,
      tripId: trip.id,
      tripTitle: trip.title,
      title: _fallback(document.title, document.category.label),
      subtitle: subtitle,
      searchableText: _searchText(<String>[
        document.title,
        document.description,
        document.fileName,
        document.fileExtension,
        document.category.label,
        trip.title,
        trip.destination,
        trip.country,
        subtitle,
      ]),
      date: document.createdAt,
    );
  }

  static GlobalSearchResult _memoryResult(Trip trip, TripAlbumEntry entry) {
    final type = TripAlbumEntryTypes.byId(entry.typeId);
    final subtitle = _joinNonEmpty(<String>[
      type.label,
      _formatDate(entry.date),
      entry.location,
    ]);
    return GlobalSearchResult(
      id: 'memory:${trip.id}:${entry.id}',
      type: GlobalSearchResultType.memory,
      target: GlobalSearchTarget.memories,
      tripId: trip.id,
      tripTitle: trip.title,
      title: _fallback(entry.title, type.label),
      subtitle: subtitle,
      searchableText: _searchText(<String>[
        entry.title,
        entry.description,
        entry.location,
        type.label,
        trip.title,
        trip.destination,
        trip.country,
        subtitle,
      ]),
      date: entry.date,
    );
  }

  static GlobalSearchResult _expenseResult(
    Trip trip,
    TripBudgetExpense expense,
  ) {
    final subtitle = _joinNonEmpty(<String>[
      expense.category.label,
      TripMoney.format(expense.amountCents, trip.budgetCurrency),
      expense.status.label,
      _formatDate(expense.dateOnly),
    ]);
    return GlobalSearchResult(
      id: 'expense:${trip.id}:${expense.id}',
      type: GlobalSearchResultType.expense,
      target: GlobalSearchTarget.planning,
      tripId: trip.id,
      tripTitle: trip.title,
      title: _fallback(expense.title, 'Ausgabe'),
      subtitle: subtitle,
      searchableText: _searchText(<String>[
        expense.title,
        expense.notes,
        expense.category.label,
        expense.status.label,
        trip.budgetCurrency,
        trip.title,
        trip.destination,
        trip.country,
        ...trip.participants.map((participant) => participant.name),
        subtitle,
      ]),
      date: expense.dateOnly,
    );
  }

  static GlobalSearchResult _planReminderResult(
    Trip trip,
    TripPlanItem item,
  ) {
    return GlobalSearchResult(
      id: 'reminder:plan:${trip.id}:${item.id}',
      type: GlobalSearchResultType.reminder,
      target: GlobalSearchTarget.planning,
      tripId: trip.id,
      tripTitle: trip.title,
      title: _fallback(item.title, 'Programmpunkt'),
      subtitle: '${item.reminderLabel} · ${_formatDate(item.date)}',
      searchableText: _searchText(<String>[
        item.title,
        item.type.label,
        item.location,
        item.notes,
        item.reminderLabel,
        trip.title,
        _formatDate(item.date),
        'Erinnerung Benachrichtigung',
      ]),
      date: item.reminderAt ?? item.startsAt,
    );
  }

  static GlobalSearchResult _documentReminderResult(
    Trip trip,
    TravelDocument document,
  ) {
    final expiresAt = document.expiresAt ?? document.createdAt;
    final days = document.expiryReminderDaysBefore ?? 0;
    return GlobalSearchResult(
      id: 'reminder:document:${trip.id}:${document.id}',
      type: GlobalSearchResultType.reminder,
      target: GlobalSearchTarget.documents,
      tripId: trip.id,
      tripTitle: trip.title,
      title: _fallback(document.title, 'Dokument'),
      subtitle: '$days Tage vor Ablauf · ${_formatDate(expiresAt)}',
      searchableText: _searchText(<String>[
        document.title,
        document.description,
        document.category.label,
        trip.title,
        _formatDate(expiresAt),
        'Dokument Erinnerung Ablauf Benachrichtigung',
      ]),
      date: expiresAt.subtract(Duration(days: days)),
    );
  }

  static Iterable<GlobalSearchResult> _locationResults(Trip trip) sync* {
    final seen = <String>{
      normalize(trip.destination),
      normalize(trip.country),
      normalize('${trip.destination} ${trip.country}'),
    }..removeWhere((value) => value.isEmpty);

    for (final item in trip.planItems) {
      final location = item.location.trim();
      final key = normalize(location);
      if (key.isEmpty || !seen.add(key)) {
        continue;
      }
      yield GlobalSearchResult(
        id: 'place:plan:${trip.id}:${item.id}',
        type: GlobalSearchResultType.place,
        target: GlobalSearchTarget.planning,
        tripId: trip.id,
        tripTitle: trip.title,
        title: location,
        subtitle: '${item.title} · ${trip.title}',
        searchableText: _searchText(<String>[
          location,
          item.title,
          item.type.label,
          trip.title,
          trip.country,
          _formatDate(item.date),
          'Ort Adresse',
        ]),
        date: item.dateOnly,
      );
    }

    for (final entry in trip.albumEntries) {
      final location = entry.location.trim();
      final key = normalize(location);
      if (key.isEmpty || !seen.add(key)) {
        continue;
      }
      yield GlobalSearchResult(
        id: 'place:memory:${trip.id}:${entry.id}',
        type: GlobalSearchResultType.place,
        target: GlobalSearchTarget.memories,
        tripId: trip.id,
        tripTitle: trip.title,
        title: location,
        subtitle: '${_fallback(entry.title, 'Moment')} · ${trip.title}',
        searchableText: _searchText(<String>[
          location,
          entry.title,
          entry.description,
          trip.title,
          trip.country,
          _formatDate(entry.date),
          'Ort Erinnerung',
        ]),
        date: entry.date,
      );
    }
  }

  static int _score(
    GlobalSearchResult result,
    String normalizedQuery,
    List<String> tokens,
  ) {
    if (normalizedQuery.isEmpty) {
      return 0;
    }
    final title = normalize(result.title);
    final subtitle = normalize(result.subtitle);
    var score = 0;
    if (title == normalizedQuery) {
      score += 100;
    } else if (title.startsWith(normalizedQuery)) {
      score += 70;
    } else if (title.contains(normalizedQuery)) {
      score += 50;
    }
    if (subtitle.contains(normalizedQuery)) {
      score += 20;
    }
    score += tokens.where(title.contains).length * 8;
    return score;
  }

  static int _compareResults(
    GlobalSearchResult left,
    GlobalSearchResult right,
  ) {
    final dateComparison = right.date.compareTo(left.date);
    if (dateComparison != 0) {
      return dateComparison;
    }
    final typeComparison = left.type.index.compareTo(right.type.index);
    if (typeComparison != 0) {
      return typeComparison;
    }
    return left.title.toLowerCase().compareTo(right.title.toLowerCase());
  }

  static String _searchText(Iterable<String> values) {
    return values.where((value) => value.trim().isNotEmpty).join(' ');
  }

  static String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _joinNonEmpty(Iterable<String> values) {
    return values.where((value) => value.trim().isNotEmpty).join(' · ');
  }

  static String _formatDateRange(DateTime start, DateTime end) {
    return '${_formatDate(start)} – ${_formatDate(end)}';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String _formatMinutes(int value) {
    final minutes = value.clamp(0, 1439).toInt();
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute Uhr';
  }
}
