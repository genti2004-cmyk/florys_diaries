import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/statistics/application/travel_statistics_analyzer.dart';
import 'package:florys_diaries/features/statistics/domain/travel_statistics.dart';
import 'package:florys_diaries/features/statistics/presentation/statistics_screen.dart';
import 'package:florys_diaries/features/trips/application/trip_store.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  testWidgets('reuses statistics while the trip list instance is unchanged', (
    tester,
  ) async {
    final store = TripStore();
    final analyzer = _CountingStatisticsAnalyzer();
    late StateSetter rebuildParent;

    await tester.pumpWidget(
      MaterialApp(
        home: TripStoreScope(
          store: store,
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuildParent = setState;
              return Scaffold(body: StatisticsScreen(analyzer: analyzer));
            },
          ),
        ),
      ),
    );

    expect(analyzer.callCount, 1);
    expect(find.text('Deine Reisebilanz'), findsOneWidget);

    rebuildParent(() {});
    await tester.pump();

    expect(analyzer.callCount, 1);
  });
}

class _CountingStatisticsAnalyzer extends TravelStatisticsAnalyzer {
  int callCount = 0;

  @override
  TravelStatistics analyze(List<Trip> trips) {
    callCount += 1;
    return super.analyze(trips);
  }
}
