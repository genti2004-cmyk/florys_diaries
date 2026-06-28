import 'package:flutter/foundation.dart';

import 'package:florys_diaries/features/backup/domain/backup_sync_status.dart';

class BackupSyncStatusStore extends ChangeNotifier {
  BackupSyncStatusStore({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  BackupSyncStatus _status = const BackupSyncStatus.initial();
  bool _isDisposed = false;

  BackupSyncStatus get status => _status;

  void markScheduled() {
    _setStatus(
      BackupSyncStatus(
        overallState: BackupSyncOverallState.scheduled,
        localState: _status.localState,
        cloudState: _status.cloudState,
        hasPendingChanges: true,
        lastStartedAt: _status.lastStartedAt,
        lastCompletedAt: _status.lastCompletedAt,
      ),
    );
  }

  void markRunStarted() {
    _setStatus(
      BackupSyncStatus(
        overallState: BackupSyncOverallState.running,
        localState: BackupSyncChannelState.checking,
        cloudState: BackupSyncChannelState.checking,
        hasPendingChanges: false,
        lastStartedAt: _clock(),
        lastCompletedAt: _status.lastCompletedAt,
      ),
    );
  }

  void markLocalCompleted({required bool created}) {
    _setStatus(
      BackupSyncStatus(
        overallState: _status.overallState,
        localState: created
            ? BackupSyncChannelState.created
            : BackupSyncChannelState.upToDate,
        cloudState: _status.cloudState,
        hasPendingChanges: _status.hasPendingChanges,
        lastStartedAt: _status.lastStartedAt,
        lastCompletedAt: _status.lastCompletedAt,
        lastError: _status.lastError,
      ),
    );
  }

  void markCloudCompleted(BackupSyncChannelState state) {
    _setStatus(
      BackupSyncStatus(
        overallState: _status.overallState,
        localState: _status.localState,
        cloudState: state,
        hasPendingChanges: _status.hasPendingChanges,
        lastStartedAt: _status.lastStartedAt,
        lastCompletedAt: _status.lastCompletedAt,
        lastError: _status.lastError,
      ),
    );
  }

  void markOperationFailed(BackupSyncTarget target, Object error) {
    _setStatus(
      BackupSyncStatus(
        overallState: BackupSyncOverallState.failed,
        localState: target == BackupSyncTarget.local
            ? BackupSyncChannelState.failed
            : _status.localState,
        cloudState: target == BackupSyncTarget.cloud
            ? BackupSyncChannelState.failed
            : _status.cloudState,
        hasPendingChanges: _status.hasPendingChanges,
        lastStartedAt: _status.lastStartedAt,
        lastCompletedAt: _status.lastCompletedAt,
        lastError: error.toString(),
      ),
    );
  }

  void markRunCompleted() {
    final hasFailure =
        _status.localState == BackupSyncChannelState.failed ||
        _status.cloudState == BackupSyncChannelState.failed;
    final requiresAttention =
        _status.cloudState == BackupSyncChannelState.signInRequired;

    _setStatus(
      BackupSyncStatus(
        overallState: hasFailure
            ? BackupSyncOverallState.failed
            : requiresAttention
            ? BackupSyncOverallState.attention
            : BackupSyncOverallState.completed,
        localState: _status.localState,
        cloudState: _status.cloudState,
        hasPendingChanges: false,
        lastStartedAt: _status.lastStartedAt,
        lastCompletedAt: _clock(),
        lastError: _status.lastError,
      ),
    );
  }

  void _setStatus(BackupSyncStatus status) {
    if (_isDisposed) {
      return;
    }
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
