import 'package:flutter/widgets.dart';

import 'package:florys_diaries/features/backup/application/backup_sync_status_store.dart';

class BackupSyncStatusScope extends InheritedNotifier<BackupSyncStatusStore> {
  const BackupSyncStatusScope({
    required BackupSyncStatusStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static BackupSyncStatusStore of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<BackupSyncStatusScope>();
    assert(
      scope != null,
      'BackupSyncStatusScope was not found in the widget tree.',
    );
    return scope!.notifier!;
  }
}
