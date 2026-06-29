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
      storageService: _RecoverableTripStorageService(),
      now: () => DateTime(2026, 6, 29),
    );
    final backupStore = BackupSyncStatusStore();
    await tripStore.load();

    addTearDown(tripStore.dispose);
    addTearDown(backupStore.dispose);

    await tester.pumpWidget(
      _TestShell(tripStore: tripStore, backupStore: backupStore),
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

  testWidgets('blocks the normal app shell until local data is safe', (
    tester,
  ) async {
    final storage = _RecoverableTripStorageService(failLoading: true);
    final tripStore = TripStore(
      storageService: storage,
      now: () => DateTime(2026, 6, 29),
    );
    final backupStore = BackupSyncStatusStore();
    await tripStore.load();

    addTearDown(tripStore.dispose);
    addTearDown(backupStore.dispose);

    await tester.pumpWidget(
      _TestShell(tripStore: tripStore, backupStore: backupStore),
    );
    await tester.pump();

    expect(find.text('Reisedaten nicht freigeben'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('trip-storage-retry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('trip-storage-backups')),
      findsOneWidget,
    );

    storage.failLoading = false;
    await tester.tap(find.byKey(const ValueKey<String>('trip-storage-retry')));
    await tester.pumpAndSettle();

    expect(find.text('Reisedaten nicht freigeben'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tripStore.hasLoadError, isFalse);
  });
}

class _TestShell extends StatelessWidget {
  const _TestShell({required this.tripStore, required this.backupStore});

  final TripStore tripStore;
  final BackupSyncStatusStore backupStore;

  @override
  Widget build(BuildContext context) {
    return BackupSyncStatusScope(
      store: backupStore,
      child: TripStoreScope(
        store: tripStore,
        child: const MaterialApp(home: MainShellScreen()),
      ),
    );
  }
}

class _RecoverableTripStorageService extends TripStorageService {
  _RecoverableTripStorageService({this.failLoading = false});

  bool failLoading;

  @override
  Future<List<Trip>> loadTrips() async {
    if (failLoading) {
      throw const TripStorageException(
        'Die lokalen Reisedaten konnten nicht sicher gelesen werden.',
      );
    }
    return const [];
  }
}
