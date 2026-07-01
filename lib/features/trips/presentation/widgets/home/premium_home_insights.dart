import 'package:flutter/material.dart';

import 'package:florys_diaries/app/theme/app_colors.dart';
import 'package:florys_diaries/core/widgets/travel_visuals.dart';
import 'package:florys_diaries/core/widgets/trip_cover_image.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/reminders/domain/trip_reminder_entry.dart';
import 'package:florys_diaries/features/trips/application/home_dashboard_snapshot.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class PremiumHomeInsights extends StatelessWidget {
  const PremiumHomeInsights({
    required this.snapshot,
    required this.onOpenPlan,
    required this.onOpenReminder,
    required this.onOpenBudget,
    required this.onOpenMoment,
    super.key,
  });

  final HomeDashboardSnapshot snapshot;
  final ValueChanged<Trip> onOpenPlan;
  final void Function(Trip trip, TripReminderSourceType sourceType)
      onOpenReminder;
  final ValueChanged<Trip> onOpenBudget;
  final ValueChanged<Trip> onOpenMoment;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];
    final plan = snapshot.planPreview;
    final reminder = snapshot.reminderPreview;
    final budgetTrip = snapshot.focusTrip;
    final moment = snapshot.momentPreview;

    if (plan != null) {
      cards.add(
        _InsightCard(
          icon: plan.item.type.icon,
          eyebrow: plan.isToday ? 'Heute' : 'Nächster Programmpunkt',
          title: plan.item.title,
          subtitle: _planSubtitle(plan),
          accent: const Color(0xFF9DB7FF),
          onTap: () => onOpenPlan(plan.trip),
        ),
      );
    }

    if (reminder != null) {
      final isDocument =
          reminder.reminder.sourceType == TripReminderSourceType.documentExpiry;
      cards.add(
        _InsightCard(
          icon: isDocument
              ? Icons.description_outlined
              : Icons.notifications_active_outlined,
          eyebrow: 'Nächste Erinnerung',
          title: reminder.reminder.title,
          subtitle: _reminderSubtitle(reminder),
          accent: const Color(0xFFFFD58A),
          onTap: () => onOpenReminder(
            reminder.trip,
            reminder.reminder.sourceType,
          ),
        ),
      );
    }

    if (budgetTrip != null && budgetTrip.budgetAmountCents > 0) {
      cards.add(
        _BudgetInsightCard(
          trip: budgetTrip,
          onTap: () => onOpenBudget(budgetTrip),
        ),
      );
    }

    if (moment != null) {
      cards.add(
        _InsightCard(
          icon: moment.entry.isFavorite
              ? Icons.favorite_rounded
              : Icons.photo_library_outlined,
          eyebrow: 'Letzter Moment',
          title: moment.entry.title,
          subtitle:
              '${TravelVisuals.formatDate(moment.entry.date)} · ${moment.trip.title}',
          accent: const Color(0xFFF2A9C0),
          onTap: () => onOpenMoment(moment.trip),
        ),
      );
    }

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 370 ? 2 : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(growable: false),
        );
      },
    );
  }

  static String _planSubtitle(HomePlanPreview preview) {
    final time = _formatTime(preview.item.startsAt);
    final location = preview.item.location.trim();
    if (location.isNotEmpty) {
      return '$time · $location';
    }
    return '$time · ${preview.trip.title}';
  }

  static String _reminderSubtitle(HomeReminderPreview preview) {
    final date = TravelVisuals.formatDate(preview.reminder.eventAt);
    final time = _formatTime(preview.reminder.eventAt);
    return '$date, $time · ${preview.trip.title}';
  }

  static String _formatTime(DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes Uhr';
  }
}

class PremiumUpcomingTripRow extends StatelessWidget {
  const PremiumUpcomingTripRow({
    required this.trip,
    required this.onTap,
    super.key,
  });

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.homeSurface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: AppColors.homeBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 18,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: TripCoverImage(
                  trip: trip,
                  borderRadius: BorderRadius.circular(19),
                  overlay: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x52000000)],
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

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 166,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF17263D), Color(0xFF0E1A2B)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.homeBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(icon, size: 20, color: accent),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: Colors.white54,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
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
      ),
    );
  }
}

class _BudgetInsightCard extends StatelessWidget {
  const _BudgetInsightCard({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final remaining = trip.forecastRemainingBudgetCents;
    final overBudget = remaining < 0;
    final accent = overBudget
        ? const Color(0xFFFF9EA5)
        : const Color(0xFF86D7B6);
    final progress = trip.forecastBudgetProgress;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 166,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF142D2C), Color(0xFF0D1D25)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.homeBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 20,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: Colors.white54,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                overBudget ? 'Budget überschritten' : 'Verfügbares Budget',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                TripMoney.format(remaining, trip.budgetCurrency),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${TripMoney.format(trip.totalExpenseCents, trip.budgetCurrency)} geplant · ${trip.title}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.homeTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
