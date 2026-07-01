import 'package:flutter/material.dart';

enum TripExpenseCategory {
  accommodation,
  transport,
  food,
  activities,
  shopping,
  health,
  other,
}

extension TripExpenseCategoryX on TripExpenseCategory {
  String get label {
    return switch (this) {
      TripExpenseCategory.accommodation => 'Unterkunft',
      TripExpenseCategory.transport => 'Transport',
      TripExpenseCategory.food => 'Essen',
      TripExpenseCategory.activities => 'Aktivitäten',
      TripExpenseCategory.shopping => 'Shopping',
      TripExpenseCategory.health => 'Gesundheit',
      TripExpenseCategory.other => 'Sonstiges',
    };
  }

  IconData get icon {
    return switch (this) {
      TripExpenseCategory.accommodation => Icons.hotel_rounded,
      TripExpenseCategory.transport => Icons.directions_transit_rounded,
      TripExpenseCategory.food => Icons.restaurant_rounded,
      TripExpenseCategory.activities => Icons.local_activity_rounded,
      TripExpenseCategory.shopping => Icons.shopping_bag_rounded,
      TripExpenseCategory.health => Icons.health_and_safety_rounded,
      TripExpenseCategory.other => Icons.receipt_long_rounded,
    };
  }
}

enum TripExpenseStatus { planned, paid }

extension TripExpenseStatusX on TripExpenseStatus {
  String get label {
    return switch (this) {
      TripExpenseStatus.planned => 'Geplant',
      TripExpenseStatus.paid => 'Bezahlt',
    };
  }

  IconData get icon {
    return switch (this) {
      TripExpenseStatus.planned => Icons.schedule_rounded,
      TripExpenseStatus.paid => Icons.check_circle_rounded,
    };
  }
}

class TripBudgetExpense {
  const TripBudgetExpense({
    required this.id,
    required this.title,
    required this.date,
    required this.amountCents,
    required this.category,
    this.status = TripExpenseStatus.planned,
    this.notes = '',
  });

  final String id;
  final String title;
  final DateTime date;
  final int amountCents;
  final TripExpenseCategory category;
  final TripExpenseStatus status;
  final String notes;

  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  bool get isPaid => status == TripExpenseStatus.paid;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': dateOnly.toIso8601String(),
      'amountCents': amountCents,
      'category': category.name,
      'status': status.name,
      'notes': notes,
    };
  }

  static TripBudgetExpense fromJson(Map<String, dynamic> json) {
    return TripBudgetExpense(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      date: _parseDate(json['date']) ?? DateTime.now(),
      amountCents: _parseAmount(json['amountCents']),
      category: _parseCategory(json['category']),
      status: _parseStatus(json['status']),
      notes: (json['notes'] as String?) ?? '',
    );
  }

  TripBudgetExpense copyWith({
    String? id,
    String? title,
    DateTime? date,
    int? amountCents,
    TripExpenseCategory? category,
    TripExpenseStatus? status,
    String? notes,
  }) {
    return TripBudgetExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      amountCents: amountCents ?? this.amountCents,
      category: category ?? this.category,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static int _parseAmount(Object? value) {
    if (value is! num) {
      return 0;
    }
    final amount = value.toInt();
    return amount < 0 ? 0 : amount;
  }

  static TripExpenseCategory _parseCategory(Object? value) {
    final name = value is String ? value : '';
    return TripExpenseCategory.values.firstWhere(
      (category) => category.name == name,
      orElse: () => TripExpenseCategory.other,
    );
  }

  static TripExpenseStatus _parseStatus(Object? value) {
    final name = value is String ? value : '';
    return TripExpenseStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => TripExpenseStatus.planned,
    );
  }
}

class TripMoney {
  const TripMoney._();

  static const List<String> supportedCurrencies = [
    'EUR',
    'USD',
    'GBP',
    'CHF',
    'ALL',
  ];

  static String normalizeCurrency(String value) {
    final normalized = value.trim().toUpperCase();
    return supportedCurrencies.contains(normalized) ? normalized : 'EUR';
  }

  static String format(int cents, String currency) {
    final normalizedCurrency = normalizeCurrency(currency);
    final isNegative = cents < 0;
    final absolute = cents.abs();
    final whole = absolute ~/ 100;
    final decimals = (absolute % 100).toString().padLeft(2, '0');
    final groupedWhole = _groupThousands(whole);
    final amount = '${isNegative ? '-' : ''}$groupedWhole,$decimals';

    return switch (normalizedCurrency) {
      'EUR' => '$amount €',
      'USD' => '$amount USD',
      'GBP' => '$amount GBP',
      'CHF' => '$amount CHF',
      'ALL' => '$amount ALL',
      _ => '$amount $normalizedCurrency',
    };
  }

  static int? parseToCents(String input) {
    var value = input.trim();
    if (value.isEmpty) {
      return null;
    }

    value = value.replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (value.isEmpty || value.startsWith('-')) {
      return null;
    }

    final commaIndex = value.lastIndexOf(',');
    final dotIndex = value.lastIndexOf('.');
    final decimalIndex = commaIndex > dotIndex ? commaIndex : dotIndex;

    if (decimalIndex >= 0) {
      final fractionLength = value.length - decimalIndex - 1;
      if (fractionLength <= 2) {
        final whole = value.substring(0, decimalIndex).replaceAll(
          RegExp(r'[,.]'),
          '',
        );
        final fraction = value.substring(decimalIndex + 1);
        value = '$whole.${fraction.padRight(2, '0')}';
      } else {
        value = value.replaceAll(RegExp(r'[,.]'), '');
      }
    }

    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return (parsed * 100).round();
  }

  static String _groupThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}
