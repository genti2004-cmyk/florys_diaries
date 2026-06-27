import 'package:flutter/material.dart';

import '../features/backup/data/automatic_google_drive_backup_service.dart';
import '../features/backup/data/local_backup_service.dart';
import '../features/shell/presentation/main_shell_screen.dart';
import '../features/trips/application/trip_store.dart';
import '../features/trips/application/trip_store_scope.dart';
import 'theme/app_theme.dart';

class FlorysDiariesApp extends StatefulWidget {
  const FlorysDiariesApp({super.key});

  @override
  State<FlorysDiariesApp> createState() => _FlorysDiariesAppState();
}

class _FlorysDiariesAppState extends State<FlorysDiariesApp> {
  static const _localBackupService = LocalBackupService();
  static final _automaticGoogleDriveBackupService =
      AutomaticGoogleDriveBackupService();

  late final TripStore _tripStore;

  @override
  void initState() {
    super.initState();
    _tripStore = TripStore();
    _initializeStore();
  }

  Future<void> _initializeStore() async {
    await _tripStore.load();

    try {
      await _localBackupService.createAutomaticBackupIfDue(
        _tripStore.trips,
      );
    } catch (error) {
      debugPrint('Automatisches lokales Backup fehlgeschlagen: $error');
    }

    try {
      await _automaticGoogleDriveBackupService.runIfDue(
        _tripStore.trips,
      );
    } catch (error) {
      debugPrint('Automatisches Google-Drive-Backup fehlgeschlagen: $error');
    }
  }

  @override
  void dispose() {
    _tripStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TripStoreScope(
      store: _tripStore,
      child: MaterialApp(
        title: 'FlorysDiaries',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainShellScreen(),
      ),
    );
  }
}
