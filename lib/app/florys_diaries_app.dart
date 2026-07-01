import 'dart:async';

import 'package:flutter/material.dart';

import 'package:florys_diaries/core/constants/app_metadata.dart';
import '../features/backup/application/backup_sync_coordinator.dart';
import '../features/backup/application/backup_sync_status_scope.dart';
import '../features/backup/application/backup_sync_status_store.dart';
import '../features/backup/data/automatic_google_drive_backup_service.dart';
import '../features/backup/data/local_backup_service.dart';
import '../features/backup/domain/backup_sync_status.dart';
import '../features/reminders/application/trip_reminder_coordinator.dart';
import '../features/security/application/app_lock_controller.dart';
import '../features/security/application/app_lock_scope.dart';
import '../features/security/presentation/widgets/app_lock_gate.dart';
import '../features/shell/presentation/main_shell_screen.dart';
import '../features/trips/application/trip_store.dart';
import '../features/trips/application/trip_store_scope.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_controller.dart';
import 'theme/app_theme_scope.dart';

class FlorysDiariesApp extends StatefulWidget {
  const FlorysDiariesApp({super.key});

  @override
  State<FlorysDiariesApp> createState() => _FlorysDiariesAppState();
}

class _FlorysDiariesAppState extends State<FlorysDiariesApp>
    with WidgetsBindingObserver {
  static const _localBackupService = LocalBackupService();
  static final _automaticGoogleDriveBackupService =
      AutomaticGoogleDriveBackupService();

  late final TripStore _tripStore;
  late final AppThemeController _themeController;
  late final BackupSyncStatusStore _backupSyncStatusStore;
  late final BackupSyncCoordinator _backupSyncCoordinator;
  late final TripReminderCoordinator _reminderCoordinator;
  late final AppLockController _appLockController;

  bool _storeListenerAttached = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tripStore = TripStore();
    _themeController = AppThemeController();
    unawaited(_themeController.load());
    _backupSyncStatusStore = BackupSyncStatusStore();
    _reminderCoordinator = TripReminderCoordinator();
    _appLockController = AppLockController();
    unawaited(_appLockController.load());
    _backupSyncCoordinator = BackupSyncCoordinator(
      localBackupOperation: (trips) async {
        final created = await _localBackupService.createAutomaticBackupIfDue(
          trips,
        );
        _backupSyncStatusStore.markLocalCompleted(created: created != null);
      },
      cloudBackupOperation: (trips) async {
        final result = await _automaticGoogleDriveBackupService.runIfDue(trips);
        _backupSyncStatusStore.markCloudCompleted(
          _cloudStateFor(result.status),
        );
      },
      onScheduled: _backupSyncStatusStore.markScheduled,
      onRunStarted: _backupSyncStatusStore.markRunStarted,
      onRunCompleted: _backupSyncStatusStore.markRunCompleted,
      onError: (target, error, _) {
        _backupSyncStatusStore.markOperationFailed(target, error);
        final operation = target == BackupSyncTarget.local
            ? 'Automatisches lokales Backup'
            : 'Automatisches Google-Drive-Backup';
        debugPrint('$operation fehlgeschlagen: $error');
      },
    );

    _tripStore.addListener(_handleTripStoreChanged);
    _storeListenerAttached = true;
    _initializeStore();
  }

  Future<void> _initializeStore() async {
    await _tripStore.load();
    if (_isDisposed || _tripStore.hasLoadError) {
      return;
    }

    await Future.wait<void>([
      _backupSyncCoordinator.flush(_tripStore.trips),
      _reminderCoordinator.flush(_tripStore.trips),
    ]);
  }

  void _handleTripStoreChanged() {
    if (_isDisposed || _tripStore.isLoading || _tripStore.hasLoadError) {
      return;
    }
    _backupSyncCoordinator.schedule(_tripStore.trips);
    _reminderCoordinator.schedule(_tripStore.trips);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLockController.handleLifecycle(state);

    if (_isDisposed || _tripStore.isLoading || _tripStore.hasLoadError) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _backupSyncCoordinator.schedule(_tripStore.trips);
        _reminderCoordinator.schedule(_tripStore.trips);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_backupSyncCoordinator.flush(_tripStore.trips));
        unawaited(_reminderCoordinator.flush(_tripStore.trips));
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);

    if (_storeListenerAttached) {
      _tripStore.removeListener(_handleTripStoreChanged);
    }

    _backupSyncCoordinator.dispose();
    _reminderCoordinator.dispose();
    _backupSyncStatusStore.dispose();
    _tripStore.dispose();
    _themeController.dispose();
    _appLockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackupSyncStatusScope(
      store: _backupSyncStatusStore,
      child: TripStoreScope(
        store: _tripStore,
        child: AppLockScope(
          controller: _appLockController,
          child: AnimatedBuilder(
            animation: _themeController,
            builder: (context, child) {
              return AppThemeScope(
                controller: _themeController,
                child: MaterialApp(
                  title: AppMetadata.name,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.forPreset(_themeController.preset),
                  home: AppLockGate(
                    controller: _appLockController,
                    child: const MainShellScreen(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static BackupSyncChannelState _cloudStateFor(
    AutomaticGoogleDriveBackupStatus status,
  ) {
    return switch (status) {
      AutomaticGoogleDriveBackupStatus.disabled =>
        BackupSyncChannelState.disabled,
      AutomaticGoogleDriveBackupStatus.notDue ||
      AutomaticGoogleDriveBackupStatus.noChanges =>
        BackupSyncChannelState.upToDate,
      AutomaticGoogleDriveBackupStatus.signInRequired =>
        BackupSyncChannelState.signInRequired,
      AutomaticGoogleDriveBackupStatus.uploaded =>
        BackupSyncChannelState.created,
    };
  }
}
