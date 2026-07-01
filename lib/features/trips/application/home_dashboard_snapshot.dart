import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/reminders/domain/trip_reminder_entry.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class HomeDashboardSnapshot {
  const HomeDashboardSnapshot({
    required this.tripCount,
    required this.countryCount,
    required this.documentCount,
    required this.memoryCount,
    required this.upcomingTrips,
    required this.focusTrip,
    required this.planPreview,
    required this.reminderPreview,
    required this.momentPreview,
  });

  factory HomeDashboardSnapshot.fromTrips(
    List<Trip> trips, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = _dateOnly(current);
    final orderedTrips = List<Trip>.from(trips)
      ..sort((left, right) => left.startDate.compareTo(right.startDate));

    final upcomingTrips = orderedTrips
        .where((trip) => !_dateOnly(trip.endDate).isBefore(today))
        .toList(growable: false);

    Trip? activeTrip;
    for (final trip in upcomingTrips) {
      final starts = _dateOnly(trip.startDate);
      final ends = _dateOnly(trip.endDate);
      if (!today.isBefore(starts) && !today.isAfter(ends)) {
        activeTrip = trip;
        break;
      }
    }

    final focusTrip = activeTrip ??
        (upcomingTrips.isEmpty ? null : upcomingTrips.first);

    final countries = <String>{};
    var documentCount = 0;
    var memoryCount = 0;
    for (final trip in orderedTrips) {
      final country = trip.country.trim().toLowerCase();
      if (country.isNotEmpty) {
        countries.add(country);
      }
      documentCount += trip.documentCount;
      memoryCount += trip.albumEntryCount;
    }

    return HomeDashboardSnapshot(
      tripCount: orderedTrips.length,
      countryCount: countries.length,
      documentCount: documentCount,
      memoryCount: memoryCount,
      upcomingTrips: List<Trip>.unmodifiable(upcomingTrips),
      focusTrip: focusTrip,
      planPreview: _findPlanPreview(
        upcomingTrips,
        current: current,
        today: today,
        activeTrip: activeTrip,
      ),
      reminderPreview: _findReminderPreview(orderedTrips, current),
      momentPreview: _findMomentPreview(orderedTrips),
    );
  }

  final int tripCount;
  final int countryCount;
  final int documentCount;
  final int memoryCount;
  final List<Trip> upcomingTrips;
  final Trip? focusTrip;
  final HomePlanPreview? planPreview;
  final HomeReminderPreview? reminderPreview;
  final HomeMomentPreview? momentPreview;

  bool get hasInsights =>
      planPreview != null ||
      reminderPreview != null ||
      (focusTrip?.budgetAmountCents ?? 0) > 0 ||
      momentPreview != null;

  static HomePlanPreview? _findPlanPreview(
    List<Trip> upcomingTrips, {
    required DateTime current,
    required DateTime today,
    required Trip? activeTrip,
  }) {
    final candidates = <HomePlanPreview>[];

    for (final trip in upcomingTrips) {
      for (final item in trip.planItems) {
        if (item.isCompleted || item.dateOnly.isBefore(today)) {
          continue;
        }
        candidates.add(
          HomePlanPreview(
            trip: trip,
            item: item,
            isToday: item.dateOnly == today,
            isCurrentTrip: identical(trip, activeTrip),
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((left, right) {
      if (left.isCurrentTrip != right.isCurrentTrip) {
        return left.isCurrentTrip ? -1 : 1;
      }
      final dateComparison = left.item.startsAt.compareTo(right.item.startsAt);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return left.item.title.compareTo(right.item.title);
    });

    final future = candidates.where(
      (preview) => !preview.item.startsAt.isBefore(current),
    );
    if (future.isNotEmpty) {
      return future.first;
    }

    return candidates.first;
  }

  static HomeReminderPreview? _findReminderPreview(
    List<Trip> trips,
    DateTime current,
  ) {
    for (final reminder in TripReminderEntry.fromTrips(trips)) {
      if (reminder.scheduledAt.isBefore(current)) {
        continue;
      }
      Trip? trip;
      for (final item in trips) {
        if (item.id == reminder.tripId) {
          trip = item;
          break;
        }
      }
      if (trip != null) {
        return HomeReminderPreview(trip: trip, reminder: reminder);
      }
    }
    return null;
  }

  static HomeMomentPreview? _findMomentPreview(List<Trip> trips) {
    HomeMomentPreview? result;
    for (final trip in trips) {
      for (final entry in trip.albumEntries) {
        if (result == null || entry.date.isAfter(result.entry.date)) {
          result = HomeMomentPreview(trip: trip, entry: entry);
        }
      }
    }
    return result;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class HomePlanPreview {
  const HomePlanPreview({
    required this.trip,
    required this.item,
    required this.isToday,
    required this.isCurrentTrip,
  });

  final Trip trip;
  final TripPlanItem item;
  final bool isToday;
  final bool isCurrentTrip;
}

class HomeReminderPreview {
  const HomeReminderPreview({required this.trip, required this.reminder});

  final Trip trip;
  final TripReminderEntry reminder;
}

class HomeMomentPreview {
  const HomeMomentPreview({required this.trip, required this.entry});

  final Trip trip;
  final TripAlbumEntry entry;
}
