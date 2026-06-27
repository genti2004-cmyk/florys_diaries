import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripExportService {
  const TripExportService({this.fileService = const TravelFileService()});

  final TravelFileService fileService;

  Future<File> exportTripAsZip(Trip trip) async {
    final exportRoot = await _freshExportRoot(trip);
    await _writeTripMetadata(trip, exportRoot);
    await _copyDocumentFiles(trip, exportRoot);

    final targetZip = await _targetZipFile(trip);
    if (await targetZip.exists()) {
      await targetZip.delete();
    }

    final encoder = ZipFileEncoder();
    encoder.create(targetZip.path);
    await encoder.addDirectory(exportRoot, includeDirName: true);
    encoder.closeSync();

    return targetZip;
  }

  Future<Directory> _freshExportRoot(Trip trip) async {
    final temp = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final exportRoot = Directory(
      _joinMany([
        temp.path,
        'florys_diaries_exports',
        '${_safeName(trip.title)}_$stamp',
      ]),
    );

    if (await exportRoot.exists()) {
      await exportRoot.delete(recursive: true);
    }
    await exportRoot.create(recursive: true);
    return exportRoot;
  }

  Future<File> _targetZipFile(Trip trip) async {
    final temp = await getTemporaryDirectory();
    final directory = Directory(
      _joinMany([temp.path, 'florys_diaries_exports']),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    return File(
      _joinMany([directory.path, '${_safeName(trip.title)}_$stamp.zip']),
    );
  }

  Future<void> _writeTripMetadata(Trip trip, Directory exportRoot) async {
    final encoder = const JsonEncoder.withIndent('  ');
    final metadataFile = File(_joinMany([exportRoot.path, 'reise.json']));
    await metadataFile.writeAsString(
      encoder.convert(trip.toJson()),
      flush: true,
    );

    final readme = File(_joinMany([exportRoot.path, 'README.txt']));
    await readme.writeAsString(
      'FlorysDiaries Reise-Export\n\n'
      'Reise: ${trip.title}\n'
      'Ziel: ${trip.destination}, ${trip.country}\n'
      'Zeitraum: ${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}\n\n'
      'Die Datei reise.json enthält die strukturierten Reisedaten.\n'
      'Der Ordner documents enthält die exportierten Dokumentdateien.\n',
      flush: true,
    );
  }

  Future<void> _copyDocumentFiles(Trip trip, Directory exportRoot) async {
    final documentsDirectory = Directory(
      _joinMany([exportRoot.path, 'documents']),
    );
    await documentsDirectory.create(recursive: true);

    for (final document in trip.documents) {
      final source = await fileService.resolveDocumentFile(document);
      if (source == null || !await source.exists()) {
        continue;
      }

      final targetName = _safeName(
        document.fileName.trim().isEmpty ? document.title : document.fileName,
      );
      final target = File(
        _joinMany([documentsDirectory.path, '${document.id}_$targetName']),
      );
      await source.copy(target.path);
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String _safeName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    return cleaned.isEmpty ? 'reise' : cleaned;
  }

  static String _joinMany(List<String> parts) {
    return parts
        .where((part) => part.trim().isNotEmpty)
        .join(Platform.pathSeparator);
  }
}
