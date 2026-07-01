import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/planner/domain/trip_plan_item.dart';
import 'package:florys_diaries/features/search/application/global_search_engine.dart';
import 'package:florys_diaries/features/search/domain/global_search_result.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  const engine = GlobalSearchEngine();

  test('indexes all supported travel content types', () {
    final index = engine.buildIndex(<Trip>[_sampleTrip()]);
    final types = index.map((result) => result.type).toSet();

    expect(types, containsAll(GlobalSearchResultType.values));
    expect(
      index.where((result) => result.type == GlobalSearchResultType.reminder),
      hasLength(2),
    );
  });

  test('searches across title, location, notes and categories', () {
    final index = engine.buildIndex(<Trip>[_sampleTrip()]);

    final hotel = engine.search(index, query: 'hotel');
    final museum = engine.search(index, query: 'museum ticket');
    final location = engine.search(index, query: 'Alexanderplatz');

    expect(
      hotel.map((result) => result.type),
      containsAll(<GlobalSearchResultType>{
        GlobalSearchResultType.planItem,
        GlobalSearchResultType.document,
      }),
    );
    expect(
      museum.single.type,
      GlobalSearchResultType.expense,
    );
    expect(
      location.any((result) => result.type == GlobalSearchResultType.place),
      isTrue,
    );
  });

  test('filters by content type, trip and year', () {
    final secondTrip = Trip(
      id: 'trip-2',
      title: 'Sommer 2027',
      destination: 'Split',
      country: 'Kroatien',
      startDate: DateTime(2027, 7, 1),
      endDate: DateTime(2027, 7, 7),
    );
    final index = engine.buildIndex(<Trip>[_sampleTrip(), secondTrip]);

    final results = engine.search(
      index,
      types: const <GlobalSearchResultType>{GlobalSearchResultType.trip},
      tripId: 'trip-1',
      year: 2026,
    );

    expect(results, hasLength(1));
    expect(results.single.title, 'Berlin Reise');
    expect(engine.availableYears(index), orderedEquals(<int>[2027, 2026]));
  });

  test('matches German umlaut transliterations', () {
    final trip = Trip(
      id: 'trip-umlaut',
      title: 'München Wochenende',
      destination: 'München',
      country: 'Deutschland',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 2),
    );
    final index = engine.buildIndex(<Trip>[trip]);

    expect(engine.search(index, query: 'Muenchen'), isNotEmpty);
  });
}

Trip _sampleTrip() {
  return Trip(
    id: 'trip-1',
    title: 'Berlin Reise',
    destination: 'Berlin',
    country: 'Deutschland',
    startDate: DateTime(2026, 5, 10),
    endDate: DateTime(2026, 5, 14),
    notes: 'Städtereise mit Kultur',
    planItems: <TripPlanItem>[
      TripPlanItem(
        id: 'plan-1',
        title: 'Hotel einchecken',
        date: DateTime(2026, 5, 10),
        startMinutes: 15 * 60,
        type: TripPlanItemType.hotel,
        location: 'Alexanderplatz',
        notes: 'Reservierung bereithalten',
        reminderMinutesBefore: 60,
      ),
    ],
    documents: <TravelDocument>[
      TravelDocument(
        id: 'document-1',
        title: 'Hotel Reservierung',
        categoryId: DocumentCategories.hotel.id,
        createdAt: DateTime(2026, 4, 1),
        description: 'Buchungsbestätigung',
      ),
      TravelDocument(
        id: 'document-2',
        title: 'Reisepass',
        categoryId: DocumentCategories.passport.id,
        createdAt: DateTime(2026, 1, 2),
        expiresAt: DateTime(2027, 1, 2),
        expiryReminderDaysBefore: 30,
      ),
    ],
    albumEntries: <TripAlbumEntry>[
      TripAlbumEntry(
        id: 'memory-1',
        typeId: TripAlbumEntryTypes.highlight.id,
        date: DateTime(2026, 5, 11),
        title: 'Sonnenuntergang',
        description: 'Schöner Blick über die Stadt',
        location: 'Fernsehturm',
      ),
    ],
    budgetAmountCents: 100000,
    budgetExpenses: <TripBudgetExpense>[
      TripBudgetExpense(
        id: 'expense-1',
        title: 'Museum Ticket',
        date: DateTime(2026, 5, 12),
        amountCents: 2400,
        category: TripExpenseCategory.activities,
        status: TripExpenseStatus.paid,
        notes: 'Pergamon Panorama',
      ),
    ],
  );
}
