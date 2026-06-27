import 'package:flutter/material.dart';

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

  Future<void> _openAssistant() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TravelAssistantScreen(),
      ),
    );
  }

  Future<void> _openTripEditor() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TripEditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showNewTripAction = _index == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Reiseassistent',
            onPressed: _openAssistant,
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      floatingActionButton: showNewTripAction
          ? FloatingActionButton.extended(
              onPressed: _openTripEditor,
              icon: const Icon(Icons.add),
              label: const Text('Neue Reise'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_outlined),
            selectedIcon: Icon(Icons.flight_takeoff),
            label: 'Reisen',
          ),
          NavigationDestination(
            icon: Icon(Icons.luggage_outlined),
            selectedIcon: Icon(Icons.luggage),
            label: 'Archiv',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'Welt',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Mehr',
          ),
        ],
      ),
    );
  }
}
