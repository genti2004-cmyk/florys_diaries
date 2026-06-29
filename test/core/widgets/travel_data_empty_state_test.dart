import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/core/widgets/travel_data_empty_state.dart';

void main() {
  testWidgets('empty state remains readable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: TravelDataEmptyState(
              icon: Icons.public,
              title: 'Noch keine Reisedaten',
              description:
                  'Eine längere Beschreibung für einen schmalen Bildschirm.',
              hint: 'Dieser Hinweis bleibt ebenfalls vollständig lesbar.',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Noch keine Reisedaten'), findsOneWidget);
    expect(
      find.text('Dieser Hinweis bleibt ebenfalls vollständig lesbar.'),
      findsOneWidget,
    );
  });
}
