import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/statistics/presentation/widgets/statistics_period_filter.dart';

void main() {
  testWidgets('year filter stays usable on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: StatisticsPeriodFilter(
              selectedYear: 2025,
              years: const [2026, 2025, 2024],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Zeitraum'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(
      find.text(
        'Es zählen alle Reisen, die 2025 mindestens an einem Tag berühren.',
      ),
      findsOneWidget,
    );
  });
}
