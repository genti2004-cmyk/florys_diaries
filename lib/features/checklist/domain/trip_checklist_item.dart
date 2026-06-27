import 'package:flutter/material.dart';

enum TripChecklistCategory { documents, luggage, bookings, health, other }

extension TripChecklistCategoryX on TripChecklistCategory {
  String get label {
    return switch (this) {
      TripChecklistCategory.documents => 'Dokumente',
      TripChecklistCategory.luggage => 'Gepäck',
      TripChecklistCategory.bookings => 'Buchungen',
      TripChecklistCategory.health => 'Gesundheit',
      TripChecklistCategory.other => 'Sonstiges',
    };
  }

  IconData get icon {
    return switch (this) {
      TripChecklistCategory.documents => Icons.badge_outlined,
      TripChecklistCategory.luggage => Icons.luggage_outlined,
      TripChecklistCategory.bookings => Icons.confirmation_number_outlined,
      TripChecklistCategory.health => Icons.health_and_safety_outlined,
      TripChecklistCategory.other => Icons.check_circle_outline_rounded,
    };
  }
}

enum TripChecklistPriority { high, medium, low }

extension TripChecklistPriorityX on TripChecklistPriority {
  String get label {
    return switch (this) {
      TripChecklistPriority.high => 'Hoch',
      TripChecklistPriority.medium => 'Mittel',
      TripChecklistPriority.low => 'Niedrig',
    };
  }

  int get weight {
    return switch (this) {
      TripChecklistPriority.high => 3,
      TripChecklistPriority.medium => 2,
      TripChecklistPriority.low => 1,
    };
  }
}

class TripChecklistItem {
  const TripChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.notes = '',
    this.dueDate,
    this.isCompleted = false,
    this.sourceKey,
  });

  final String id;
  final String title;
  final TripChecklistCategory category;
  final TripChecklistPriority priority;
  final DateTime createdAt;
  final String notes;
  final DateTime? dueDate;
  final bool isCompleted;
  final String? sourceKey;

  bool get isOverdue {
    final due = dueDate;
    if (isCompleted || due == null) {
      return false;
    }
    return _dateOnly(due).isBefore(_dateOnly(DateTime.now()));
  }

  bool get isDueSoon {
    final due = dueDate;
    if (isCompleted || due == null || isOverdue) {
      return false;
    }
    final difference = _dateOnly(
      due,
    ).difference(_dateOnly(DateTime.now())).inDays;
    return difference <= 3;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'sourceKey': sourceKey,
    };
  }

  static TripChecklistItem fromJson(Map<String, dynamic> json) {
    return TripChecklistItem(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      category: _parseCategory(json['category']),
      priority: _parsePriority(json['priority']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      notes: (json['notes'] as String?) ?? '',
      dueDate: _parseDate(json['dueDate']),
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      sourceKey: json['sourceKey'] as String?,
    );
  }

  TripChecklistItem copyWith({
    String? id,
    String? title,
    TripChecklistCategory? category,
    TripChecklistPriority? priority,
    DateTime? createdAt,
    String? notes,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
    String? sourceKey,
  }) {
    return TripChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      sourceKey: sourceKey ?? this.sourceKey,
    );
  }

  static TripChecklistCategory _parseCategory(Object? value) {
    final name = value is String ? value : '';
    return TripChecklistCategory.values.firstWhere(
      (category) => category.name == name,
      orElse: () => TripChecklistCategory.other,
    );
  }

  static TripChecklistPriority _parsePriority(Object? value) {
    final name = value is String ? value : '';
    return TripChecklistPriority.values.firstWhere(
      (priority) => priority.name == name,
      orElse: () => TripChecklistPriority.medium,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
