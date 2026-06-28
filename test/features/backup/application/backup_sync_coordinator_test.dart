import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/application/backup_sync_coordinator.dart';
import 'package:florys_diaries/features/backup/domain/backup_sync_status.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  test(
    'schedule bündelt schnelle Änderungen und nutzt den neuesten Stand',
    () async {
      final localSnapshots = <List<Trip>>[];
      final cloudSnapshots = <List<Trip>>[];
      final coordinator = BackupSyncCoordinator(
        debounceDuration: Duration.zero,
        localBackupOperation: (trips) async {
          localSnapshots.add(trips);
        },
        cloudBackupOperation: (trips) async {
          cloudSnapshots.add(trips);
        },
      );
      addTearDown(coordinator.dispose);

      coordinator.schedule(<Trip>[_trip('first')]);
      coordinator.schedule(<Trip>[_trip('latest')]);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(localSnapshots, hasLength(1));
      expect(cloudSnapshots, hasLength(1));
      expect(localSnapshots.single.single.id, 'latest');
      expect(cloudSnapshots.single.single.id, 'latest');
    },
  );

  test('flush führt beide Prüfungen sofort aus', () async {
    var localCalls = 0;
    var cloudCalls = 0;
    final coordinator = BackupSyncCoordinator(
      debounceDuration: const Duration(hours: 1),
      localBackupOperation: (trips) async {
        localCalls++;
        expect(trips.single.id, 'trip-1');
      },
      cloudBackupOperation: (trips) async {
        cloudCalls++;
        expect(trips.single.id, 'trip-1');
      },
    );
    addTearDown(coordinator.dispose);

    await coordinator.flush(<Trip>[_trip('trip-1')]);

    expect(localCalls, 1);
    expect(cloudCalls, 1);
  });

  test('ein lokaler Fehler blockiert die Cloud-Prüfung nicht', () async {
    final errors = <String>[];
    var cloudCalls = 0;
    final coordinator = BackupSyncCoordinator(
      localBackupOperation: (_) async {
        throw const FormatException('Lokaler Testfehler');
      },
      cloudBackupOperation: (_) async {
        cloudCalls++;
      },
      onError: (target, error, _) {
        errors.add('$target: $error');
      },
    );
    addTearDown(coordinator.dispose);

    await coordinator.flush(<Trip>[_trip('trip-1')]);

    expect(cloudCalls, 1);
    expect(errors, hasLength(1));
    expect(errors.single, contains(BackupSyncTarget.local.name));
  });

  test(
    'eine Änderung während eines laufenden Checks wird nachgeholt',
    () async {
      final firstRunGate = Completer<void>();
      final snapshots = <String>[];
      var localCalls = 0;

      final coordinator = BackupSyncCoordinator(
        debounceDuration: Duration.zero,
        localBackupOperation: (trips) async {
          localCalls++;
          snapshots.add(trips.single.id);
          if (localCalls == 1) {
            await firstRunGate.future;
          }
        },
        cloudBackupOperation: (_) async {},
      );
      addTearDown(coordinator.dispose);

      final firstFlush = coordinator.flush(<Trip>[_trip('first')]);
      await Future<void>.delayed(Duration.zero);

      coordinator.schedule(<Trip>[_trip('second')]);
      firstRunGate.complete();
      await firstFlush;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(snapshots, <String>['first', 'second']);
    },
  );
  test('meldet geplanten, gestarteten und abgeschlossenen Lauf', () async {
    final events = <String>[];
    final coordinator = BackupSyncCoordinator(
      localBackupOperation: (_) async {},
      cloudBackupOperation: (_) async {},
      onScheduled: () => events.add('scheduled'),
      onRunStarted: () => events.add('started'),
      onRunCompleted: () => events.add('completed'),
    );
    addTearDown(coordinator.dispose);

    await coordinator.flush(<Trip>[_trip('trip-1')]);

    expect(events, <String>['scheduled', 'started', 'completed']);
  });
}

Trip _trip(String id) {
  return Trip(
    id: id,
    title: id,
    destination: 'Berlin',
    country: 'Deutschland',
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2026, 6, 2),
  );
}
