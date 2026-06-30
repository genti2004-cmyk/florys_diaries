import 'package:florys_diaries/features/assistant/domain/travel_assistant_models.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TravelAssistantAnalyzer {
  const TravelAssistantAnalyzer();

  TravelAssistantSnapshot analyze(List<Trip> source, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final trips = List<Trip>.from(source)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final upcoming = trips
        .where((trip) => !_isPast(trip, today))
        .toList(growable: false);
    final past = trips
        .where((trip) => _isPast(trip, today))
        .toList(growable: false);
    final nextTrip = upcoming.isEmpty ? null : upcoming.first;
    final insights = <TravelAssistantInsight>[];

    if (trips.isEmpty) {
      insights.add(
        const TravelAssistantInsight(
          id: 'empty',
          kind: TravelAssistantInsightKind.overview,
          priority: TravelAssistantPriority.high,
          title: 'Dein Reisetagebuch wartet',
          message:
              'Lege eine Reise an. Danach kann der Assistent Unterlagen, '
              'Momente und Vorbereitung auswerten.',
        ),
      );
    } else {
      _addUpcomingInsights(upcoming, insights, today);
      _addPastTripInsights(past, insights);
      _addOverviewInsight(trips, insights);
    }

    insights.sort(_compareInsights);

    final countries = trips
        .map((trip) => trip.country.trim().toLowerCase())
        .where((country) => country.isNotEmpty)
        .toSet();
    final documents = trips.expand((trip) => trip.documents).toList();
    final entries = trips.expand((trip) => trip.albumEntries).toList();

    return TravelAssistantSnapshot(
      tripCount: trips.length,
      upcomingCount: upcoming.length,
      pastCount: past.length,
      countryCount: countries.length,
      documentCount: documents.length,
      fileCount: documents.where((document) => document.hasFile).length,
      photoCount: trips.fold(0, (sum, trip) => sum + trip.photoCount),
      memoryCount: entries.length,
      highlightCount: entries
          .where((entry) => entry.isHighlight || entry.isFavorite)
          .length,
      checklistItemCount: trips.fold<int>(
        0,
        (sum, trip) => sum + trip.checklistItems.length,
      ),
      checklistCompletedCount: trips.fold<int>(
        0,
        (sum, trip) => sum + trip.checklistCompletedCount,
      ),
      nextTripReadiness: nextTrip == null ? 0 : _readinessScore(nextTrip),
      insights: List.unmodifiable(insights.take(8)),
      nextTrip: nextTrip,
    );
  }

  void _addUpcomingInsights(
    List<Trip> trips,
    List<TravelAssistantInsight> target,
    DateTime today,
  ) {
    for (final trip in trips.take(3)) {
      final tripLabel = _tripLabel(trip);
      final daysUntil = _dateOnly(trip.startDate).difference(today).inDays;
      final documentsWithoutFile = trip.documents
          .where((document) => !document.hasFile)
          .length;

      if (trip.documents.isEmpty) {
        target.add(
          TravelAssistantInsight(
            id: 'documents-${trip.id}',
            kind: TravelAssistantInsightKind.documents,
            priority: daysUntil <= 30
                ? TravelAssistantPriority.high
                : TravelAssistantPriority.medium,
            title: 'Unterlagen für $tripLabel fehlen',
            message: daysUntil <= 0
                ? 'Die Reise beginnt heute oder läuft bereits. Hinterlege '
                      'Tickets, Buchungen oder Reisedokumente.'
                : 'Noch $daysUntil Tage. Hinterlege Tickets, Buchungen oder '
                      'Reisedokumente im Dokumentenbereich.',
            tripId: trip.id,
          ),
        );
      } else if (documentsWithoutFile > 0) {
        target.add(
          TravelAssistantInsight(
            id: 'files-${trip.id}',
            kind: TravelAssistantInsightKind.documents,
            priority: TravelAssistantPriority.medium,
            title: 'Dateien für $tripLabel ergänzen',
            message: documentsWithoutFile == 1
                ? 'Ein Dokumenteintrag hat noch keine gespeicherte Datei.'
                : '$documentsWithoutFile Dokumenteinträge haben noch keine '
                      'gespeicherte Datei.',
            tripId: trip.id,
          ),
        );
      }

      if (trip.notes.trim().isEmpty) {
        target.add(
          TravelAssistantInsight(
            id: 'notes-${trip.id}',
            kind: TravelAssistantInsightKind.preparation,
            priority: TravelAssistantPriority.low,
            title: 'Plan für $tripLabel ergänzen',
            message:
                'Notiere Adresse, Treffpunkte oder wichtige Aufgaben, '
                'damit alles an einem Ort bleibt.',
            tripId: trip.id,
          ),
        );
      }
    }
  }

  void _addPastTripInsights(
    List<Trip> trips,
    List<TravelAssistantInsight> target,
  ) {
    final newestFirst = List<Trip>.from(trips)
      ..sort((a, b) => b.endDate.compareTo(a.endDate));

    for (final trip in newestFirst.take(3)) {
      final tripLabel = _tripLabel(trip);
      final hasNotableMoment = trip.albumEntries.any(
        (entry) => entry.isHighlight || entry.isFavorite,
      );

      if (trip.photoCount > 0 && trip.albumEntries.isEmpty) {
        target.add(
          TravelAssistantInsight(
            id: 'album-${trip.id}',
            kind: TravelAssistantInsightKind.memories,
            priority: TravelAssistantPriority.medium,
            title: 'Fotos von $tripLabel erzählen noch keine Geschichte',
            message:
                '${trip.photoCount} Fotos sind erfasst. Ergänze eine '
                'Notiz oder Moment für das Reisealbum.',
            tripId: trip.id,
          ),
        );
      } else if (trip.albumEntries.isNotEmpty && !hasNotableMoment) {
        target.add(
          TravelAssistantInsight(
            id: 'highlight-${trip.id}',
            kind: TravelAssistantInsightKind.highlights,
            priority: TravelAssistantPriority.low,
            title: 'Lieblingsmoment aus $tripLabel markieren',
            message:
                'Die Reise hat Album-Einträge, aber noch kein Highlight '
                'oder keinen Favoriten.',
            tripId: trip.id,
          ),
        );
      } else if (trip.notes.trim().isEmpty && trip.albumEntries.isEmpty) {
        target.add(
          TravelAssistantInsight(
            id: 'memory-${trip.id}',
            kind: TravelAssistantInsightKind.memories,
            priority: TravelAssistantPriority.low,
            title: '$tripLabel kurz festhalten',
            message:
                'Ein kurzer Moment macht die Reise später lebendiger '
                'wiedererlebbar.',
            tripId: trip.id,
          ),
        );
      }
    }
  }

  void _addOverviewInsight(
    List<Trip> trips,
    List<TravelAssistantInsight> target,
  ) {
    final countryCounts = <String, int>{};
    final countryLabels = <String, String>{};

    for (final trip in trips) {
      final label = trip.country.trim();
      if (label.isEmpty) {
        continue;
      }
      final key = label.toLowerCase();
      countryCounts[key] = (countryCounts[key] ?? 0) + 1;
      countryLabels[key] = label;
    }

    if (countryCounts.isEmpty) {
      return;
    }

    final sorted = countryCounts.entries.toList()
      ..sort((a, b) {
        final countComparison = b.value.compareTo(a.value);
        if (countComparison != 0) {
          return countComparison;
        }
        return a.key.compareTo(b.key);
      });
    final top = sorted.first;
    if (top.value < 2) {
      return;
    }

    target.add(
      TravelAssistantInsight(
        id: 'top-country-${top.key}',
        kind: TravelAssistantInsightKind.overview,
        priority: TravelAssistantPriority.low,
        title: '${countryLabels[top.key]} ist dein häufigstes Reiseland',
        message:
            '${top.value} Reisen führen dorthin. In der Statistik findest '
            'du weitere Reise-Rekorde.',
      ),
    );
  }

  static int _readinessScore(Trip trip) {
    var score = 30;

    if (trip.notes.trim().isNotEmpty) {
      score += 20;
    }
    if (trip.documents.isNotEmpty) {
      score += 25;
    }
    if (trip.documents.isNotEmpty &&
        trip.documents.every((document) => document.hasFile)) {
      score += 15;
    }
    if (trip.albumEntries.isNotEmpty) {
      score += 10;
    }

    return score.clamp(0, 100).toInt();
  }

  static int _compareInsights(
    TravelAssistantInsight a,
    TravelAssistantInsight b,
  ) {
    final priority = _priorityWeight(b.priority) - _priorityWeight(a.priority);
    if (priority != 0) {
      return priority;
    }
    return a.title.compareTo(b.title);
  }

  static int _priorityWeight(TravelAssistantPriority priority) {
    return switch (priority) {
      TravelAssistantPriority.high => 3,
      TravelAssistantPriority.medium => 2,
      TravelAssistantPriority.low => 1,
    };
  }

  static bool _isPast(Trip trip, DateTime today) {
    return _dateOnly(trip.endDate).isBefore(today);
  }

  static String _tripLabel(Trip trip) {
    final destination = trip.destination.trim();
    if (destination.isNotEmpty) {
      return destination;
    }
    final title = trip.title.trim();
    if (title.isNotEmpty) {
      return title;
    }
    return 'Reise ohne Zielangabe';
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
