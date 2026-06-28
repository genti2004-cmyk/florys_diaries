import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:florys_diaries/features/backup/data/app_backup_service.dart';
import 'package:florys_diaries/features/backup/data/backup_content_fingerprint_service.dart';
import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';
import 'package:florys_diaries/features/backup/domain/local_backup_entry.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

typedef LocalBackupDirectoryProvider = Future<Directory> Function();

class LocalBackupService {
  const LocalBackupService({
    this.backupService = const AppBackupService(),
    this.fingerprintService = const BackupContentFingerprintService(),
    this.backupDirectoryProvider,
    this.clock,
  });

  final AppBackupService backupService;
  final BackupContentFingerprintService fingerprintService;
  final LocalBackupDirectoryProvider? backupDirectoryProvider;
  final DateTime Function()? clock;

  static const int maximumAutomaticBackups = 7;
  static const Duration automaticBackupInterval = Duration(hours: 24);
  static const String _directoryName = 'FlorysDiariesLocalBackups';

  Future<LocalBackupEntry?> createAutomaticBackupIfDue(List<Trip> trips) async {
    final entries = await listBackups();
    final automaticEntries = entries
        .where((entry) => entry.isAutomatic)
        .toList(growable: false);

    if (automaticEntries.isNotEmpty) {
      final elapsed = _now().difference(automaticEntries.first.createdAt);
      if (!elapsed.isNegative && elapsed < automaticBackupInterval) {
        return null;
      }
    }

    final contentFingerprint = await fingerprintService.calculate(trips);
    if (automaticEntries.isNotEmpty &&
        _fingerprintFromFileName(automaticEntries.first.fileName) ==
            contentFingerprint.toLowerCase()) {
      return null;
    }

    return _createLocalBackup(
      trips,
      automatic: true,
      contentFingerprint: contentFingerprint,
    );
  }

  Future<LocalBackupEntry> createLocalBackup(
    List<Trip> trips, {
    required bool automatic,
  }) async {
    final contentFingerprint = automatic
        ? await fingerprintService.calculate(trips)
        : null;

    return _createLocalBackup(
      trips,
      automatic: automatic,
      contentFingerprint: contentFingerprint,
    );
  }

  Future<LocalBackupEntry> _createLocalBackup(
    List<Trip> trips, {
    required bool automatic,
    required String? contentFingerprint,
  }) async {
    AppBackupCreateResult? created;

    try {
      created = await backupService.createBackup(trips);
      final directory = await _backupDirectory();
      final target = await _uniqueTargetFile(
        directory,
        created.createdAt,
        automatic: automatic,
        contentFingerprint: contentFingerprint,
      );
      final copied = await created.file.copy(target.path);

      final entry = LocalBackupEntry(
        file: copied,
        createdAt: created.createdAt,
        sizeBytes: await copied.length(),
        isAutomatic: automatic,
      );

      if (automatic) {
        await _pruneOldAutomaticBackups();
      }
      return entry;
    } finally {
      final temporaryFile = created?.file;
      if (temporaryFile != null && await temporaryFile.exists()) {
        try {
          await temporaryFile.delete();
        } on FileSystemException {
          // Das temporäre Arbeitsbackup wird vom Betriebssystem bereinigt.
        }
      }
    }
  }

  Future<List<LocalBackupEntry>> listBackups() async {
    final directory = await _backupDirectory();
    final entries = <LocalBackupEntry>[];

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !_isZipFile(entity.path)) {
        continue;
      }

      try {
        final stat = await entity.stat();
        final fileName = _baseName(entity.path);
        entries.add(
          LocalBackupEntry(
            file: entity,
            createdAt: _dateFromFileName(fileName) ?? stat.modified,
            sizeBytes: stat.size,
            isAutomatic: fileName.contains('_Auto_'),
          ),
        );
      } on FileSystemException {
        // Eine gerade entfernte oder nicht lesbare Datei wird übersprungen.
      }
    }

    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> deleteBackup(LocalBackupEntry entry) async {
    final allowedEntries = await listBackups();
    final isManagedFile = allowedEntries.any(
      (candidate) => candidate.file.absolute.path == entry.file.absolute.path,
    );
    if (!isManagedFile) {
      throw const FileSystemException(
        'Diese Datei gehört nicht zur lokalen Backup-Historie.',
      );
    }

    if (await entry.file.exists()) {
      await entry.file.delete();
    }
  }

  Future<Directory> _backupDirectory() async {
    final suppliedDirectory = backupDirectoryProvider == null
        ? null
        : await backupDirectoryProvider!();
    final directory =
        suppliedDirectory ??
        Directory(
          _join((await getApplicationSupportDirectory()).path, _directoryName),
        );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> _uniqueTargetFile(
    Directory directory,
    DateTime createdAt, {
    required bool automatic,
    required String? contentFingerprint,
  }) async {
    final kind = automatic ? 'Auto' : 'Lokal';
    final fingerprintSuffix = automatic && contentFingerprint != null
        ? '_F${_normalizeFingerprint(contentFingerprint)}'
        : '';
    final baseName =
        'FlorysDiaries_${kind}_${_fileStamp(createdAt)}$fingerprintSuffix';
    var candidate = File(_join(directory.path, '$baseName.zip'));
    var suffix = 2;

    while (await candidate.exists()) {
      candidate = File(_join(directory.path, '${baseName}_$suffix.zip'));
      suffix++;
    }
    return candidate;
  }

  Future<void> _pruneOldAutomaticBackups() async {
    final automaticEntries = (await listBackups())
        .where((entry) => entry.isAutomatic)
        .toList(growable: false);
    if (automaticEntries.length <= maximumAutomaticBackups) {
      return;
    }

    for (final entry in automaticEntries.skip(maximumAutomaticBackups)) {
      try {
        if (await entry.file.exists()) {
          await entry.file.delete();
        }
      } on FileSystemException {
        // Eine einzelne nicht löschbare Datei blockiert neue Backups nicht.
      }
    }
  }

  DateTime _now() => clock?.call() ?? DateTime.now();

  static String? _fingerprintFromFileName(String fileName) {
    final match = RegExp(
      r'_F([0-9a-f]{16,64})(?:_\d+)?\.zip$',
      caseSensitive: false,
    ).firstMatch(fileName);
    return match?.group(1)?.toLowerCase();
  }

  static String _normalizeFingerprint(String value) {
    final normalized = value.trim().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{16,64}$').hasMatch(normalized)) {
      throw ArgumentError.value(
        value,
        'contentFingerprint',
        'Der Backup-Fingerabdruck ist ungültig.',
      );
    }
    return normalized;
  }

  static DateTime? _dateFromFileName(String fileName) {
    final match = RegExp(
      r'_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})',
    ).firstMatch(fileName);
    if (match == null) {
      return null;
    }

    final values = List<int?>.generate(
      6,
      (index) => int.tryParse(match.group(index + 1) ?? ''),
      growable: false,
    );
    if (values.any((value) => value == null)) {
      return null;
    }

    try {
      return DateTime(
        values[0]!,
        values[1]!,
        values[2]!,
        values[3]!,
        values[4]!,
        values[5]!,
      );
    } on ArgumentError {
      return null;
    }
  }

  static bool _isZipFile(String path) {
    return path.toLowerCase().endsWith('.zip');
  }

  static String _fileStamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }

  static String _baseName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized
        .split('/')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? '' : parts.last;
  }

  static String _join(String left, String right) {
    return '$left${Platform.pathSeparator}$right';
  }
}
