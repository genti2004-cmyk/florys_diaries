import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/assistant/presentation/travel_assistant_screen.dart';
import 'package:florys_diaries/features/map/presentation/world_map_screen.dart';
import 'package:florys_diaries/features/settings/presentation/settings_screen.dart';
import 'package:florys_diaries/features/statistics/presentation/statistics_screen.dart';
import 'package:florys_diaries/features/trips/presentation/screens/past_trips_screen.dart';
import 'package:florys_diaries/features/trips/presentation/screens/trip_editor_screen.dart';
import 'package:florys_diaries/features/trips/presentation/screens/upcoming_trips_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;

  static const List<Widget> _screens = [
    UpcomingTripsScreen(),
    PastTripsScreen(),
    WorldMapScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  static const List<String> _titles = [
    'FlorysDiaries',
    'Archiv',
    'Welt',
    'Statistik',
    'Einstellungen',
  ];

  static const List<String> _subtitles = [
    'Reisen planen',
    'Erinnerungen bewahren',
    'Bereiste Orte entdecken',
    'Deine Reisebilanz',
    'Sicherung und App',
  ];

  Future<void> _openAssistant() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TravelAssistantScreen()),
    );
  }

  Future<void> _openTripEditor() {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TripEditorScreen()));
  }

  void _selectDestination(int value) {
    if (value == _index) {
      return;
    }
    setState(() => _index = value);
  }

  void _handleBack(bool didPop) {
    if (didPop || _index == 0) {
      return;
    }
    setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    final showNewTripAction = _index == 0;

    return PopScope<void>(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) => _handleBack(didPop),
      child: Scaffold(
        appBar: AppBar(
          title: _ShellTitle(
            title: _titles[_index],
            subtitle: _subtitles[_index],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton.filledTonal(
                tooltip: 'Reiseassistent',
                onPressed: _openAssistant,
                icon: const Icon(Icons.auto_awesome_rounded),
              ),
            ),
          ],
        ),
        body: ColoredBox(
          color: AppColors.background,
          child: IndexedStack(index: _index, children: _screens),
        ),
        floatingActionButton: showNewTripAction
            ? FloatingActionButton.extended(
                onPressed: _openTripEditor,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Neue Reise'),
              )
            : null,
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: _index,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: _selectDestination,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.flight_takeoff_outlined),
                  selectedIcon: Icon(Icons.flight_takeoff_rounded),
                  label: 'Reisen',
                ),
                NavigationDestination(
                  icon: Icon(Icons.luggage_outlined),
                  selectedIcon: Icon(Icons.luggage_rounded),
                  label: 'Archiv',
                ),
                NavigationDestination(
                  icon: Icon(Icons.public_outlined),
                  selectedIcon: Icon(Icons.public_rounded),
                  label: 'Welt',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Statistik',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Mehr',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellTitle extends StatelessWidget {
  const _ShellTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
