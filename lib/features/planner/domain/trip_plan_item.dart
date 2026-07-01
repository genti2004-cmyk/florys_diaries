import 'package:flutter/material.dart';

enum TripPlanItemType {
  activity,
  flight,
  hotel,
  restaurant,
  sight,
  transport,
}

extension TripPlanItemTypeX on TripPlanItemType {
  String get label {
    return switch (this) {
      TripPlanItemType.activity => 'Aktivität',
      TripPlanItemType.flight => 'Flug',
      TripPlanItemType.hotel => 'Hotel',
      TripPlanItemType.restaurant => 'Restaurant',
      TripPlanItemType.sight => 'Sehenswürdigkeit',
      TripPlanItemType.transport => 'Transport',
    };
  }

  IconData get icon {
    return switch (this) {
      TripPlanItemType.activity => Icons.auto_awesome_rounded,
      TripPlanItemType.flight => Icons.flight_rounded,
      TripPlanItemType.hotel => Icons.hotel_rounded,
      TripPlanItemType.restaurant => Icons.restaurant_rounded,
      TripPlanItemType.sight => Icons.account_balance_rounded,
      TripPlanItemType.transport => Icons.directions_transit_rounded,
    };
  }
}

class TripPlanItem {
  const TripPlanItem({
    required this.id,
    required this.title,
    required this.date,
    required this.startMinutes,
    required this.type,
    this.endMinutes,
    this.location = '',
    this.notes = '',
    this.isCompleted = false,
    this.linkedDocumentId,
    this.reminderMinutesBefore,
  });

  final String id;
  final String title;
  final DateTime date;
  final int startMinutes;
  final int? endMinutes;
  final TripPlanItemType type;
  final String location;
  final String notes;
  final bool isCompleted;
  final String? linkedDocumentId;
  final int? reminderMinutesBefore;

  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  int get sortValue => startMinutes.clamp(0, 1439).toInt();

  bool get hasEndTime => endMinutes != null;

  bool get hasReminder => reminderMinutesBefore != null;

  DateTime get startsAt => DateTime(
    date.year,
    date.month,
    date.day,
    startMinutes ~/ 60,
    startMinutes % 60,
  );

  DateTime? get reminderAt {
    final minutes = reminderMinutesBefore;
    return minutes == null ? null : startsAt.subtract(Duration(minutes: minutes));
  }

  String get reminderLabel {
    return switch (reminderMinutesBefore) {
      15 => '15 Minuten vorher',
      30 => '30 Minuten vorher',
      60 => '1 Stunde vorher',
      1440 => '1 Tag vorher',
      final int value => '$value Minuten vorher',
      null => 'Keine Erinnerung',
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': dateOnly.toIso8601String(),
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'type': type.name,
      'location': location,
      'notes': notes,
      'isCompleted': isCompleted,
      'linkedDocumentId': linkedDocumentId,
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  static TripPlanItem fromJson(Map<String, dynamic> json) {
    return TripPlanItem(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      date: _parseDate(json['date']) ?? DateTime.now(),
      startMinutes: _parseMinutes(json['startMinutes']) ?? 9 * 60,
      endMinutes: _parseMinutes(json['endMinutes']),
      type: _parseType(json['type']),
      location: (json['location'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      linkedDocumentId: json['linkedDocumentId'] as String?,
      reminderMinutesBefore: _parseReminderMinutes(
        json['reminderMinutesBefore'],
      ),
    );
  }

  TripPlanItem copyWith({
    String? id,
    String? title,
    DateTime? date,
    int? startMinutes,
    int? endMinutes,
    bool clearEndMinutes = false,
    TripPlanItemType? type,
    String? location,
    String? notes,
    bool? isCompleted,
    String? linkedDocumentId,
    bool clearLinkedDocument = false,
    int? reminderMinutesBefore,
    bool clearReminder = false,
  }) {
    return TripPlanItem(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: clearEndMinutes ? null : endMinutes ?? this.endMinutes,
      type: type ?? this.type,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedDocumentId: clearLinkedDocument
          ? null
          : linkedDocumentId ?? this.linkedDocumentId,
      reminderMinutesBefore: clearReminder
          ? null
          : reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }

  static TripPlanItemType _parseType(Object? value) {
    final name = value is String ? value : '';
    return TripPlanItemType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => TripPlanItemType.activity,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static int? _parseReminderMinutes(Object? value) {
    if (value is! num) {
      return null;
    }
    final minutes = value.toInt();
    return const <int>{15, 30, 60, 1440}.contains(minutes)
        ? minutes
        : null;
  }

  static int? _parseMinutes(Object? value) {
    if (value is! num) {
      return null;
    }
    final minutes = value.toInt();
    if (minutes < 0 || minutes > 1439) {
      return null;
    }
    return minutes;
  }
}
