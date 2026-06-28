import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/documents/application/trip_document_query.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_detail_hero_card.dart';
import 'package:florys_diaries/features/trips/presentation/widgets/trip_vault_section.dart';

void main() {
  testWidgets('trip detail modules do not overflow on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final trip = Trip(
      id: 'long',
      title:
          'Sehr lange Reisebezeichnung für einen realistischen schmalen Bildschirm',
      destination: 'Eine besonders lange Zielbezeichnung',
      country: 'Deutschland',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 14),
      notes:
          'Eine längere Notiz mit mehreren Informationen zur Reise und Vorbereitung.',
      photoCount: 120000,
    );
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 1000),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TripDetailHeroCard(trip: trip),
                  const SizedBox(height: 16),
                  TripVaultSection(
                    trip: trip,
                    visibleDocuments: const [],
                    searchController: controller,
                    query: const TripDocumentQuery(),
                    onAddDocument: () {},
                    onDocumentTap: (_) {},
                    onFavoriteToggle: (_) {},
                    onSearchChanged: (_) {},
                    onCategoryChanged: (_) {},
                    onSortChanged: (_) {},
                    onFavoritesChanged: (_) {},
                    onResetFilters: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Sehr lange Reisebezeichnung'), findsOneWidget);
    expect(find.text('120000 Fotos'), findsOneWidget);
  });
}
