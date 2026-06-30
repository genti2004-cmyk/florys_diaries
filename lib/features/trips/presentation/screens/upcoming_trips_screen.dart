import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/features/assistant/presentation/travel_assistant_screen.dart';
import 'package:florys_diaries/features/settings/presentation/settings_screen.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_empty_state.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/upcoming_trip_hero.dart';

import 'past_trips_screen.dart';
import 'trip_detail_screen.dart';
import 'trip_editor_screen.dart';

class UpcomingTripsScreen extends StatelessWidget {
  const UpcomingTripsScreen({super.key});

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

  Future<void> _openTimeline(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PastTripsScreen()));
  }

  void _openTrip(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TripDetailScreen(trip: trip)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = TripStoreScope.of(context);
    final trips = store.upcomingTrips;
    final nextTrip = trips.isEmpty ? null : trips.first;
    final allTrips = store.trips;
    final countryCount = allTrips
        .map((trip) => trip.country.trim().toLowerCase())
        .where((country) => country.isNotEmpty)
        .toSet()
        .length;
    final documentCount = allTrips.fold<int>(
      0,
      (sum, trip) => sum + trip.documentCount,
    );
    final memoryCount = allTrips.fold<int>(
      0,
      (sum, trip) => sum + trip.albumEntryCount,
    );
    final totalDays = allTrips.fold<int>(
      0,
      (sum, trip) => sum + trip.durationDays,
    );

    return ColoredBox(
      color: AppColors.homeBackground,
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey<String>('premium-home-v2'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
          children: [
            _HomeHeader(
              onOpenAssistant: () => _openAssistant(context),
              onOpenSettings: () => _openSettings(context),
            ),
            const SizedBox(height: 18),
            if (store.isLoading)
              const _LoadingState()
            else if (nextTrip == null)
              _DarkEmptyState(onCreateTrip: () => _openEditor(context))
            else ...[
              UpcomingTripHero(
                trip: nextTrip,
                onTap: () => _openTrip(context, nextTrip),
              ),
              const SizedBox(height: 16),
              _MetricsGrid(
                items: [
                  _MetricItem(label: 'Reisen', value: '${allTrips.length}'),
                  _MetricItem(label: 'Länder', value: '$countryCount'),
                  _MetricItem(label: 'Tage', value: '$totalDays'),
                  _MetricItem(
                    label: 'Dokumente',
                    value: '$documentCount',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Meine Reisen',
                subtitle: 'Schneller Zugriff auf deine geplanten Abenteuer.',
                actionLabel: 'Timeline',
                onAction: () => _openTimeline(context),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 198,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: trips.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _CompactTripCard(
                      trip: trip,
                      onTap: () => _openTrip(context, trip),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              const _SectionHeader(
                title: 'Reisestatus',
                subtitle: 'Was du bereits gesammelt und erlebt hast.',
              ),
              const SizedBox(height: 12),
              _InsightCard(
                icon: Icons.favorite_outline_rounded,
                title: '$memoryCount Erinnerungen',
                subtitle:
                    'Momente, Highlights und Notizen aus deinen Reisen.',
              ),
              const SizedBox(height: 10),
              _InsightCard(
                icon: Icons.flight_takeoff_rounded,
                title: '${trips.length} kommende Reisen',
                subtitle: trips.length == 1
                    ? 'Ein Abenteuer wartet bereits auf dich.'
                    : 'Mehrere Reisen stehen bereits in den Startlöchern.',
              ),
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
    required this.onOpenSettings,
  });

  final VoidCallback onOpenAssistant;
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
              const SizedBox(height: 7),
              Text(
                'FlorysDiaries',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 27,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Deine Reisen. Deine Geschichten. Für immer.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.homeTextMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.auto_awesome_rounded,
          onTap: onOpenAssistant,
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.settings_outlined,
          onTap: onOpenSettings,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.items});

  final List<_MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.25,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.homeSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.homeBorder),
          ),
          child: Row(
            children: [
              Text(
                item.value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.homeTextMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.homeTextMuted,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 10),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 3),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactTripCard extends StatelessWidget {
  const _CompactTripCard({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TravelVisuals.forText(
      '${trip.destination} ${trip.country} ${trip.title}',
    );

    return SizedBox(
      width: 178,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.gradient,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      TravelVisuals.formatMonthYear(trip.startDate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    trip.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trip.destination}, ${trip.country}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.timelapse_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${trip.durationDays} Tage',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.homeSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.homeBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.homeSurfaceSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.homeTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;
}
