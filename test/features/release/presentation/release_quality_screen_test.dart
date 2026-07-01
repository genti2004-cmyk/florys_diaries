import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/release/presentation/screens/release_quality_screen.dart';

void main() {
  testWidgets('release quality screen stays usable on a narrow display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReleaseQualityScreen(
          trips: [],
          localBackups: [],
          dataSafetyReport: null,
          isReleaseBuild: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Release & Qualität'), findsOneWidget);
    expect(find.text('Prüfung vor Release nötig'), findsOneWidget);
    expect(find.text('Aktueller Datenbestand'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Diagnose kopieren'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Diagnose kopieren'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
