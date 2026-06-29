import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/application/backup_sync_status_scope.dart';
import 'package:florys_diaries/features/backup/application/backup_sync_status_store.dart';
import 'package:florys_diaries/features/shell/presentation/main_shell_screen.dart';
import 'package:florys_diaries/features/trips/application/trip_store.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';
import 'package:florys_diaries/features/trips/data/trip_storage_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  testWidgets('back from another tab returns to Reisen first', (tester) async {
    final tripStore = TripStore(
      storageService: _EmptyTripStorageService(),
      now: () => DateTime(2026, 6, 29),
    );
    final backupStore = BackupSyncStatusStore();
    await tripStore.load();

    addTearDown(tripStore.dispose);
    addTearDown(backupStore.dispose);

    await tester.pumpWidget(
      BackupSyncStatusScope(
        store: backupStore,
        child: TripStoreScope(
          store: tripStore,
          child: const MaterialApp(home: MainShellScreen()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Statistik'),
      ),
    );
    await tester.pump();

    var navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 3);

    await tester.binding.handlePopRoute();
    await tester.pump();

    navigationBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigationBar.selectedIndex, 0);
    expect(find.text('FlorysDiaries'), findsOneWidget);
  });
}

class _EmptyTripStorageService extends TripStorageService {
  @override
  Future<List<Trip>> loadTrips() async => const [];
}
