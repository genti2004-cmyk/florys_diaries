import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';

class Trip {
  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.country,
    required this.startDate,
    required this.endDate,
    this.notes = '',
    this.documents = const [],
    this.albumEntries = const [],
    this.checklistItems = const [],
    this.photoCount = 0,
  });

  final String id;
  final String title;
  final String destination;
  final String country;
  final DateTime startDate;
  final DateTime endDate;
  final String notes;
  final List<TravelDocument> documents;
  final List<TripAlbumEntry> albumEntries;
  final List<TripChecklistItem> checklistItems;
  final int photoCount;

  int get documentCount => documents.length;

  int get albumEntryCount => albumEntries.length;

  int get highlightCount {
    return albumEntries.where((entry) => entry.isHighlight).length;
  }

  int get checklistCompletedCount {
    return checklistItems.where((item) => item.isCompleted).length;
  }

  int get checklistOpenCount => checklistItems.length - checklistCompletedCount;

  int get checklistOverdueCount {
    return checklistItems.where((item) => item.isOverdue).length;
  }

  double get checklistProgress {
    if (checklistItems.isEmpty) {
      return 0;
    }
    return checklistCompletedCount / checklistItems.length;
  }

  int get durationDays {
    final difference = endDate.difference(startDate).inDays + 1;
    return difference < 1 ? 1 : difference;
  }

  bool get isPast {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return endOnly.isBefore(todayOnly);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'country': country,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'notes': notes,
      'documents': documents.map((document) => document.toJson()).toList(),
      'albumEntries': albumEntries.map((entry) => entry.toJson()).toList(),
      'checklistItems': checklistItems.map((item) => item.toJson()).toList(),
      'photoCount': photoCount,
    };
  }

  static Trip fromJson(Map<String, dynamic> json) {
    return Trip(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      destination: (json['destination'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']) ?? DateTime.now(),
      notes: (json['notes'] as String?) ?? '',
      documents: _parseDocuments(json['documents']),
      albumEntries: _parseAlbumEntries(json['albumEntries']),
      checklistItems: _parseChecklistItems(json['checklistItems']),
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 0,
    );
  }

  Trip copyWith({
    String? id,
    String? title,
    String? destination,
    String? country,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    List<TravelDocument>? documents,
    List<TripAlbumEntry>? albumEntries,
    List<TripChecklistItem>? checklistItems,
    int? photoCount,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      country: country ?? this.country,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      documents: documents ?? this.documents,
      albumEntries: albumEntries ?? this.albumEntries,
      checklistItems: checklistItems ?? this.checklistItems,
      photoCount: photoCount ?? this.photoCount,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static List<TravelDocument> _parseDocuments(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(TravelDocument.fromJson)
        .where((document) => document.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  static List<TripAlbumEntry> _parseAlbumEntries(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(TripAlbumEntry.fromJson)
        .where((entry) => entry.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  static List<TripChecklistItem> _parseChecklistItems(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(TripChecklistItem.fromJson)
        .where(
          (item) => item.id.trim().isNotEmpty && item.title.trim().isNotEmpty,
        )
        .toList(growable: false);
  }
}
