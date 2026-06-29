import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/trips/presentation/widgets/trip_detail_quick_actions.dart';

void main() {
  testWidgets('detail quick actions remain usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var replayCalls = 0;
    var editCalls = 0;
    var exportCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TripDetailQuickActions(
              onReplay: () => replayCalls++,
              onEdit: () => editCalls++,
              onExport: () => exportCalls++,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Replay'), findsOneWidget);
    expect(find.text('Bearbeiten'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);

    await tester.tap(find.text('Replay'));
    await tester.tap(find.text('Bearbeiten'));
    await tester.tap(find.text('Export'));
    await tester.pump();

    expect(replayCalls, 1);
    expect(editCalls, 1);
    expect(exportCalls, 1);
  });
}
