import 'package:flutter/material.dart';

enum AppThemePreset { standard, dark, rose, ocean }

extension AppThemePresetX on AppThemePreset {
  String get label {
    return switch (this) {
      AppThemePreset.standard => 'Standard',
      AppThemePreset.dark => 'Dunkel',
      AppThemePreset.rose => 'Rose',
      AppThemePreset.ocean => 'Ocean',
    };
  }

  String get description {
    return switch (this) {
      AppThemePreset.standard => 'Das aktuelle Premium-Design',
      AppThemePreset.dark => 'Nachtblau mit hellen Akzenten',
      AppThemePreset.rose => 'Rose mit elegantem Violett',
      AppThemePreset.ocean => 'Blau mit ruhigem Türkis',
    };
  }

  IconData get icon {
    return switch (this) {
      AppThemePreset.standard => Icons.auto_awesome_rounded,
      AppThemePreset.dark => Icons.dark_mode_rounded,
      AppThemePreset.rose => Icons.favorite_rounded,
      AppThemePreset.ocean => Icons.water_rounded,
    };
  }

  bool get isDark => this == AppThemePreset.dark;

  AppThemePalette get palette {
    return switch (this) {
      AppThemePreset.standard => const AppThemePalette(
        primary: Color(0xFF2D5BDE),
        primarySoft: Color(0xFFEAF1FF),
        secondary: Color(0xFF6E9E96),
        background: Color(0xFFF5F7FB),
        surface: Color(0xFFFFFFFF),
        surfaceSoft: Color(0xFFF4F6FA),
        text: Color(0xFF101827),
        textMuted: Color(0xFF667085),
        border: Color(0xFFE4E9F2),
      ),
      AppThemePreset.dark => const AppThemePalette(
        primary: Color(0xFF91AEFF),
        primarySoft: Color(0xFF1D315A),
        secondary: Color(0xFF76B9AE),
        background: Color(0xFF080F1A),
        surface: Color(0xFF111B2A),
        surfaceSoft: Color(0xFF182538),
        text: Color(0xFFF5F7FC),
        textMuted: Color(0xFFAEB9CB),
        border: Color(0xFF293A52),
      ),
      AppThemePreset.rose => const AppThemePalette(
        primary: Color(0xFFB65D7D),
        primarySoft: Color(0xFFF8E8EF),
        secondary: Color(0xFF6E76C9),
        background: Color(0xFFFBF5F8),
        surface: Color(0xFFFFFFFF),
        surfaceSoft: Color(0xFFF8EDF3),
        text: Color(0xFF291923),
        textMuted: Color(0xFF786370),
        border: Color(0xFFEEDCE5),
      ),
      AppThemePreset.ocean => const AppThemePalette(
        primary: Color(0xFF2868C8),
        primarySoft: Color(0xFFE5F0FC),
        secondary: Color(0xFF2E9797),
        background: Color(0xFFF3F8FC),
        surface: Color(0xFFFFFFFF),
        surfaceSoft: Color(0xFFEAF4FA),
        text: Color(0xFF102333),
        textMuted: Color(0xFF617685),
        border: Color(0xFFDCEAF2),
      ),
    };
  }

}

AppThemePreset appThemePresetFromName(String? value) {
  return AppThemePreset.values.firstWhere(
    (preset) => preset.name == value,
    orElse: () => AppThemePreset.standard,
  );
}

class AppThemePalette {
  const AppThemePalette({
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.text,
    required this.textMuted,
    required this.border,
  });

  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceSoft;
  final Color text;
  final Color textMuted;
  final Color border;
}
