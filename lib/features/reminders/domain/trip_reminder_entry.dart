import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

enum TripReminderSourceType { planItem, documentExpiry }

class TripReminderEntry {
  const TripReminderEntry({
    required this.notificationId,
    required this.tripId,
    required this.tripTitle,
    required this.sourceId,
    required this.sourceType,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.eventAt,
  });

  final int notificationId;
  final String tripId;
  final String tripTitle;
  final String sourceId;
  final TripReminderSourceType sourceType;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final DateTime eventAt;

  bool isFuture(DateTime now) => scheduledAt.isAfter(now);

  String get payload =>
      'florys-reminder:${sourceType.name}:$tripId:$sourceId';

  static List<TripReminderEntry> fromTrip(Trip trip) {
    final entries = <TripReminderEntry>[];

    for (final item in trip.planItems) {
      final reminderMinutes = item.reminderMinutesBefore;
      if (reminderMinutes == null || item.isCompleted) {
        continue;
      }
      final eventAt = item.startsAt;
      final scheduledAt = eventAt.subtract(Duration(minutes: reminderMinutes));
      final location = item.location.trim();
      entries.add(
        TripReminderEntry(
          notificationId: notificationIdFor(
            '${trip.id}|plan|${item.id}',
          ),
          tripId: trip.id,
          tripTitle: trip.title,
          sourceId: item.id,
          sourceType: TripReminderSourceType.planItem,
          title: '${item.type.label}: ${item.title}',
          body: location.isEmpty
              ? '${trip.title} · ${item.reminderLabel}'
              : '$location · ${trip.title} · ${item.reminderLabel}',
          scheduledAt: scheduledAt,
          eventAt: eventAt,
        ),
      );
    }

    for (final document in trip.documents) {
      final expiresAt = document.expiresAt;
      final reminderDays = document.expiryReminderDaysBefore;
      if (expiresAt == null || reminderDays == null) {
        continue;
      }
      final eventAt = DateTime(
        expiresAt.year,
        expiresAt.month,
        expiresAt.day,
        9,
      );
      final scheduledAt = eventAt.subtract(Duration(days: reminderDays));
      entries.add(
        TripReminderEntry(
          notificationId: notificationIdFor(
            '${trip.id}|document|${document.id}',
          ),
          tripId: trip.id,
          tripTitle: trip.title,
          sourceId: document.id,
          sourceType: TripReminderSourceType.documentExpiry,
          title: 'Dokument läuft bald ab',
          body: '${document.title} · ${trip.title}',
          scheduledAt: scheduledAt,
          eventAt: eventAt,
        ),
      );
    }

    entries.sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    return List<TripReminderEntry>.unmodifiable(entries);
  }

  static List<TripReminderEntry> fromTrips(Iterable<Trip> trips) {
    final entries = <TripReminderEntry>[];
    for (final trip in trips) {
      entries.addAll(fromTrip(trip));
    }
    entries.sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    return List<TripReminderEntry>.unmodifiable(entries);
  }

  static int notificationIdFor(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash == 0 ? 1 : hash;
  }
}
