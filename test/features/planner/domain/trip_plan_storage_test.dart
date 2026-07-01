import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/trips/data/trip_storage_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  late Directory directory;
  late TripStorageService storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('florys_plan_test_');
    storage = TripStorageService(
      documentsDirectoryProvider: () async => directory,
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('storage persists day planner entries', () async {
    final trip = Trip(
      id: 'trip-1',
      title: 'Prag',
      destination: 'Prag',
      country: 'Tschechien',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 4),
      planItems: [
        TripPlanItem(
          id: 'plan-1',
          title: 'Karlsbrücke',
          date: DateTime(2026, 9, 2),
          startMinutes: 8 * 60,
          type: TripPlanItemType.sight,
          isCompleted: true,
        ),
      ],
    );

    await storage.saveTrips([trip]);
    final loaded = await storage.loadTrips();

    expect(loaded.single.planItems.single.title, 'Karlsbrücke');
    expect(loaded.single.planItems.single.isCompleted, isTrue);
  });
}
