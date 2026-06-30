import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/settings/presentation/privacy_and_data_screen.dart';

void main() {
  testWidgets('privacy overview stays usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PrivacyAndDataScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Datenschutz & Daten'), findsOneWidget);
    expect(find.text('Lokale Reisedaten'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    for (final key in <String>[
      'privacy-system-backup',
      'privacy-google-drive',
      'privacy-map-services',
      'privacy-no-tracking',
      'privacy-delete-data',
      'privacy-current-version-note',
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey<String>(key)),
        280,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    expect(find.text('Daten löschen'), findsOneWidget);
  });
}
