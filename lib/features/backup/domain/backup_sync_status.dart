enum BackupSyncTarget { local, cloud }

enum BackupSyncOverallState {
  idle,
  scheduled,
  running,
  completed,
  attention,
  failed,
}

enum BackupSyncChannelState {
  waiting,
  checking,
  created,
  upToDate,
  disabled,
  signInRequired,
  failed,
}

class BackupSyncStatus {
  const BackupSyncStatus({
    required this.overallState,
    required this.localState,
    required this.cloudState,
    required this.hasPendingChanges,
    this.lastStartedAt,
    this.lastCompletedAt,
    this.lastError,
  });

  const BackupSyncStatus.initial()
    : overallState = BackupSyncOverallState.idle,
      localState = BackupSyncChannelState.waiting,
      cloudState = BackupSyncChannelState.waiting,
      hasPendingChanges = false,
      lastStartedAt = null,
      lastCompletedAt = null,
      lastError = null;

  final BackupSyncOverallState overallState;
  final BackupSyncChannelState localState;
  final BackupSyncChannelState cloudState;
  final bool hasPendingChanges;
  final DateTime? lastStartedAt;
  final DateTime? lastCompletedAt;
  final String? lastError;
}
