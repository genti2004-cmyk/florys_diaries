import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/map/widgets/world_summary_card.dart';

void main() {
  testWidgets('world summary remains readable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: WorldSummaryCard(
              countryCount: 12,
              cityCount: 28,
              tripCount: 15,
              travelDays: 125,
              progressPercent: 6.2,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('6.2 % der Welt'), findsOneWidget);
    expect(find.text('Reisen'), findsOneWidget);
    expect(find.text('Länder'), findsOneWidget);
    expect(find.text('Städte'), findsOneWidget);
    expect(find.text('Tage'), findsOneWidget);
  });
}
