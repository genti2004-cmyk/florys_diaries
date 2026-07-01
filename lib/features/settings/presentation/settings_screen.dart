import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/features/backup/application/backup_sync_status_scope.dart';
import 'package:florys_diaries/features/backup/data/app_backup_service.dart';
import 'package:florys_diaries/features/backup/data/automatic_cloud_backup_settings_service.dart';
import 'package:florys_diaries/features/backup/data/automatic_google_drive_backup_service.dart';
import 'package:florys_diaries/features/backup/data/data_safety_service.dart';
import 'package:florys_diaries/features/backup/data/backup_provider_registry.dart';
import 'package:florys_diaries/features/backup/data/google_drive_app_data_service.dart';
import 'package:florys_diaries/features/backup/data/local_backup_service.dart';
import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';
import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';
import 'package:florys_diaries/features/backup/domain/data_safety_report.dart';
import 'package:florys_diaries/features/backup/domain/google_drive_backup_models.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/reminders/presentation/screens/upcoming_reminders_screen.dart';
import 'package:florys_diaries/features/release/presentation/screens/release_quality_screen.dart';
import 'package:florys_diaries/features/security/presentation/screens/security_settings_screen.dart';
import 'package:florys_diaries/features/settings/presentation/settings_backup_formatter.dart';
import 'package:florys_diaries/features/settings/presentation/privacy_and_data_screen.dart';
import 'package:florys_diaries/features/settings/presentation/widgets/settings_backup_dialogs.dart';
import 'package:florys_diaries/features/settings/presentation/widgets/settings_content.dart';
import 'package:florys_diaries/features/trips/application/trip_store_scope.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _backupService = AppBackupService();
  static const _providerRegistry = BackupProviderRegistry();
  static const _localBackupService = LocalBackupService();
  static final _googleDriveService = GoogleDriveAppDataService();
  static const _automaticCloudSettingsService =
      AutomaticCloudBackupSettingsService();
  static final _automaticGoogleDriveBackupService =
      AutomaticGoogleDriveBackupService();
  static const _dataSafetyService = DataSafetyService();

  bool _isBusy = false;
  bool _isHistoryLoading = true;
  String? _statusText;
  List<LocalBackupEntry> _localBackups = const [];
  List<GoogleDriveStoredBackup> _cloudBackups = const [];
  bool _isCloudHistoryLoading = false;
  bool _cloudHistoryLoaded = false;
  String? _cloudAccountEmail;
  BackupProviderId _selectedProviderId = BackupProviderId.device;
  AutomaticCloudBackupSettings _automaticCloudSettings =
      AutomaticCloudBackupSettings.defaults;
  bool _isAutomaticCloudSettingsLoading = true;
  bool _isDataSafetyLoading = false;
  bool _initialSafetyCheckScheduled = false;
  DataSafetyReport? _dataSafetyReport;

  BackupProvider get _selectedProvider =>
      _providerRegistry.providerFor(_selectedProviderId);

  @override
  void initState() {
    super.initState();
    _loadLocalBackups();
    _loadAutomaticCloudSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialSafetyCheckScheduled) {
      return;
    }
    _initialSafetyCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_runDataSafetyCheck(showErrors: false));
      }
    });
  }

  Future<void> _runDataSafetyCheck({bool showErrors = true}) async {
    if (_isDataSafetyLoading) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isDataSafetyLoading = true);

    try {
      final store = TripStoreScope.of(context);
      final report = await _dataSafetyService.inspect(
        store.trips,
        localBackups: _isHistoryLoading ? null : _localBackups,
      );
      if (!mounted) {
        return;
      }
      setState(() => _dataSafetyReport = report);
    } on FileSystemException catch (error) {
      if (mounted && showErrors) {
        _showError(messenger, error.message);
      }
    } catch (_) {
      if (mounted && showErrors) {
        _showError(
          messenger,
          'Die Daten-Sicherheitsprüfung konnte nicht abgeschlossen werden.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDataSafetyLoading = false);
      }
    }
  }

  Future<void> _loadLocalBackups() async {
    try {
      final entries = await _localBackupService.listBackups();
      if (!mounted) {
        return;
      }
      setState(() {
        _localBackups = entries;
        _isHistoryLoading = false;
      });
      if (_dataSafetyReport != null && !_isBusy) {
        unawaited(_runDataSafetyCheck(showErrors: false));
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localBackups = const [];
        _isHistoryLoading = false;
      });
    }
  }

  Future<void> _loadAutomaticCloudSettings() async {
    try {
      final settings = await _automaticCloudSettingsService.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _automaticCloudSettings = settings;
        _isAutomaticCloudSettingsLoading = false;
      });
    } on AutomaticCloudBackupSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _automaticCloudSettings = AutomaticCloudBackupSettings.defaults;
        _isAutomaticCloudSettingsLoading = false;
        _statusText = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _automaticCloudSettings = AutomaticCloudBackupSettings.defaults;
        _isAutomaticCloudSettingsLoading = false;
        _statusText =
            'Die automatischen Backup-Einstellungen konnten nicht geladen '
            'werden.';
      });
    }
  }

  Future<void> _saveAutomaticCloudSettings(
    AutomaticCloudBackupSettings settings, {
    String? statusText,
  }) async {
    final previous = _automaticCloudSettings;
    setState(() {
      _automaticCloudSettings = settings;
      if (statusText != null) {
        _statusText = statusText;
      }
    });

    try {
      await _automaticCloudSettingsService.save(settings);
    } on AutomaticCloudBackupSettingsException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _automaticCloudSettings = previous);
      _showError(ScaffoldMessenger.of(context), error.message);
    } on FileSystemException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _automaticCloudSettings = previous);
      _showError(ScaffoldMessenger.of(context), error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _automaticCloudSettings = previous);
      _showError(
        ScaffoldMessenger.of(context),
        'Die Einstellung konnte nicht gespeichert werden.',
      );
    }
  }

  Future<void> _setAutomaticCloudEnabled(bool enabled) {
    return _saveAutomaticCloudSettings(
      _automaticCloudSettings.copyWith(enabled: enabled),
      statusText: enabled
          ? 'Automatische Google-Drive-Sicherung ist aktiviert.'
          : 'Automatische Google-Drive-Sicherung ist ausgeschaltet.',
    );
  }

  Future<void> _setAutomaticCloudInterval(int days) {
    return _saveAutomaticCloudSettings(
      _automaticCloudSettings.copyWith(intervalDays: days),
      statusText: days == 1
          ? 'Automatisches Cloud-Intervall: täglich.'
          : 'Automatisches Cloud-Intervall: alle $days Tage.',
    );
  }

  Future<void> _setAutomaticCloudRetention(int count) {
    return _saveAutomaticCloudSettings(
      _automaticCloudSettings.copyWith(retentionLimit: count),
      statusText: 'Es bleiben höchstens $count automatische Cloud-Backups.',
    );
  }

  Future<void> _runAutomaticCloudBackupNow() async {
    if (_isBusy) {
      return;
    }

    final store = TripStoreScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isBusy = true;
      _statusText = 'Automatisches Google-Drive-Backup wird erstellt ...';
    });

    try {
      final result = await _automaticGoogleDriveBackupService.runNow(
        store.trips,
      );
      if (!mounted) {
        return;
      }

      if (result.status == AutomaticGoogleDriveBackupStatus.signInRequired) {
        setState(() {
          _statusText = 'Google-Drive-Anmeldung wurde abgebrochen.';
        });
        return;
      }

      if (result.status == AutomaticGoogleDriveBackupStatus.noChanges) {
        setState(() {
          _automaticCloudSettings = result.settings;
          _statusText = 'Keine Änderungen seit der letzten Sicherung.';
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Keine Änderungen seit der letzten Sicherung.'),
          ),
        );
        return;
      }

      setState(() {
        _automaticCloudSettings = result.settings;
        _statusText = result.deletedCount == 0
            ? 'Automatisches Cloud-Backup wurde gespeichert.'
            : 'Automatisches Cloud-Backup wurde gespeichert. '
                  '${result.deletedCount} ältere automatische Sicherungen wurden entfernt.';
      });
      await _loadGoogleDriveBackups(showErrors: false);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Automatisches Google-Drive-Backup gespeichert.'),
        ),
      );
    } on FileSystemException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
    } catch (_) {
      if (mounted) {
        _showError(
          messenger,
          'Das automatische Google-Drive-Backup ist fehlgeschlagen.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _loadGoogleDriveBackups({bool showErrors = true}) async {
    if (_isCloudHistoryLoading) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isCloudHistoryLoading = true);

    try {
      final result = await _googleDriveService.loadBackupHistory();
      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _cloudHistoryLoaded = false;
          _statusText = 'Google-Drive-Anmeldung wurde abgebrochen.';
        });
        return;
      }

      setState(() {
        _cloudBackups = result.backups;
        _cloudAccountEmail = result.accountEmail;
        _cloudHistoryLoaded = true;
      });
    } on FileSystemException catch (error) {
      if (mounted && showErrors) {
        _showError(messenger, error.message);
      }
    } catch (_) {
      if (mounted && showErrors) {
        _showError(
          messenger,
          'Die Google-Drive-Backup-Historie konnte nicht geladen werden.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCloudHistoryLoading = false);
      }
    }
  }

  Future<void> _createBackup() async {
    if (_isBusy) {
      return;
    }

    final store = TripStoreScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    AppBackupCreateResult? result;

    setState(() {
      _isBusy = true;
      _statusText = 'Neues Backup wird erstellt ...';
    });

    try {
      final provider = _selectedProvider;
      final created = await _backupService.createBackup(store.trips);
      result = created;
      final saved = await provider.saveBackup(created.file);
      if (!mounted) {
        return;
      }

      if (saved == null) {
        setState(() {
          _statusText =
              'Speichern wurde abgebrochen. Es wurde kein neues Backup abgelegt.';
        });
        return;
      }

      setState(() {
        _statusText = SettingsBackupFormatter.savedBackupSummary(
          created,
          saved.displayName,
          provider.displayName,
        );
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Backup gespeichert: ${saved.displayName}')),
      );
      if (provider.id == BackupProviderId.googleDrive) {
        await _loadGoogleDriveBackups(showErrors: false);
      }
    } on FileSystemException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
    } on FormatException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
    } catch (_) {
      if (mounted) {
        _showError(messenger, 'Das Backup konnte nicht gespeichert werden.');
      }
    } finally {
      final temporaryFile = result?.file;
      if (temporaryFile != null && await temporaryFile.exists()) {
        try {
          await temporaryFile.delete();
        } on FileSystemException {
          // Die temporäre Datei wird spätestens vom Betriebssystem bereinigt.
        }
      }
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _createLocalBackup() async {
    if (_isBusy) {
      return;
    }

    final store = TripStoreScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isBusy = true;
      _statusText = 'Lokale Sicherung wird erstellt ...';
    });

    try {
      final entry = await _localBackupService.createLocalBackup(
        store.trips,
        automatic: false,
      );
      await _loadLocalBackups();
      await _runDataSafetyCheck(showErrors: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText =
            'Lokal gesichert: ${entry.fileName} · '
            '${SettingsBackupFormatter.formatBytes(entry.sizeBytes)}';
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Lokale Sicherung wurde erstellt.')),
      );
    } on FileSystemException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
    } catch (_) {
      if (mounted) {
        _showError(
          messenger,
          'Die lokale Sicherung konnte nicht erstellt werden.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _restoreBackup() async {
    if (_isBusy) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    BackupProviderSelection? selection;
    try {
      selection = await _selectedProvider.pickBackup();
    } on FileSystemException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
      return;
    } catch (_) {
      if (mounted) {
        _showError(messenger, 'Das Backup konnte nicht ausgewählt werden.');
      }
      return;
    }

    if (!mounted || selection == null) {
      return;
    }

    try {
      await _inspectAndRestore(
        backupFile: selection.file,
        fileName: selection.displayName,
        sourceLabel: _selectedProvider.displayName,
      );
    } finally {
      if (selection.deleteAfterUse && await selection.file.exists()) {
        try {
          await selection.file.delete();
        } on FileSystemException {
          // Temporäre Cloud-Dateien werden spätestens vom System bereinigt.
        }
      }
    }
  }

  Future<void> _restoreGoogleDriveBackup(GoogleDriveStoredBackup entry) async {
    if (_isBusy) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    GoogleDriveDownloadResult? result;
    setState(() {
      _isBusy = true;
      _statusText =
          'Cloud-Backup wird für die Inhaltsprüfung heruntergeladen ...';
    });

    try {
      result = await _googleDriveService.downloadBackup(entry);
      if (!mounted) {
        return;
      }
      if (result == null) {
        setState(() {
          _statusText = 'Google-Drive-Anmeldung wurde abgebrochen.';
        });
        return;
      }
    } on FileSystemException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
      return;
    } catch (_) {
      if (mounted) {
        _showError(
          messenger,
          'Das Cloud-Backup konnte nicht heruntergeladen werden.',
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }

    final downloaded = result;
    if (!mounted) {
      return;
    }

    try {
      await _inspectAndRestore(
        backupFile: downloaded.file,
        fileName: downloaded.backup.name,
        sourceLabel: 'Google Drive',
        sourceDetail: 'Konto: ${downloaded.accountEmail}',
      );
    } finally {
      if (await downloaded.file.exists()) {
        try {
          await downloaded.file.delete();
        } on FileSystemException {
          // Temporäre Cloud-Dateien werden spätestens vom System bereinigt.
        }
      }
    }
  }

  Future<void> _deleteGoogleDriveBackup(GoogleDriveStoredBackup entry) async {
    if (_isBusy) {
      return;
    }

    final confirmed = await showGoogleDriveBackupDeleteDialog(context, entry);
    if (!mounted || !confirmed) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isBusy = true;
      _statusText = 'Cloud-Backup wird gelöscht ...';
    });

    try {
      final deleted = await _googleDriveService.deleteBackup(entry);
      if (!mounted) {
        return;
      }
      if (!deleted) {
        setState(() {
          _statusText = 'Google-Drive-Anmeldung wurde abgebrochen.';
        });
        return;
      }

      await _loadGoogleDriveBackups(showErrors: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText = 'Cloud-Backup gelöscht: ${entry.name}';
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Cloud-Backup wurde gelöscht.')),
      );
    } on FileSystemException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
    } catch (_) {
      if (mounted) {
        _showError(messenger, 'Das Cloud-Backup konnte nicht gelöscht werden.');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _restoreLocalBackup(LocalBackupEntry entry) async {
    if (!entry.canRestore) {
      final message =
          entry.validationError ??
          'Diese lokale Sicherung ist beschädigt und kann nicht '
              'wiederhergestellt werden.';
      _showError(ScaffoldMessenger.of(context), message);
      return;
    }

    await _inspectAndRestore(
      backupFile: entry.file,
      fileName: entry.fileName,
      sourceLabel: 'Lokales Backup',
      sourceDetail: entry.isAutomatic
          ? 'Automatisch erstellt'
          : 'Manuell erstellt',
    );
  }

  Future<void> _inspectAndRestore({
    required File backupFile,
    required String fileName,
    required String sourceLabel,
    String? sourceDetail,
  }) async {
    if (_isBusy) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    late final AppBackupInspectionResult inspection;

    setState(() {
      _isBusy = true;
      _statusText = 'Ausgewähltes Backup wird geprüft ...';
    });

    try {
      inspection = await _backupService.inspectBackup(backupFile);
    } on FormatException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
      return;
    } on FileSystemException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
      return;
    } catch (_) {
      if (mounted) {
        _showError(
          messenger,
          'Die ausgewählte Backup-Datei konnte nicht geprüft werden.',
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = SettingsBackupFormatter.selectedBackupSummary(
        fileName,
        inspection,
      );
    });

    final confirmed = await _confirmRestore(
      fileName: fileName,
      inspection: inspection,
      sourceLabel: sourceLabel,
      sourceDetail: sourceDetail,
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final store = TripStoreScope.of(context);
    setState(() {
      _isBusy = true;
      _statusText = 'Sicherheitskopie des aktuellen Stands wird erstellt ...';
    });

    try {
      final safetyBackup = await _localBackupService.createSafetyBackup(
        store.trips,
      );
      await _loadLocalBackups();
      if (!mounted) {
        return;
      }

      setState(() {
        _statusText =
            'Sicherheitskopie erstellt: ${safetyBackup.fileName}. '
            'Backup wird wiederhergestellt ...';
      });

      final result = await _backupService.restoreBackup(backupFile);
      await store.reloadFromStorage();
      await _runDataSafetyCheck(showErrors: false);
      if (!mounted) {
        return;
      }

      setState(() {
        _statusText =
            '${SettingsBackupFormatter.restoreSummary(result)} '
            'Der vorherige Stand bleibt als Sicherheitskopie erhalten.';
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${result.tripCount} Reisen wurden wiederhergestellt. Der vorherige Stand wurde lokal gesichert.',
          ),
        ),
      );
    } on FormatException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
    } on FileSystemException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
    } catch (_) {
      if (mounted) {
        _showError(
          messenger,
          'Die Wiederherstellung wurde abgebrochen oder ist fehlgeschlagen. Die bisherigen Daten bleiben erhalten; eine bereits erstellte Sicherheitskopie bleibt verfügbar.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _selectProvider(BackupProviderId id) {
    if (_isBusy || id == _selectedProviderId) {
      return;
    }

    final shouldLoadCloudHistory =
        id == BackupProviderId.googleDrive && !_cloudHistoryLoaded;
    setState(() {
      _selectedProviderId = id;
      _statusText = 'Backup-Ziel: ${_selectedProvider.displayName}';
    });

    if (shouldLoadCloudHistory) {
      unawaited(_loadGoogleDriveBackups());
    }
  }

  void _showUnavailableProvider(BackupProvider provider) {
    final message =
        '${provider.displayName} ist vorbereitet, aber noch nicht verbunden.';
    setState(() => _statusText = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _deleteLocalBackup(LocalBackupEntry entry) async {
    if (_isBusy) {
      return;
    }

    final confirmed = await showLocalBackupDeleteDialog(context, entry);
    if (!mounted || !confirmed) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);
    try {
      await _localBackupService.deleteBackup(entry);
      await _loadLocalBackups();
      await _runDataSafetyCheck(showErrors: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText = 'Lokales Backup gelöscht: ${entry.fileName}';
      });
    } on FileSystemException catch (error) {
      if (mounted) {
        _showError(messenger, error.message);
      }
    } catch (_) {
      if (mounted) {
        _showError(
          messenger,
          'Das lokale Backup konnte nicht gelöscht werden.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<bool?> _confirmRestore({
    required String fileName,
    required AppBackupInspectionResult inspection,
    required String sourceLabel,
    String? sourceDetail,
  }) {
    return showBackupRestoreConfirmationDialog(
      context,
      fileName: fileName,
      inspection: inspection,
      sourceLabel: sourceLabel,
      sourceDetail: sourceDetail,
    );
  }

  void _showError(ScaffoldMessengerState messenger, String message) {
    setState(() => _statusText = message);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _openReminders() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const UpcomingRemindersScreen(),
      ),
    );
  }


  void _openSecurity() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const SecuritySettingsScreen(),
      ),
    );
  }

  void _openPrivacyAndData() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PrivacyAndDataScreen()),
    );
  }

  void _openReleaseQuality() {
    final store = TripStoreScope.of(context);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReleaseQualityScreen(
          trips: List.unmodifiable(store.trips),
          localBackups: List.unmodifiable(_localBackups),
          dataSafetyReport: _dataSafetyReport,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backupSyncStatus = BackupSyncStatusScope.of(context).status;

    return SettingsContent(
      backupSyncStatus: backupSyncStatus,
      providers: _providerRegistry.providers,
      selectedProviderId: _selectedProviderId,
      selectedProviderName: _selectedProvider.displayName,
      isBusy: _isBusy,
      statusText: _statusText,
      localBackups: _localBackups,
      isLocalHistoryLoading: _isHistoryLoading,
      cloudBackups: _cloudBackups,
      cloudAccountEmail: _cloudAccountEmail,
      isCloudHistoryLoading: _isCloudHistoryLoading,
      automaticCloudSettings: _automaticCloudSettings,
      isAutomaticCloudSettingsLoading: _isAutomaticCloudSettingsLoading,
      dataSafetyReport: _dataSafetyReport,
      isDataSafetyLoading: _isDataSafetyLoading,
      onProviderSelected: _selectProvider,
      onUnavailableProviderSelected: _showUnavailableProvider,
      onCreateBackup: _createBackup,
      onRestoreBackup: _restoreBackup,
      onRefreshCloudBackups: () => _loadGoogleDriveBackups(),
      onRestoreCloudBackup: _restoreGoogleDriveBackup,
      onDeleteCloudBackup: _deleteGoogleDriveBackup,
      onAutomaticCloudEnabledChanged: _setAutomaticCloudEnabled,
      onAutomaticCloudIntervalChanged: _setAutomaticCloudInterval,
      onAutomaticCloudRetentionChanged: _setAutomaticCloudRetention,
      onRunAutomaticCloudBackup: _runAutomaticCloudBackupNow,
      onCreateLocalBackup: _createLocalBackup,
      onRestoreLocalBackup: _restoreLocalBackup,
      onDeleteLocalBackup: _deleteLocalBackup,
      onRunDataSafetyCheck: () => unawaited(_runDataSafetyCheck()),
      onOpenReminders: _openReminders,
      onOpenSecurity: _openSecurity,
      onOpenReleaseQuality: _openReleaseQuality,
      onOpenPrivacy: _openPrivacyAndData,
    );
  }
}
