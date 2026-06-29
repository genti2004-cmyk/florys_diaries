import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/statistics/presentation/widgets/statistics_panel.dart';

void main() {
  testWidgets('long statistics values remain usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: StatisticsPanel(
              child: Column(
                children: [
                  StatisticsInfoRow(
                    label: 'Durchschnittliche Reisedauer',
                    value: '123.456,7 Tage mit sehr langem Zusatz',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Durchschnittliche Reisedauer'), findsOneWidget);
    expect(find.text('123.456,7 Tage mit sehr langem Zusatz'), findsOneWidget);
  });
}
