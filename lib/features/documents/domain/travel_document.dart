import 'document_category.dart';

class TravelDocument {
  const TravelDocument({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.createdAt,
    this.description = '',
    this.fileName = '',
    this.relativePath = '',
    this.fileSizeBytes = 0,
    this.fileExtension = '',
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String categoryId;
  final DateTime createdAt;
  final String description;
  final String fileName;
  final String relativePath;
  final int fileSizeBytes;
  final String fileExtension;
  final bool isFavorite;

  DocumentCategory get category => DocumentCategories.byId(categoryId);

  bool get hasFile => relativePath.trim().isNotEmpty;

  String get fileTypeLabel {
    final extension = fileExtension.trim().toUpperCase();
    if (extension.isEmpty) {
      return hasFile ? 'DATEI' : 'OHNE DATEI';
    }
    return extension;
  }

  String get sizeLabel {
    if (fileSizeBytes <= 0) {
      return '';
    }
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    }
    if (fileSizeBytes < 1024 * 1024) {
      final kb = fileSizeBytes / 1024;
      return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    }
    final mb = fileSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'fileName': fileName,
      'relativePath': relativePath,
      'fileSizeBytes': fileSizeBytes,
      'fileExtension': fileExtension,
      'isFavorite': isFavorite,
    };
  }

  static TravelDocument fromJson(Map<String, dynamic> json) {
    return TravelDocument(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      categoryId: (json['categoryId'] as String?) ?? DocumentCategories.other.id,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      description: (json['description'] as String?) ?? '',
      fileName: (json['fileName'] as String?) ?? '',
      relativePath: (json['relativePath'] as String?) ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      fileExtension: (json['fileExtension'] as String?) ?? '',
      isFavorite: (json['isFavorite'] as bool?) ?? false,
    );
  }

  TravelDocument copyWith({
    String? id,
    String? title,
    String? categoryId,
    DateTime? createdAt,
    String? description,
    String? fileName,
    String? relativePath,
    int? fileSizeBytes,
    String? fileExtension,
    bool? isFavorite,
  }) {
    return TravelDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      relativePath: relativePath ?? this.relativePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      fileExtension: fileExtension ?? this.fileExtension,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
