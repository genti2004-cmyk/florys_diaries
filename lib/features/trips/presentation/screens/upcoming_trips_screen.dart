import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/core/widgets/trip_cover_image.dart';
import 'package:florys_diaries/features/assistant/presentation/travel_assistant_screen.dart';
import 'package:florys_diaries/features/map/presentation/world_map_screen.dart';
import 'package:florys_diaries/features/search/presentation/global_search_screen.dart';
import 'package:florys_diaries/features/settings/presentation/settings_screen.dart';
import 'package:florys_diaries/features/statistics/presentation/statistics_screen.dart';
import 'package:florys_diaries/features/templates/presentation/screens/trip_templates_screen.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_empty_state.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/upcoming_trip_hero.dart';

import 'past_trips_screen.dart';
import 'trip_detail_screen.dart';
import 'trip_editor_screen.dart';

class UpcomingTripsScreen extends StatelessWidget {
  const UpcomingTripsScreen({
    this.onOpenTrips,
    this.onOpenMap,
    super.key,
  });

  final VoidCallback? onOpenTrips;
  final VoidCallback? onOpenMap;

  Future<void> _openEditor(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TripEditorScreen()));
  }

  Future<void> _openAssistant(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TravelAssistantScreen()),
    );
  }

  Future<void> _openSettings(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openSearch(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GlobalSearchScreen()),
    );
  }


  Future<void> _openTemplates(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TripTemplatesScreen()),
    );
  }

  Future<void> _openStatistics(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Reisebilanz')),
          body: const StatisticsScreen(showHeader: false),
        ),
      ),
    );
  }


  void _showTrips(BuildContext context) {
    final callback = onOpenTrips;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PastTripsScreen()),
    );
  }

  void _showMap(BuildContext context) {
    final callback = onOpenMap;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WorldMapScreen()),
    );
  }

  void _openTrip(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TripDetailScreen(trip: trip)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final upcomingTrips = store.upcomingTrips;
    final nextTrip = upcomingTrips.isEmpty ? null : upcomingTrips.first;
    final additionalTrips = upcomingTrips.skip(1).take(2).toList(growable: false);
    final allTrips = store.trips;

    final metrics = _HomeMetrics.fromTrips(allTrips);

    return ColoredBox(
      color: AppColors.homeBackground,
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('premium-home-v6'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 132),
          children: [
            _HomeHeader(
              onOpenAssistant: () => _openAssistant(context),
              onOpenSearch: () => _openSearch(context),
              onOpenSettings: () => _openSettings(context),
            ),
            const SizedBox(height: 18),
            if (store.isLoading)
              const _LoadingState()
            else if (nextTrip == null && allTrips.isEmpty)
              _DarkEmptyState(onCreateTrip: () => _openEditor(context))
            else if (nextTrip == null) ...[
              _NoUpcomingTripState(onCreateTrip: () => _openEditor(context)),
              const SizedBox(height: 14),
              _HomeQuickActions(
                onCreateTrip: () => _openEditor(context),
                onOpenTrips: () => _showTrips(context),
                onOpenStatistics: () => _openStatistics(context),
                onOpenTemplates: () => _openTemplates(context),
              ),
              const SizedBox(height: 18),
              _CompactOverviewCard(
                tripCount: allTrips.length,
                countryCount: metrics.countryCount,
                documentCount: metrics.documentCount,
                memoryCount: metrics.memoryCount,
                onOpenMap: () => _showMap(context),
              ),
            ] else ...[
              UpcomingTripHero(
                trip: nextTrip,
                onTap: () => _openTrip(context, nextTrip),
              ),
              const SizedBox(height: 14),
              _HomeQuickActions(
                onCreateTrip: () => _openEditor(context),
                onOpenTrips: () => _showTrips(context),
                onOpenStatistics: () => _openStatistics(context),
                onOpenTemplates: () => _openTemplates(context),
              ),
              const SizedBox(height: 18),
              _CompactOverviewCard(
                tripCount: allTrips.length,
                countryCount: metrics.countryCount,
                documentCount: metrics.documentCount,
                memoryCount: metrics.memoryCount,
                onOpenMap: () => _showMap(context),
              ),
              if (additionalTrips.isNotEmpty) ...[
                const SizedBox(height: 22),
                _SectionHeader(
                  title: 'Weitere geplante Reisen',
                  actionLabel: 'Alle Reisen',
                  onAction: () => _showTrips(context),
                ),
                const SizedBox(height: 12),
                ...additionalTrips.map(
                  (trip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _UpcomingTripRow(
                      trip: trip,
                      onTap: () => _openTrip(context, trip),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onOpenAssistant,
    required this.onOpenSearch,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenAssistant;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${TravelVisuals.greeting()}, Florenta ✨',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'FlorysDiaries',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 27,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          tooltip: 'Reiseassistent',
          icon: Icons.auto_awesome_rounded,
          onTap: onOpenAssistant,
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          tooltip: 'Globale Suche',
          icon: Icons.search_rounded,
          onTap: onOpenSearch,
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          tooltip: 'Einstellungen',
          icon: Icons.settings_outlined,
          onTap: onOpenSettings,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.homeSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.homeBorder),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _HomeQuickActions extends StatelessWidget {
  const _HomeQuickActions({
    required this.onCreateTrip,
    required this.onOpenTrips,
    required this.onOpenStatistics,
    required this.onOpenTemplates,
  });

  final VoidCallback onCreateTrip;
  final VoidCallback onOpenTrips;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenTemplates;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      _QuickAction(
        icon: Icons.add_rounded,
        label: 'Neue Reise',
        onTap: onCreateTrip,
        emphasized: true,
      ),
      _QuickAction(
        icon: Icons.luggage_outlined,
        label: 'Reisen',
        onTap: onOpenTrips,
      ),
      _QuickAction(
        icon: Icons.collections_bookmark_outlined,
        label: 'Vorlagen',
        onTap: onOpenTemplates,
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: 'Statistik',
        onTap: onOpenStatistics,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 390 ? 2 : 4;
        final width =
            (constraints.maxWidth - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: actions
              .map((action) => SizedBox(width: width, child: action))
              .toList(growable: false),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final background = emphasized ? Colors.white : AppColors.homeSurface;
    final foreground = emphasized ? AppColors.primary : Colors.white;
    final border = emphasized ? Colors.white : AppColors.homeBorder;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: foreground),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactOverviewCard extends StatelessWidget {
  const _CompactOverviewCard({
    required this.tripCount,
    required this.countryCount,
    required this.documentCount,
    required this.memoryCount,
    required this.onOpenMap,
  });

  final int tripCount;
  final int countryCount;
  final int documentCount;
  final int memoryCount;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.homeSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.homeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Auf einen Blick',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenMap,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.public_rounded, size: 17),
                label: const Text('Karte'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _OverviewMetric(value: '$tripCount', label: 'Reisen')),
              Expanded(child: _OverviewMetric(value: '$countryCount', label: 'Länder')),
              Expanded(
                child: _OverviewMetric(
                  value: '$documentCount',
                  label: 'Dokumente',
                ),
              ),
              Expanded(
                child: _OverviewMetric(value: '$memoryCount', label: 'Momente'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.homeTextMuted,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(actionLabel),
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpcomingTripRow extends StatelessWidget {
  const _UpcomingTripRow({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.homeSurface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.homeBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: TripCoverImage(
                  trip: trip,
                  borderRadius: BorderRadius.circular(18),
                  overlay: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x44000000)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${trip.destination}, ${trip.country}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.homeTextMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      TravelVisuals.formatDateRange(
                        trip.startDate,
                        trip.endDate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoUpcomingTripState extends StatelessWidget {
  const _NoUpcomingTripState({required this.onCreateTrip});

  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.homeSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.homeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.homeSurfaceSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Zeit für das nächste Abenteuer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Deine bisherigen Reisen bleiben erhalten. Plane jetzt dein nächstes Ziel.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.homeTextMuted,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreateTrip,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Neue Reise planen'),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.homeSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.homeBorder),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Reisen werden geladen …',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DarkEmptyState extends StatelessWidget {
  const _DarkEmptyState({required this.onCreateTrip});

  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.homeSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.homeBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(cardColor: AppColors.homeSurface),
        child: TripEmptyState(onCreateTrip: onCreateTrip),
      ),
    );
  }
}

class _HomeMetrics {
  const _HomeMetrics({
    required this.countryCount,
    required this.documentCount,
    required this.memoryCount,
  });

  factory _HomeMetrics.fromTrips(List<Trip> trips) {
    final countries = <String>{};
    var documentCount = 0;
    var memoryCount = 0;

    for (final trip in trips) {
      final country = trip.country.trim().toLowerCase();
      if (country.isNotEmpty) {
        countries.add(country);
      }
      documentCount += trip.documentCount;
      memoryCount += trip.albumEntryCount;
    }

    return _HomeMetrics(
      countryCount: countries.length,
      documentCount: documentCount,
      memoryCount: memoryCount,
    );
  }

  final int countryCount;
  final int documentCount;
  final int memoryCount;
}
