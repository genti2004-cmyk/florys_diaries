import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:florys_diaries/features/backup/data/google_drive_auth_service.dart';
import 'package:florys_diaries/features/backup/domain/google_drive_backup_models.dart';

class GoogleDriveRestClient {
  GoogleDriveRestClient({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<GoogleDriveStoredBackup> upload(
    GoogleDriveSession session,
    File sourceFile, {
    bool automatic = false,
  }) {
    return _withNetworkErrors(() async {
      if (!await sourceFile.exists()) {
        throw const FileSystemException(
          'Die zu sichernde Backup-Datei wurde nicht gefunden.',
        );
      }

      final remoteName = _baseName(sourceFile.path);
      final length = await sourceFile.length();
      final headers = await session.authorizationHeaders();

      final createResponse = await _client.post(
        Uri.https('www.googleapis.com', '/upload/drive/v3/files', const {
          'uploadType': 'resumable',
          'fields': 'id,name,createdTime,modifiedTime,size',
        }),
        headers: {
          ...headers,
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Upload-Content-Type': 'application/zip',
          'X-Upload-Content-Length': '$length',
        },
        body: jsonEncode({
          'name': remoteName,
          'parents': const ['appDataFolder'],
          'description': automatic
              ? 'Automatisches FlorysDiaries Backup'
              : 'FlorysDiaries Backup',
          'appProperties': {
            'florysDiariesBackup': 'true',
            'backupFormat': 'zip',
            'backupKind': automatic ? 'automatic' : 'manual',
          },
        }),
      );

      if (createResponse.statusCode != 200 &&
          createResponse.statusCode != 201) {
        _throwDriveError(createResponse.statusCode, createResponse.body);
      }

      final uploadLocation = createResponse.headers['location'];
      if (uploadLocation == null || uploadLocation.trim().isEmpty) {
        throw const FileSystemException(
          'Google Drive hat keine Upload-Adresse zurückgegeben.',
        );
      }

      final uploadRequest =
          http.StreamedRequest('PUT', Uri.parse(uploadLocation))
            ..headers.addAll(headers)
            ..headers['Content-Type'] = 'application/zip'
            ..contentLength = length;

      final responseFuture = _client.send(uploadRequest);
      await uploadRequest.sink.addStream(sourceFile.openRead());
      await uploadRequest.sink.close();

      final streamedResponse = await responseFuture;
      final responseBody = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode != 200 &&
          streamedResponse.statusCode != 201) {
        _throwDriveError(streamedResponse.statusCode, responseBody);
      }

      return GoogleDriveStoredBackup.fromJson(_decodeObject(responseBody));
    });
  }

  Future<List<GoogleDriveStoredBackup>> listBackups(
    GoogleDriveSession session,
  ) {
    return _withNetworkErrors(() async {
      final headers = await session.authorizationHeaders();
      final response = await _client.get(
        Uri.https('www.googleapis.com', '/drive/v3/files', {
          'spaces': 'appDataFolder',
          'q':
              "trashed = false and appProperties has { key='florysDiariesBackup' and value='true' }",
          'orderBy': 'createdTime desc',
          'pageSize': '100',
          'fields':
              'files(id,name,createdTime,modifiedTime,size,appProperties)',
        }),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _throwDriveError(response.statusCode, response.body);
      }

      final rawFiles = _decodeObject(response.body)['files'];
      if (rawFiles is! List) {
        return const [];
      }

      final backups = <GoogleDriveStoredBackup>[];
      for (final rawFile in rawFiles) {
        if (rawFile is! Map) {
          continue;
        }
        final json = rawFile.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final backup = GoogleDriveStoredBackup.tryFromJson(json);
        if (backup != null) {
          backups.add(backup);
        }
      }

      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    });
  }

  Future<File> download(
    GoogleDriveSession session,
    GoogleDriveStoredBackup backup,
  ) {
    return _withNetworkErrors(() async {
      final headers = await session.authorizationHeaders();
      final request = http.Request(
        'GET',
        Uri.https('www.googleapis.com', '/drive/v3/files/${backup.id}', const {
          'alt': 'media',
        }),
      )..headers.addAll(headers);

      final response = await _client.send(request);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        _throwDriveError(response.statusCode, body);
      }

      final temporaryDirectory = await getTemporaryDirectory();
      final importsDirectory = Directory(
        _join(temporaryDirectory.path, 'florys_diaries_google_drive_imports'),
      );
      await importsDirectory.create(recursive: true);

      final target = File(
        _join(
          importsDirectory.path,
          '${DateTime.now().microsecondsSinceEpoch}_${_safeFileName(backup.name)}',
        ),
      );

      try {
        await response.stream.pipe(target.openWrite());
      } catch (_) {
        if (await target.exists()) {
          await target.delete();
        }
        rethrow;
      }
      return target;
    });
  }

  Future<void> deleteBackup(
    GoogleDriveSession session,
    GoogleDriveStoredBackup backup,
  ) {
    return _withNetworkErrors(() async {
      final headers = await session.authorizationHeaders();
      final response = await _client.delete(
        Uri.https('www.googleapis.com', '/drive/v3/files/${backup.id}'),
        headers: headers,
      );

      if (response.statusCode != 204) {
        _throwDriveError(response.statusCode, response.body);
      }
    });
  }

  Future<T> _withNetworkErrors<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FileSystemException {
      rethrow;
    } on SocketException {
      throw const FileSystemException(
        'Keine Internetverbindung. Google Drive ist nicht erreichbar.',
      );
    } on http.ClientException catch (error) {
      throw FileSystemException(
        error.message.trim().isEmpty
            ? 'Google Drive ist momentan nicht erreichbar.'
            : 'Google Drive: ${error.message}',
      );
    }
  }

  static Map<String, dynamic> _decodeObject(String source) {
    if (source.trim().isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FileSystemException(
        'Google Drive hat eine unerwartete Antwort zurückgegeben.',
      );
    }

    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  static Never _throwDriveError(int statusCode, String responseBody) {
    final message = _driveErrorMessage(responseBody);

    if (statusCode == 401 || statusCode == 403) {
      throw FileSystemException(
        'Google Drive hat den Zugriff abgelehnt. '
        'Bitte den Vorgang erneut starten und die Berechtigung bestätigen.'
        '${message == null ? '' : ' ($message)'}',
      );
    }

    if (statusCode == 404) {
      throw const FileSystemException(
        'Das ausgewählte Google-Drive-Backup wurde nicht gefunden.',
      );
    }

    throw FileSystemException(
      message == null
          ? 'Google Drive antwortete mit Fehler $statusCode.'
          : 'Google Drive: $message',
    );
  }

  static String? _driveErrorMessage(String responseBody) {
    try {
      final error = _decodeObject(responseBody)['error'];
      if (error is Map) {
        final message = error['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Eine unlesbare Antwort wird über den HTTP-Status beschrieben.
    }
    return null;
  }

  static String _baseName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized
        .split('/')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? 'FlorysDiaries_Backup.zip' : parts.last;
  }

  static String _safeFileName(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (cleaned.isEmpty) {
      return 'FlorysDiaries_Backup.zip';
    }
    return cleaned.toLowerCase().endsWith('.zip') ? cleaned : '$cleaned.zip';
  }

  static String _join(String left, String right) {
    return '$left${Platform.pathSeparator}$right';
  }
}
