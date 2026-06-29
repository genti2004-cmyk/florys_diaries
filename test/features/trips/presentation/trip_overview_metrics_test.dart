import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/trips/presentation/widgets/trip_overview_metrics.dart';

void main() {
  testWidgets('metrics remain readable on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: TripOverviewMetrics(
              upcomingCount: 12,
              countryCount: 8,
              documentCount: 24,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('Reisen'), findsOneWidget);
    expect(find.text('Länder'), findsOneWidget);
    expect(find.text('Dokumente'), findsOneWidget);
  });
}
