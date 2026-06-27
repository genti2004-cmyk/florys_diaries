import 'replay_geo_point.dart';

enum ReplayEventType {
  start,
  destination,
  document,
  photo,
  note,
  highlight,
  place,
  food,
  memory,
  end,
}

class ReplayEvent {
  const ReplayEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    this.subtitle = '',
    this.location = '',
    this.description = '',
    this.badge = '',
    this.position,
  });

  final String id;
  final ReplayEventType type;
  final String title;
  final DateTime date;
  final String subtitle;
  final String location;
  final String description;
  final String badge;
  final ReplayGeoPoint? position;

  bool get isHighlight => type == ReplayEventType.highlight;

  bool get hasPosition => position?.isValid ?? false;

  String get typeLabel {
    switch (type) {
      case ReplayEventType.start:
        return 'Start';
      case ReplayEventType.destination:
        return 'Ziel';
      case ReplayEventType.document:
        return 'Dokument';
      case ReplayEventType.photo:
        return 'Foto';
      case ReplayEventType.note:
        return 'Notiz';
      case ReplayEventType.highlight:
        return 'Highlight';
      case ReplayEventType.place:
        return 'Ort';
      case ReplayEventType.food:
        return 'Essen';
      case ReplayEventType.memory:
        return 'Erinnerung';
      case ReplayEventType.end:
        return 'Ende';
    }
  }
}
