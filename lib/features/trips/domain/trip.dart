import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/participants/domain/trip_participant.dart';

class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.country,
    required this.startDate,
    required this.endDate,
    this.notes = '',
    this.documents = const [],
    this.albumEntries = const [],
    this.checklistItems = const [],
    this.planItems = const [],
    this.budgetAmountCents = 0,
    this.budgetCurrency = 'EUR',
    this.budgetExpenses = const [],
    this.participants = const [],
    this.photoCount = 0,
  });

  final String id;
  final String title;
  final String destination;
  final String country;
  final DateTime startDate;
  final DateTime endDate;
  final String notes;
  final List<TravelDocument> documents;
  final List<TripAlbumEntry> albumEntries;
  final List<TripChecklistItem> checklistItems;
  final List<TripPlanItem> planItems;
  final int budgetAmountCents;
  final String budgetCurrency;
  final List<TripBudgetExpense> budgetExpenses;
  final List<TripParticipant> participants;
  final int photoCount;

  int get documentCount => documents.length;

  int get albumEntryCount => albumEntries.length;

  int get highlightCount {
    return albumEntries.where((entry) => entry.isHighlight).length;
  }

  int get checklistCompletedCount {
    return checklistItems.where((item) => item.isCompleted).length;
  }

  int get checklistOpenCount => checklistItems.length - checklistCompletedCount;

  int get planItemCount => planItems.length;

  int get planCompletedCount {
    return planItems.where((item) => item.isCompleted).length;
  }

  int get plannedDayCount {
    return planItems.map((item) => item.dateOnly).toSet().length;
  }

  int get paidExpenseCents {
    return budgetExpenses
        .where((expense) => expense.status == TripExpenseStatus.paid)
        .fold<int>(0, (sum, expense) => sum + expense.amountCents);
  }

  Set<String> get coveredPlannedExpenseIds {
    final paidKeys = budgetExpenses
        .where((expense) => expense.status == TripExpenseStatus.paid)
        .map(_budgetExpenseMatchKey)
        .toSet();

    return budgetExpenses
        .where(
          (expense) =>
              expense.status == TripExpenseStatus.planned &&
              paidKeys.contains(_budgetExpenseMatchKey(expense)),
        )
        .map((expense) => expense.id)
        .toSet();
  }

  int get plannedExpenseCents {
    final coveredIds = coveredPlannedExpenseIds;
    return budgetExpenses
        .where(
          (expense) =>
              expense.status == TripExpenseStatus.planned &&
              !coveredIds.contains(expense.id),
        )
        .fold<int>(0, (sum, expense) => sum + expense.amountCents);
  }

  int get totalExpenseCents => paidExpenseCents + plannedExpenseCents;

  int get actualRemainingBudgetCents =>
      budgetAmountCents - paidExpenseCents;

  int get forecastRemainingBudgetCents =>
      budgetAmountCents - totalExpenseCents;

  int get remainingBudgetCents => forecastRemainingBudgetCents;

  double get paidBudgetProgress {
    if (budgetAmountCents <= 0) {
      return 0;
    }
    return (paidExpenseCents / budgetAmountCents).clamp(0, 1).toDouble();
  }

  double get forecastBudgetProgress {
    if (budgetAmountCents <= 0) {
      return 0;
    }
    return (totalExpenseCents / budgetAmountCents).clamp(0, 1).toDouble();
  }

  double get budgetProgress => forecastBudgetProgress;

  int get checklistOverdueCount {
    return checklistItems.where((item) => item.isOverdue).length;
  }

  double get checklistProgress {
    if (checklistItems.isEmpty) {
      return 0;
    }
    return checklistCompletedCount / checklistItems.length;
  }

  int get durationDays {
    final difference = endDate.difference(startDate).inDays + 1;
    return difference < 1 ? 1 : difference;
  }

  bool get isPast {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return endOnly.isBefore(todayOnly);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'country': country,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'notes': notes,
      'documents': documents.map((document) => document.toJson()).toList(),
      'albumEntries': albumEntries.map((entry) => entry.toJson()).toList(),
      'checklistItems': checklistItems.map((item) => item.toJson()).toList(),
      'planItems': planItems.map((item) => item.toJson()).toList(),
      'budgetAmountCents': budgetAmountCents,
      'budgetCurrency': budgetCurrency,
      'budgetExpenses': budgetExpenses
          .map((expense) => expense.toJson())
          .toList(),
      'participants': participants
          .map((participant) => participant.toJson())
          .toList(),
      'photoCount': photoCount,
    };
  }

  static Trip fromJson(Map<String, dynamic> json) {
    return Trip(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      destination: (json['destination'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']) ?? DateTime.now(),
      notes: (json['notes'] as String?) ?? '',
      documents: _parseDocuments(json['documents']),
      albumEntries: _parseAlbumEntries(json['albumEntries']),
      checklistItems: _parseChecklistItems(json['checklistItems']),
      planItems: _parsePlanItems(json['planItems']),
      budgetAmountCents: _parseNonNegativeInt(json['budgetAmountCents']),
      budgetCurrency: TripMoney.normalizeCurrency(
        (json['budgetCurrency'] as String?) ?? 'EUR',
      ),
      budgetExpenses: _parseBudgetExpenses(json['budgetExpenses']),
      participants: _parseParticipants(json['participants']),
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
    );
  }

  Trip copyWith({
    String? id,
    String? title,
    String? destination,
    String? country,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    List<TravelDocument>? documents,
    List<TripAlbumEntry>? albumEntries,
    List<TripChecklistItem>? checklistItems,
    List<TripPlanItem>? planItems,
    int? budgetAmountCents,
    String? budgetCurrency,
    List<TripBudgetExpense>? budgetExpenses,
    List<TripParticipant>? participants,
    int? photoCount,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      country: country ?? this.country,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      documents: documents ?? this.documents,
      albumEntries: albumEntries ?? this.albumEntries,
      checklistItems: checklistItems ?? this.checklistItems,
      planItems: planItems ?? this.planItems,
      budgetAmountCents: budgetAmountCents ?? this.budgetAmountCents,
      budgetCurrency: budgetCurrency ?? this.budgetCurrency,
      budgetExpenses: budgetExpenses ?? this.budgetExpenses,
      participants: participants ?? this.participants,
      photoCount: photoCount ?? this.photoCount,
    );
  }

  static String _budgetExpenseMatchKey(TripBudgetExpense expense) {
    final title = expense.title.trim().toLowerCase();
    final date = expense.dateOnly.toIso8601String();
    return '$title|$date|${expense.amountCents}|${expense.category.name}';
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static List<TravelDocument> _parseDocuments(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(TravelDocument.fromJson)
        .where((document) => document.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  static List<TripAlbumEntry> _parseAlbumEntries(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(TripAlbumEntry.fromJson)
        .where((entry) => entry.id.trim().isNotEmpty)
        .toList(growable: false);
  }


  static List<TripPlanItem> _parsePlanItems(Object? value) {
    if (value is! List) {
      return const [];
    }

    final items = value
        .whereType<Map<String, dynamic>>()
        .map(TripPlanItem.fromJson)
        .where(
          (item) => item.id.trim().isNotEmpty && item.title.trim().isNotEmpty,
        )
        .toList(growable: true);
    items.sort((left, right) {
      final dateComparison = left.dateOnly.compareTo(right.dateOnly);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return left.sortValue.compareTo(right.sortValue);
    });
    return List<TripPlanItem>.unmodifiable(items);
  }


  static List<TripParticipant> _parseParticipants(Object? value) {
    if (value is! List) {
      return const [];
    }
    final participants = value
        .whereType<Map<String, dynamic>>()
        .map(TripParticipant.fromJson)
        .where(
          (participant) =>
              participant.id.trim().isNotEmpty &&
              participant.name.trim().isNotEmpty,
        )
        .toList(growable: true);
    final ids = <String>{};
    participants.removeWhere((participant) => !ids.add(participant.id));
    return List<TripParticipant>.unmodifiable(participants);
  }

  static List<TripBudgetExpense> _parseBudgetExpenses(Object? value) {
    if (value is! List) {
      return const [];
    }

    final expenses = value
        .whereType<Map<String, dynamic>>()
        .map(TripBudgetExpense.fromJson)
        .where(
          (expense) =>
              expense.id.trim().isNotEmpty &&
              expense.title.trim().isNotEmpty &&
              expense.amountCents > 0,
        )
        .toList(growable: true);
    expenses.sort((left, right) {
      final dateComparison = right.dateOnly.compareTo(left.dateOnly);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return left.title.compareTo(right.title);
    });
    return List<TripBudgetExpense>.unmodifiable(expenses);
  }

  static int _parseNonNegativeInt(Object? value) {
    if (value is! num) {
      return 0;
    }
    final parsed = value.toInt();
    return parsed < 0 ? 0 : parsed;
  }

  static List<TripChecklistItem> _parseChecklistItems(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(TripChecklistItem.fromJson)
        .where(
          (item) => item.id.trim().isNotEmpty && item.title.trim().isNotEmpty,
        )
        .toList(growable: false);
  }
}
