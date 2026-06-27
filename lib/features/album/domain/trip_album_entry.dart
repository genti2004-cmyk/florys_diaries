class TripAlbumEntry {
  const TripAlbumEntry({
    required this.id,
    required this.typeId,
    required this.date,
    required this.title,
    this.description = '',
    this.location = '',
    this.isFavorite = false,
  });

  final String id;
  final String typeId;
  final DateTime date;
  final String title;
  final String description;
  final String location;
  final bool isFavorite;

  bool get isHighlight => typeId == TripAlbumEntryTypes.highlight.id;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typeId': typeId,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'location': location,
      'isFavorite': isFavorite,
    };
  }

  static TripAlbumEntry fromJson(Map<String, dynamic> json) {
    return TripAlbumEntry(
      id: (json['id'] as String?) ?? '',
      typeId: (json['typeId'] as String?) ?? TripAlbumEntryTypes.note.id,
      date: _parseDate(json['date']) ?? DateTime.now(),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      location: (json['location'] as String?) ?? '',
      isFavorite: (json['isFavorite'] as bool?) ?? false,
    );
  }

  TripAlbumEntry copyWith({
    String? id,
    String? typeId,
    DateTime? date,
    String? title,
    String? description,
    String? location,
    bool? isFavorite,
  }) {
    return TripAlbumEntry(
      id: id ?? this.id,
      typeId: typeId ?? this.typeId,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
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

class TripAlbumEntryType {
  const TripAlbumEntryType({required this.id, required this.label});

  final String id;
  final String label;
}

class TripAlbumEntryTypes {
  const TripAlbumEntryTypes._();

  static const note = TripAlbumEntryType(id: 'note', label: 'Tagesnotiz');
  static const highlight = TripAlbumEntryType(
    id: 'highlight',
    label: 'Highlight',
  );
  static const place = TripAlbumEntryType(id: 'place', label: 'Ort');
  static const food = TripAlbumEntryType(id: 'food', label: 'Essen');
  static const memory = TripAlbumEntryType(id: 'memory', label: 'Erinnerung');

  static const List<TripAlbumEntryType> values = [
    note,
    highlight,
    place,
    food,
    memory,
  ];

  static TripAlbumEntryType byId(String id) {
    return values.firstWhere((type) => type.id == id, orElse: () => note);
  }
}
