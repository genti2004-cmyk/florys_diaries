import 'package:florys_diaries/features/trips/domain/trip.dart';

enum TravelAssistantInsightKind {
  preparation,
  documents,
  memories,
  highlights,
  overview,
}

enum TravelAssistantPriority {
  high,
  medium,
  low,
}

class TravelAssistantInsight {
  const TravelAssistantInsight({
    required this.id,
    required this.kind,
    required this.priority,
    required this.title,
    required this.message,
    this.tripId,
  });

  final String id;
  final TravelAssistantInsightKind kind;
  final TravelAssistantPriority priority;
  final String title;
  final String message;
  final String? tripId;
}

class TravelAssistantSnapshot {
  const TravelAssistantSnapshot({
    required this.tripCount,
    required this.upcomingCount,
    required this.pastCount,
    required this.countryCount,
    required this.documentCount,
    required this.fileCount,
    required this.photoCount,
    required this.memoryCount,
    required this.highlightCount,
    required this.nextTripReadiness,
    required this.insights,
    this.nextTrip,
  });

  final int tripCount;
  final int upcomingCount;
  final int pastCount;
  final int countryCount;
  final int documentCount;
  final int fileCount;
  final int photoCount;
  final int memoryCount;
  final int highlightCount;
  final int nextTripReadiness;
  final List<TravelAssistantInsight> insights;
  final Trip? nextTrip;

  bool get hasTrips => tripCount > 0;

  String get readinessLabel {
    if (nextTrip == null) {
      return 'Keine Reise geplant';
    }
    if (nextTripReadiness >= 80) {
      return 'Sehr gut vorbereitet';
    }
    if (nextTripReadiness >= 55) {
      return 'Gut gestartet';
    }
    return 'Noch vorbereiten';
  }
}

class TravelAssistantAnswer {
  const TravelAssistantAnswer({
    required this.title,
    required this.body,
    this.tripId,
  });

  final String title;
  final String body;
  final String? tripId;
}
