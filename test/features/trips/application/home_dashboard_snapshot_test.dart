import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/trips/application/home_dashboard_snapshot.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  group('HomeDashboardSnapshot', () {
    test('prefers the running trip and exposes real dashboard data', () {
      final now = DateTime(2026, 7, 1, 10);
      final running = Trip(
        id: 'running',
        title: 'Berlin Sommer',
        destination: 'Berlin',
        country: 'Deutschland',
        startDate: DateTime(2026, 6, 30),
        endDate: DateTime(2026, 7, 3),
        budgetAmountCents: 100000,
        planItems: [
          TripPlanItem(
            id: 'museum',
            title: 'Museum besuchen',
            date: DateTime(2026, 7, 1),
            startMinutes: 11 * 60,
            type: TripPlanItemType.sight,
            reminderMinutesBefore: 30,
          ),
        ],
        documents: [
          TravelDocument(
            id: 'ticket',
            title: 'Museumsticket',
            categoryId: DocumentCategories.pdf.id,
            createdAt: DateTime(2026, 6, 20),
          ),
        ],
        albumEntries: [
          TripAlbumEntry(
            id: 'moment',
            typeId: TripAlbumEntryTypes.highlight.id,
            date: DateTime(2026, 7, 1, 9),
            title: 'Frühstück am Spreeufer',
          ),
        ],
      );
      final future = Trip(
        id: 'future',
        title: 'Rom',
        destination: 'Rom',
        country: 'Italien',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 5),
      );

      final snapshot = HomeDashboardSnapshot.fromTrips(
        [future, running],
        now: now,
      );

      expect(snapshot.focusTrip?.id, 'running');
      expect(snapshot.upcomingTrips.map((trip) => trip.id), [
        'running',
        'future',
      ]);
      expect(snapshot.planPreview?.item.id, 'museum');
      expect(snapshot.planPreview?.isToday, isTrue);
      expect(snapshot.reminderPreview?.reminder.sourceId, 'museum');
      expect(snapshot.momentPreview?.entry.id, 'moment');
      expect(snapshot.tripCount, 2);
      expect(snapshot.countryCount, 2);
      expect(snapshot.documentCount, 1);
      expect(snapshot.memoryCount, 1);
      expect(snapshot.hasInsights, isTrue);
    });

    test('keeps historic moments visible without an upcoming trip', () {
      final past = Trip(
        id: 'past',
        title: 'Hamburg',
        destination: 'Hamburg',
        country: 'Deutschland',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 3),
        albumEntries: [
          TripAlbumEntry(
            id: 'harbour',
            typeId: TripAlbumEntryTypes.memory.id,
            date: DateTime(2026, 5, 2),
            title: 'Abend am Hafen',
          ),
        ],
      );

      final snapshot = HomeDashboardSnapshot.fromTrips(
        [past],
        now: DateTime(2026, 7, 1),
      );

      expect(snapshot.focusTrip, isNull);
      expect(snapshot.upcomingTrips, isEmpty);
      expect(snapshot.momentPreview?.entry.id, 'harbour');
      expect(snapshot.hasInsights, isTrue);
    });
  });
}
