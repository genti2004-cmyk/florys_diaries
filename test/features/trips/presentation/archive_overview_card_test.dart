import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/archive_overview_card.dart';

void main() {
  testWidgets('archive overview remains readable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final trips = [
      Trip(
        id: 'one',
        title: 'Berlin',
        destination: 'Berlin',
        country: 'Deutschland',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 4),
        photoCount: 8,
      ),
      Trip(
        id: 'two',
        title: 'Rom',
        destination: 'Rom',
        country: 'Italien',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 3),
        photoCount: 4,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ArchiveOverviewCard(trips: trips),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Deine Reisegeschichte'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('Reisen'), findsOneWidget);
    expect(find.text('Länder'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Reisetage'), findsOneWidget);
  });
}
