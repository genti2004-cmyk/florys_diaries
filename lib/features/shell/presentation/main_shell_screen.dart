import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/features/album/presentation/screens/memories_screen.dart';
import 'package:florys_diaries/features/map/presentation/world_map_screen.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/presentation/screens/past_trips_screen.dart';
import 'package:florys_diaries/features/trips/presentation/screens/upcoming_trips_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;

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
    final tripStore = TripStoreScope.of(context);

    if (tripStore.isLoading) {
      return const _TripStartupLoadingScreen();
    }
    if (tripStore.hasLoadError) {
      return _TripStorageErrorScreen(
        message:
            tripStore.loadErrorMessage ??
            'Die lokalen Reisedaten konnten nicht sicher geladen werden.',
        onRetry: () => unawaited(tripStore.reloadFromStorage()),
      );
    }

    final screens = <Widget>[
      UpcomingTripsScreen(
        onOpenTrips: () => _selectDestination(1),
        onOpenMap: () => _selectDestination(2),
      ),
      const PastTripsScreen(),
      const WorldMapScreen(),
      const MemoriesScreen(),
    ];

    final isDarkPage = _index == 0;
    final navBackground = isDarkPage ? AppColors.homeSurface : AppColors.surface;
    final navBorder = isDarkPage ? AppColors.homeBorder : AppColors.border;
    final overlayStyle = isDarkPage
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: AppColors.homeBackground,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: AppColors.background,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: PopScope<void>(
        canPop: _index == 0,
        onPopInvokedWithResult: (didPop, result) => _handleBack(didPop),
        child: Scaffold(
          extendBody: true,
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: navBackground,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: navBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120D1728),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: NavigationBar(
                  selectedIndex: _index,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: _selectDestination,
                  backgroundColor: Colors.transparent,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.luggage_outlined),
                      selectedIcon: Icon(Icons.luggage_rounded),
                      label: 'Reisen',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.public_outlined),
                      selectedIcon: Icon(Icons.public_rounded),
                      label: 'Karte',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border_rounded),
                      selectedIcon: Icon(Icons.favorite_rounded),
                      label: 'Momente',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripStartupLoadingScreen extends StatelessWidget {
  const _TripStartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ColoredBox(
        color: AppColors.homeBackground,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TripStorageErrorScreen extends StatelessWidget {
  const _TripStorageErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 34,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Reisedaten konnten nicht geladen werden',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Erneut versuchen'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
