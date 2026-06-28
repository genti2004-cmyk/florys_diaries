import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/application/backup_sync_status_store.dart';
import 'package:florys_diaries/features/backup/domain/backup_sync_status.dart';

void main() {
  test('bildet einen erfolgreichen automatischen Lauf vollständig ab', () {
    final times = <DateTime>[
      DateTime(2026, 6, 28, 12),
      DateTime(2026, 6, 28, 12, 1),
    ];
    var index = 0;
    final store = BackupSyncStatusStore(clock: () => times[index++]);
    addTearDown(store.dispose);

    store.markScheduled();
    expect(store.status.overallState, BackupSyncOverallState.scheduled);
    expect(store.status.hasPendingChanges, isTrue);

    store.markRunStarted();
    expect(store.status.overallState, BackupSyncOverallState.running);
    expect(store.status.localState, BackupSyncChannelState.checking);
    expect(store.status.cloudState, BackupSyncChannelState.checking);

    store.markLocalCompleted(created: true);
    store.markCloudCompleted(BackupSyncChannelState.upToDate);
    store.markRunCompleted();

    expect(store.status.overallState, BackupSyncOverallState.completed);
    expect(store.status.localState, BackupSyncChannelState.created);
    expect(store.status.cloudState, BackupSyncChannelState.upToDate);
    expect(store.status.lastCompletedAt, DateTime(2026, 6, 28, 12, 1));
  });

  test('Google-Anmeldung wird als notwendige Aktion angezeigt', () {
    final store = BackupSyncStatusStore();
    addTearDown(store.dispose);

    store.markRunStarted();
    store.markLocalCompleted(created: false);
    store.markCloudCompleted(BackupSyncChannelState.signInRequired);
    store.markRunCompleted();

    expect(store.status.overallState, BackupSyncOverallState.attention);
    expect(store.status.cloudState, BackupSyncChannelState.signInRequired);
  });

  test('Fehler eines Kanals bleibt nach Laufende sichtbar', () {
    final store = BackupSyncStatusStore();
    addTearDown(store.dispose);

    store.markRunStarted();
    store.markOperationFailed(
      BackupSyncTarget.local,
      const FormatException('Testfehler'),
    );
    store.markCloudCompleted(BackupSyncChannelState.upToDate);
    store.markRunCompleted();

    expect(store.status.overallState, BackupSyncOverallState.failed);
    expect(store.status.localState, BackupSyncChannelState.failed);
    expect(store.status.cloudState, BackupSyncChannelState.upToDate);
    expect(store.status.lastError, contains('Testfehler'));
  });
}
