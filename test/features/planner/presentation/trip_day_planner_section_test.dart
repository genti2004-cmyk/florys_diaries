import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/planner/presentation/widgets/trip_day_planner_section.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  testWidgets('day planner remains readable on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final trip = Trip(
      id: 'trip-1',
      title: 'Berlin',
      destination: 'Berlin',
      country: 'Deutschland',
      startDate: today,
      endDate: today.add(const Duration(days: 2)),
      planItems: [
        TripPlanItem(
          id: 'plan-1',
          title: 'Museumsinsel besuchen',
          date: today,
          startMinutes: 9 * 60 + 30,
          endMinutes: 12 * 60,
          type: TripPlanItemType.sight,
          location: 'Museumsinsel, Berlin',
          notes: 'Tickets und Reisepass mitnehmen.',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TripDayPlannerSection(trip: trip),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Dein Reiseprogramm'), findsOneWidget);
    expect(find.text('Museumsinsel besuchen'), findsOneWidget);
    expect(find.text('09:30 – 12:00'), findsOneWidget);
    expect(find.text('Sehenswürdigkeit'), findsOneWidget);
  });
}
