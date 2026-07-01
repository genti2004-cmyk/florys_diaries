import 'package:flutter/material.dart';

class TravelVisualPalette {
  const TravelVisualPalette({
    required this.gradient,
    required this.accent,
    required this.highlight,
    required this.icon,
  });

  final List<Color> gradient;
  final Color accent;
  final Color highlight;
  final IconData icon;
}

class TravelVisuals {
  const TravelVisuals._();

  static TravelVisualPalette forText(String text) {
    final normalized = text.toLowerCase();

    if (_matches(normalized, const [
      'santorini',
      'griechen',
      'greece',
      'bali',
      'indones',
      'thailand',
      'beach',
      'island',
      'meer',
      'coast',
      'küste',
      'maled',
      'ibiza',
      'mallorca',
    ])) {
      return const TravelVisualPalette(
        gradient: [Color(0xFFF0B37B), Color(0xFFD8868D), Color(0xFF2F4D71)],
        accent: Color(0xFFFFE4C2),
        highlight: Color(0xFFFFF6E0),
        icon: Icons.wb_sunny_rounded,
      );
    }

    if (_matches(normalized, const [
      'dubai',
      'new york',
      'tokyo',
      'singapur',
      'singapore',
      'city',
      'uae',
      'usa',
      'metropol',
      'skyline',
    ])) {
      return const TravelVisualPalette(
        gradient: [Color(0xFF1A2842), Color(0xFF355B8A), Color(0xFF7C97D7)],
        accent: Color(0xFFDCE8FF),
        highlight: Color(0xFFF7FAFF),
        icon: Icons.location_city_rounded,
      );
    }

    if (_matches(normalized, const [
      'ital',
      'rome',
      'venedig',
      'venice',
      'florenz',
      'paris',
      'frankreich',
      'spain',
      'barcelona',
      'portugal',
    ])) {
      return const TravelVisualPalette(
        gradient: [Color(0xFF8C5C3E), Color(0xFFC78A60), Color(0xFFE8C9A8)],
        accent: Color(0xFFFFEBD2),
        highlight: Color(0xFFFFF8ED),
        icon: Icons.castle_rounded,
      );
    }

    if (_matches(normalized, const [
      'schweiz',
      'swiss',
      'alpen',
      'alps',
      'berg',
      'mountain',
      'norway',
      'islande',
      'iceland',
      'canada',
    ])) {
      return const TravelVisualPalette(
        gradient: [Color(0xFF183D48), Color(0xFF356F76), Color(0xFF89B6A6)],
        accent: Color(0xFFE3F7F0),
        highlight: Color(0xFFF4FFFB),
        icon: Icons.terrain_rounded,
      );
    }

    return const TravelVisualPalette(
      gradient: [Color(0xFF13223C), Color(0xFF244B77), Color(0xFF6889CB)],
      accent: Color(0xFFE2EBFF),
      highlight: Color(0xFFF7FAFF),
      icon: Icons.travel_explore_rounded,
    );
  }

  static String formatDateRange(DateTime startDate, DateTime endDate) {
    return '${formatDate(startDate)} – ${formatDate(endDate)}';
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String formatMonthYear(DateTime date) {
    const months = <String>[
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 11) {
      return 'Guten Morgen';
    }
    if (hour < 17) {
      return 'Guten Tag';
    }
    return 'Guten Abend';
  }

  static bool _matches(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
