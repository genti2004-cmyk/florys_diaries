import 'dart:io';

class TravelDocumentPathPolicy {
  const TravelDocumentPathPolicy._();

  static String normalize(String value) {
    return value
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'^\./+'), '')
        .replaceAll(RegExp(r'/+'), '/');
  }

  static String safeTripFolderName(String tripId) {
    return _safeSegment(tripId, fallback: 'reise', allowDot: false);
  }

  static String safeDocumentIdPart(String documentId) {
    return _safeSegment(documentId, fallback: 'dokument', allowDot: false);
  }

  static String safeFileName(String fileName) {
    return _safeSegment(fileName, fallback: 'datei', allowDot: true);
  }

  static String relativeTripPath(String tripId) {
    return 'Reisen/${safeTripFolderName(tripId)}';
  }

  static String relativeTripDocumentsPath(String tripId) {
    return '${relativeTripPath(tripId)}/documents';
  }

  static String relativeDocumentPath(String tripId, String fileName) {
    return '${relativeTripDocumentsPath(tripId)}/${safeFileName(fileName)}';
  }

  static bool isSafeRelativePath(String value) {
    final path = normalize(value);
    if (path.isEmpty ||
        path.startsWith('/') ||
        path.contains('\u0000') ||
        RegExp(r'^[a-zA-Z]:').hasMatch(path)) {
      return false;
    }

    final segments = path.split('/');
    return !segments.any(
      (segment) => segment.isEmpty || segment == '.' || segment == '..',
    );
  }

  static bool isManagedDocumentPath(String value) {
    final path = normalize(value);
    if (!isSafeRelativePath(path)) {
      return false;
    }

    final segments = path.split('/');
    if (segments.length != 4 ||
        segments[0] != 'Reisen' ||
        segments[2] != 'documents') {
      return false;
    }

    return segments[1] == safeTripFolderName(segments[1]) &&
        segments[3] == safeFileName(segments[3]);
  }

  static bool isDocumentPathForTrip(String value, String tripId) {
    final path = normalize(value);
    if (!isManagedDocumentPath(path)) {
      return false;
    }

    final segments = path.split('/');
    return segments[1] == safeTripFolderName(tripId);
  }

  static String toPlatformPath(String relativePath) {
    return normalize(relativePath).split('/').join(Platform.pathSeparator);
  }

  static String _safeSegment(
    String value, {
    required String fallback,
    required bool allowDot,
  }) {
    final pattern = allowDot
        ? RegExp(r'[^a-zA-Z0-9._-]+')
        : RegExp(r'[^a-zA-Z0-9_-]+');

    final cleaned = value
        .trim()
        .replaceAll(pattern, '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');

    return cleaned.isEmpty ? fallback : cleaned;
  }
}
