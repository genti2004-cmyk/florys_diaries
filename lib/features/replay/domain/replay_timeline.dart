import 'replay_event.dart';

class ReplayTimeline {
  ReplayTimeline({required List<ReplayEvent> events})
    : events = List<ReplayEvent>.unmodifiable(_sortEvents(events));

  final List<ReplayEvent> events;

  bool get isEmpty => events.isEmpty;

  bool get isNotEmpty => events.isNotEmpty;

  int get length => events.length;

  ReplayEvent eventAt(int index) {
    final safeIndex = index.clamp(0, events.length - 1);
    return events[safeIndex];
  }

  double progressFor(int index) {
    if (events.length <= 1) {
      return events.isEmpty ? 0 : 1;
    }
    return (index + 1) / events.length;
  }

  static List<ReplayEvent> _sortEvents(List<ReplayEvent> events) {
    final sorted = List<ReplayEvent>.from(events);
    sorted.sort((left, right) {
      final dateCompare = left.date.compareTo(right.date);
      if (dateCompare != 0) {
        return dateCompare;
      }

      final typeCompare = _typeOrder(
        left.type,
      ).compareTo(_typeOrder(right.type));
      if (typeCompare != 0) {
        return typeCompare;
      }
      return left.title.toLowerCase().compareTo(right.title.toLowerCase());
    });
    return sorted;
  }

  static int _typeOrder(ReplayEventType type) {
    switch (type) {
      case ReplayEventType.start:
        return 0;
      case ReplayEventType.destination:
        return 1;
      case ReplayEventType.document:
        return 2;
      case ReplayEventType.place:
        return 3;
      case ReplayEventType.food:
        return 4;
      case ReplayEventType.note:
        return 5;
      case ReplayEventType.highlight:
        return 6;
      case ReplayEventType.memory:
        return 7;
      case ReplayEventType.photo:
        return 8;
      case ReplayEventType.end:
        return 9;
    }
  }
}
