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
        gradient: [Color(0xFFF4A46B), Color(0xFFDA6B79), Color(0xFF2D466C)],
        accent: Color(0xFFFFE1B3),
        highlight: Color(0xFFFFF4D6),
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
        gradient: [Color(0xFF182848), Color(0xFF274B7A), Color(0xFF6C8FD9)],
        accent: Color(0xFFD8E6FF),
        highlight: Color(0xFFF4F8FF),
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
        gradient: [Color(0xFF8F5E3B), Color(0xFFC28258), Color(0xFFE6C39A)],
        accent: Color(0xFFFFE8C8),
        highlight: Color(0xFFFFF6E8),
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
        gradient: [Color(0xFF153B44), Color(0xFF2D6D73), Color(0xFF7FB1A2)],
        accent: Color(0xFFDDF6EE),
        highlight: Color(0xFFF1FFFA),
        icon: Icons.terrain_rounded,
      );
    }

    return const TravelVisualPalette(
      gradient: [Color(0xFF11203B), Color(0xFF173B68), Color(0xFF507CC6)],
      accent: Color(0xFFDCE8FF),
      highlight: Color(0xFFF4F8FF),
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
