import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/reminders/domain/trip_reminder_entry.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  test('builds plan and document reminders in chronological order', () {
    final trip = Trip(
      id: 'trip-1',
      title: 'Rom',
      destination: 'Rom',
      country: 'Italien',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 5),
      planItems: [
        TripPlanItem(
          id: 'plan-1',
          title: 'Kolosseum',
          date: DateTime(2026, 8, 2),
          startMinutes: 10 * 60,
          type: TripPlanItemType.sight,
          reminderMinutesBefore: 60,
        ),
      ],
      documents: [
        TravelDocument(
          id: 'doc-1',
          title: 'Reisepass',
          categoryId: DocumentCategories.other.id,
          createdAt: DateTime(2026, 1, 1),
          expiresAt: DateTime(2026, 7, 10),
          expiryReminderDaysBefore: 7,
        ),
      ],
    );

    final entries = TripReminderEntry.fromTrip(trip);

    expect(entries, hasLength(2));
    expect(entries.first.sourceType, TripReminderSourceType.documentExpiry);
    expect(entries.last.sourceType, TripReminderSourceType.planItem);
    expect(entries.last.scheduledAt, DateTime(2026, 8, 2, 9));
    expect(entries.last.notificationId, isPositive);
  });
}
