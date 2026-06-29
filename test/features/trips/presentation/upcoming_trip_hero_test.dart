import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/upcoming_trip_hero.dart';

void main() {
  testWidgets('hero remains usable on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var opened = false;
    final trip = Trip(
      id: 'trip-1',
      title: 'Eine besonders lange Reiseüberschrift für den schmalen Test',
      destination: 'Eine sehr lange Reisezielbezeichnung',
      country: 'Deutschland',
      startDate: DateTime(2026, 7, 2),
      endDate: DateTime(2026, 7, 8),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: UpcomingTripHero(
              trip: trip,
              now: DateTime(2026, 6, 29),
              onTap: () => opened = true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Nächste Reise'), findsOneWidget);
    expect(find.text('Startet in 3 Tagen'), findsOneWidget);
    expect(find.text('7 Tage'), findsOneWidget);

    await tester.tap(find.byType(UpcomingTripHero));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets('hero marks a currently active trip', (tester) async {
    final trip = Trip(
      id: 'trip-2',
      title: 'Berlin',
      destination: 'Berlin',
      country: 'Deutschland',
      startDate: DateTime(2026, 6, 28),
      endDate: DateTime(2026, 7, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpcomingTripHero(
            trip: trip,
            now: DateTime(2026, 6, 29),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Diese Reise läuft gerade'), findsOneWidget);
  });
}
