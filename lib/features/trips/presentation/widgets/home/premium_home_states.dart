import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';

class PremiumHomeLoading extends StatelessWidget {
  const PremiumHomeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.homeSurface,
        borderRadius: BorderRadius.circular(28),
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

class PremiumHomeEmpty extends StatelessWidget {
  const PremiumHomeEmpty({required this.onCreateTrip, super.key});

  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172A46), AppColors.homeSurface],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.homeBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Deine Reisewelt beginnt hier',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Plane deine erste Reise und sammle Programm, Dokumente, Budget und Erinnerungen sicher an einem Ort.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.homeTextMuted,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreateTrip,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Erste Reise anlegen'),
          ),
        ],
      ),
    );
  }
}

class PremiumHomeNoUpcoming extends StatelessWidget {
  const PremiumHomeNoUpcoming({required this.onCreateTrip, super.key});

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
