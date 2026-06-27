import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/core/widgets/app_section_card.dart';
import 'package:florys_diaries/features/backup/data/app_backup_service.dart';
import 'package:florys_diaries/features/backup/data/automatic_cloud_backup_settings_service.dart';
import 'package:florys_diaries/features/backup/data/automatic_google_drive_backup_service.dart';
import 'package:florys_diaries/features/backup/data/backup_provider_registry.dart';
import 'package:florys_diaries/features/backup/data/google_drive_app_data_service.dart';
import 'package:florys_diaries/features/backup/data/local_backup_service.dart';
import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';
import 'package:florys_diaries/features/backup/domain/automatic_cloud_backup_settings.dart';
import 'package:florys_diaries/features/backup/domain/backup_provider.dart';
import 'package:florys_diaries/features/backup/domain/google_drive_backup_models.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/backup_panel.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/backup_provider_selector.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/google_drive_automatic_backup_settings.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/google_drive_backup_history.dart';
import 'package:florys_diaries/features/backup/presentation/widgets/local_backup_history.dart';
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

  BackupProvider get _selectedProvider =>
      _providerRegistry.providerFor(_selectedProviderId);

  @override
  void initState() {
    super.initState();
    _loadLocalBackups();
    _loadAutomaticCloudSettings();
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
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _automaticCloudSettings = AutomaticCloudBackupSettings.defaults;
        _isAutomaticCloudSettingsLoading = false;
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
        _statusText = _savedBackupSummary(
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
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText =
            'Lokal gesichert: ${entry.fileName} · '
            '${_formatBytes(entry.sizeBytes)}';
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
      _statusText = 'Cloud-Backup wird heruntergeladen ...';
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
        fileName: '${downloaded.backup.name} · ${downloaded.accountEmail}',
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cloud-Backup löschen?'),
          content: Text(
            '${entry.name}\n\n'
            'Sicherung vom ${_formatDateTime(entry.createdAt.toLocal())}.\n'
            'Dieser Cloud-Stand wird dauerhaft entfernt.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Dauerhaft löschen'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
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

  Future<void> _restoreLocalBackup(LocalBackupEntry entry) {
    return _inspectAndRestore(backupFile: entry.file, fileName: entry.fileName);
  }

  Future<void> _inspectAndRestore({
    required File backupFile,
    required String fileName,
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
      _statusText = _selectedBackupSummary(fileName, inspection);
    });

    final confirmed = await _confirmRestore(
      fileName: fileName,
      inspection: inspection,
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final store = TripStoreScope.of(context);
    setState(() {
      _isBusy = true;
      _statusText = 'Backup wird wiederhergestellt ...';
    });

    try {
      final result = await _backupService.restoreBackup(backupFile);
      await store.reloadFromStorage();
      if (!mounted) {
        return;
      }

      setState(() {
        _statusText = _restoreSummary(result);
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${result.tripCount} Reisen wurden erfolgreich wiederhergestellt.',
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
          'Die Wiederherstellung ist fehlgeschlagen. Die bisherigen Daten bleiben erhalten.',
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Lokales Backup löschen?'),
          content: Text(
            '${entry.fileName}\n\nDiese Sicherung wird dauerhaft vom Gerät entfernt.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Löschen'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);
    try {
      await _localBackupService.deleteBackup(entry);
      await _loadLocalBackups();
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
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Dieses Backup wiederherstellen?'),
          content: Text(
            'Datei: $fileName\n'
            'Erstellt: ${_formatDateTime(inspection.backupCreatedAt.toLocal())}\n'
            'Inhalt: ${inspection.tripCount} Reisen, '
            '${inspection.fileCount} Dateien, '
            '${_formatBytes(inspection.sizeBytes)}\n\n'
            'Alle aktuell gespeicherten Reisen und lokalen Dokumentdateien werden durch genau dieses Backup ersetzt.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.restore),
              label: const Text('Wiederherstellen'),
            ),
          ],
        );
      },
    );
  }

  void _showError(ScaffoldMessengerState messenger, String message) {
    setState(() => _statusText = message);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionCard(
            icon: Icons.lock_outline,
            title: 'Sicherheit',
            subtitle: 'PIN, Biometrie und verschlüsselte Ablage folgen später.',
          ),
          const SizedBox(height: 12),
          BackupProviderSelector(
            providers: _providerRegistry.providers,
            selectedId: _selectedProviderId,
            isBusy: _isBusy,
            onSelected: _selectProvider,
            onUnavailableSelected: _showUnavailableProvider,
          ),
          const SizedBox(height: 12),
          BackupPanel(
            providerName: _selectedProvider.displayName,
            isBusy: _isBusy,
            statusText: _statusText,
            onCreateBackup: _createBackup,
            onRestoreBackup: _restoreBackup,
          ),
          if (_selectedProviderId == BackupProviderId.googleDrive) ...[
            const SizedBox(height: 12),
            GoogleDriveBackupHistory(
              entries: _cloudBackups,
              accountEmail: _cloudAccountEmail,
              isLoading: _isCloudHistoryLoading,
              isBusy: _isBusy,
              onRefresh: _loadGoogleDriveBackups,
              onRestore: _restoreGoogleDriveBackup,
              onDelete: _deleteGoogleDriveBackup,
            ),
            const SizedBox(height: 12),
            GoogleDriveAutomaticBackupSettings(
              settings: _automaticCloudSettings,
              isLoading: _isAutomaticCloudSettingsLoading,
              isBusy: _isBusy,
              onEnabledChanged: _setAutomaticCloudEnabled,
              onIntervalChanged: _setAutomaticCloudInterval,
              onRetentionChanged: _setAutomaticCloudRetention,
              onRunNow: _runAutomaticCloudBackupNow,
            ),
          ],
          const SizedBox(height: 12),
          LocalBackupHistory(
            entries: _localBackups,
            isLoading: _isHistoryLoading,
            isBusy: _isBusy,
            onCreateLocalBackup: _createLocalBackup,
            onRestore: _restoreLocalBackup,
            onDelete: _deleteLocalBackup,
          ),
          const SizedBox(height: 12),
          const AppSectionCard(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle:
                'FlorysDiaries v0.18.2 – Reise-Checkliste und intelligente Vorbereitung.',
          ),
        ],
      ),
    );
  }

  static String _savedBackupSummary(
    AppBackupCreateResult result,
    String savedName,
    String providerName,
  ) {
    return 'Gespeichert auf $providerName: $savedName · '
        '${result.tripCount} Reisen, ${result.fileCount} Dateien, '
        '${_formatBytes(result.sizeBytes)}';
  }

  static String _selectedBackupSummary(
    String fileName,
    AppBackupInspectionResult inspection,
  ) {
    return 'Ausgewählt: $fileName · Backup vom '
        '${_formatDateTime(inspection.backupCreatedAt.toLocal())} · '
        '${inspection.tripCount} Reisen';
  }

  static String _restoreSummary(AppBackupRestoreResult result) {
    return 'Wiederhergestellt: ${result.tripCount} Reisen und '
        '${result.fileCount} Dateien · Backup vom '
        '${_formatDateTime(result.backupCreatedAt.toLocal())}';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}, '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
