import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  test('plan item survives trip json roundtrip', () {
    final trip = Trip(
      id: 'trip-1',
      title: 'Rom',
      destination: 'Rom',
      country: 'Italien',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 4),
      planItems: [
        TripPlanItem(
          id: 'plan-1',
          title: 'Kolosseum',
          date: DateTime(2026, 8, 2),
          startMinutes: 9 * 60 + 30,
          endMinutes: 11 * 60,
          type: TripPlanItemType.sight,
          location: 'Piazza del Colosseo',
          notes: 'Tickets bereithalten',
          linkedDocumentId: 'ticket-1',
        ),
      ],
    );

    final restored = Trip.fromJson(trip.toJson());

    expect(restored.planItems, hasLength(1));
    final item = restored.planItems.single;
    expect(item.id, 'plan-1');
    expect(item.title, 'Kolosseum');
    expect(item.dateOnly, DateTime(2026, 8, 2));
    expect(item.startMinutes, 570);
    expect(item.endMinutes, 660);
    expect(item.type, TripPlanItemType.sight);
    expect(item.location, 'Piazza del Colosseo');
    expect(item.notes, 'Tickets bereithalten');
    expect(item.linkedDocumentId, 'ticket-1');
  });

  test('trip sorts restored plan items by date and time', () {
    final trip = Trip.fromJson({
      'id': 'trip-1',
      'title': 'Berlin',
      'destination': 'Berlin',
      'country': 'Deutschland',
      'startDate': '2026-07-01T00:00:00.000',
      'endDate': '2026-07-03T00:00:00.000',
      'planItems': [
        {
          'id': 'late',
          'title': 'Abendessen',
          'date': '2026-07-02T00:00:00.000',
          'startMinutes': 1140,
          'type': 'restaurant',
        },
        {
          'id': 'early',
          'title': 'Frühstück',
          'date': '2026-07-02T00:00:00.000',
          'startMinutes': 480,
          'type': 'restaurant',
        },
        {
          'id': 'first-day',
          'title': 'Anreise',
          'date': '2026-07-01T00:00:00.000',
          'startMinutes': 900,
          'type': 'transport',
        },
      ],
    });

    expect(trip.planItems.map((item) => item.id), [
      'first-day',
      'early',
      'late',
    ]);
    expect(trip.planItemCount, 3);
    expect(trip.plannedDayCount, 2);
  });
}
