import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/assistant/domain/travel_assistant_models.dart';
import 'package:florys_diaries/features/assistant/presentation/widgets/assistant_insight_card.dart';
import 'package:florys_diaries/features/assistant/presentation/widgets/assistant_overview_grid.dart';

void main() {
  testWidgets('assistant cards do not overflow on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const snapshot = TravelAssistantSnapshot(
      tripCount: 999999,
      upcomingCount: 999999,
      pastCount: 999999,
      countryCount: 999999,
      documentCount: 999999,
      fileCount: 999999,
      photoCount: 999999,
      memoryCount: 999999,
      highlightCount: 999999,
      checklistItemCount: 999999,
      checklistCompletedCount: 500000,
      nextTripReadiness: 100,
      insights: [],
    );
    const insight = TravelAssistantInsight(
      id: 'long',
      kind: TravelAssistantInsightKind.documents,
      priority: TravelAssistantPriority.high,
      title:
          'Sehr lange Reisebezeichnung mit vielen zusätzlichen Wörtern '
          'für einen realistischen Überlauftest',
      message:
          'Dieser ebenfalls sehr lange Hinweis prüft, ob die Karte bei '
          'schmalen Displays sauber wächst und keine Inhalte abschneidet.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 900),
            textScaler: TextScaler.linear(1.3),
          ),
          child: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  AssistantOverviewGrid(snapshot: snapshot),
                  SizedBox(height: 16),
                  AssistantInsightCard(insight: insight),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Sehr lange Reisebezeichnung'), findsOneWidget);
  });
}
