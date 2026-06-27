import 'package:florys_diaries/features/assistant/domain/travel_assistant_models.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TravelAssistantAnswerService {
  const TravelAssistantAnswerService();

  TravelAssistantAnswer answer({
    required String question,
    required List<Trip> trips,
    required TravelAssistantSnapshot snapshot,
  }) {
    final query = question.trim().toLowerCase();

    if (query.isEmpty) {
      return const TravelAssistantAnswer(
        title: 'Stelle eine Frage',
        body: 'Zum Beispiel: „Was steht als Nächstes an?“ oder '
            '„Wo fehlen Dokumente?“',
      );
    }

    if (_containsAny(query, const ['nächste', 'naechste', 'als nächstes', 'wann'])) {
      return _nextTripAnswer(snapshot.nextTrip);
    }
    if (_containsAny(query, const ['dokument', 'ticket', 'unterlage', 'datei'])) {
      return _documentAnswer(trips);
    }
    if (_containsAny(query, const ['highlight', 'lieblingsmoment', 'favorit'])) {
      return _highlightAnswer(trips, snapshot);
    }
    if (_containsAny(query, const ['foto', 'erinner', 'album', 'notiz'])) {
      return _memoryAnswer(trips, snapshot);
    }
    if (_containsAny(query, const ['land', 'länder', 'laender', 'ziel', 'wo war'])) {
      return _countryAnswer(trips);
    }
    if (_containsAny(query, const ['übersicht', 'uebersicht', 'statistik', 'zusammenfassung'])) {
      return _summaryAnswer(snapshot);
    }

    return TravelAssistantAnswer(
      title: 'Lokale Reiseanalyse',
      body: 'Ich habe ${snapshot.tripCount} Reisen durchsucht. Frage nach der '
          'nächsten Reise, fehlenden Dokumenten, Erinnerungen, Highlights oder '
          'bereisten Ländern.',
    );
  }

  TravelAssistantAnswer _nextTripAnswer(Trip? trip) {
    if (trip == null) {
      return const TravelAssistantAnswer(
        title: 'Keine kommende Reise',
        body: 'Aktuell ist keine zukünftige Reise gespeichert.',
      );
    }

    final today = _dateOnly(DateTime.now());
    final days = _dateOnly(trip.startDate).difference(today).inDays;
    final timing = days <= 0
        ? 'Die Reise beginnt heute oder läuft bereits.'
        : days == 1
            ? 'Die Reise beginnt morgen.'
            : 'Die Reise beginnt in $days Tagen.';

    return TravelAssistantAnswer(
      title: '${trip.destination}, ${trip.country}',
      body: '$timing ${_dateRange(trip)} · ${trip.durationDays} Reisetage · '
          '${trip.documentCount} Dokumente.',
      tripId: trip.id,
    );
  }

  TravelAssistantAnswer _documentAnswer(List<Trip> trips) {
    final missing = <Trip>[];
    var withoutFile = 0;
    var total = 0;

    for (final trip in trips) {
      total += trip.documentCount;
      final missingFiles = trip.documents.where((document) => !document.hasFile).length;
      withoutFile += missingFiles;
      if (!trip.isPast && (trip.documents.isEmpty || missingFiles > 0)) {
        missing.add(trip);
      }
    }

    if (trips.isEmpty) {
      return const TravelAssistantAnswer(
        title: 'Noch keine Reisedaten',
        body: 'Lege zuerst eine Reise an, damit Unterlagen geprüft werden können.',
      );
    }

    if (missing.isEmpty && withoutFile == 0) {
      return TravelAssistantAnswer(
        title: 'Dokumente sehen gut aus',
        body: '$total Dokumente sind erfasst und alle gespeicherten Einträge '
            'haben eine Datei.',
      );
    }

    final destinations = missing.take(3).map((trip) => trip.destination).join(', ');
    final destinationText = destinations.isEmpty
        ? ''
        : ' Prüfe besonders: $destinations.';
    final emptyUpcoming = missing.where((trip) => trip.documents.isEmpty).length;
    final details = <String>[
      if (emptyUpcoming > 0)
        emptyUpcoming == 1
            ? 'Eine kommende Reise hat noch keine Dokumente.'
            : '$emptyUpcoming kommende Reisen haben noch keine Dokumente.',
      if (withoutFile > 0)
        withoutFile == 1
            ? 'Ein Dokumenteintrag hat noch keine Datei.'
            : '$withoutFile Dokumenteinträge haben noch keine Datei.',
    ].join(' ');

    return TravelAssistantAnswer(
      title: 'Unterlagen prüfen',
      body: '$details$destinationText',
      tripId: missing.isEmpty ? null : missing.first.id,
    );
  }

  TravelAssistantAnswer _highlightAnswer(
    List<Trip> trips,
    TravelAssistantSnapshot snapshot,
  ) {
    final highlights = trips
        .expand(
          (trip) => trip.albumEntries
              .where((entry) => entry.isHighlight || entry.isFavorite)
              .map((entry) => (trip: trip, entry: entry)),
        )
        .toList()
      ..sort((a, b) => b.entry.date.compareTo(a.entry.date));

    if (highlights.isEmpty) {
      return const TravelAssistantAnswer(
        title: 'Noch keine Lieblingsmomente',
        body: 'Markiere im Reisealbum einen Eintrag als Highlight oder Favorit.',
      );
    }

    final latest = highlights.first;
    return TravelAssistantAnswer(
      title: latest.entry.title,
      body: '${latest.trip.destination} · ${_formatDate(latest.entry.date)}. '
          'Insgesamt sind ${snapshot.highlightCount} Highlights gespeichert.',
      tripId: latest.trip.id,
    );
  }

  TravelAssistantAnswer _memoryAnswer(
    List<Trip> trips,
    TravelAssistantSnapshot snapshot,
  ) {
    final undocumented = trips.where(
      (trip) => trip.isPast && trip.albumEntries.isEmpty && trip.notes.trim().isEmpty,
    ).toList();

    if (undocumented.isNotEmpty) {
      final trip = undocumented.first;
      return TravelAssistantAnswer(
        title: '${trip.destination} wartet auf eine Erinnerung',
        body: 'Diese vergangene Reise hat noch keine Notiz und keinen '
            'Album-Eintrag. Insgesamt sind ${snapshot.memoryCount} Erinnerungen '
            'und ${snapshot.photoCount} Fotos erfasst.',
        tripId: trip.id,
      );
    }

    return TravelAssistantAnswer(
      title: 'Deine Erinnerungen',
      body: '${snapshot.memoryCount} Album-Einträge, ${snapshot.highlightCount} '
          'Highlights und ${snapshot.photoCount} Fotos sind gespeichert.',
    );
  }

  TravelAssistantAnswer _countryAnswer(List<Trip> trips) {
    final counts = <String, int>{};
    final labels = <String, String>{};

    for (final trip in trips) {
      final label = trip.country.trim();
      if (label.isEmpty) {
        continue;
      }
      final key = label.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
      labels[key] = label;
    }

    if (counts.isEmpty) {
      return const TravelAssistantAnswer(
        title: 'Noch keine Länder gespeichert',
        body: 'Ergänze bei deinen Reisen das Land.',
      );
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).map((entry) {
      final suffix = entry.value == 1 ? 'Reise' : 'Reisen';
      return '${labels[entry.key]} (${entry.value} $suffix)';
    }).join(', ');

    return TravelAssistantAnswer(
      title: 'Deine häufigsten Reiseländer',
      body: top,
    );
  }

  TravelAssistantAnswer _summaryAnswer(TravelAssistantSnapshot snapshot) {
    return TravelAssistantAnswer(
      title: 'Deine Reiseübersicht',
      body: '${snapshot.tripCount} Reisen in ${snapshot.countryCount} Ländern · '
          '${snapshot.documentCount} Dokumente · ${snapshot.memoryCount} '
          'Erinnerungen · ${snapshot.photoCount} Fotos.',
    );
  }

  static bool _containsAny(String source, List<String> values) {
    return values.any(source.contains);
  }

  static String _dateRange(Trip trip) {
    return '${_formatDate(trip.startDate)} – ${_formatDate(trip.endDate)}';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
