import 'package:florys_diaries/features/assistant/domain/travel_assistant_models.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TravelAssistantAnswerService {
  const TravelAssistantAnswerService();

  TravelAssistantAnswer answer({
    required String question,
    required List<Trip> trips,
    required TravelAssistantSnapshot snapshot,
    DateTime? now,
  }) {
    final query = question.trim().toLowerCase();
    final today = _dateOnly(now ?? DateTime.now());

    if (query.isEmpty) {
      return const TravelAssistantAnswer(
        title: 'Stelle eine Frage',
        body:
            'Zum Beispiel: „Was steht als Nächstes an?“ oder '
            '„Wo fehlen Dokumente?“',
      );
    }

    if (_containsAny(query, const [
      'dokument',
      'ticket',
      'unterlage',
      'datei',
    ])) {
      return _documentAnswer(trips, today);
    }
    if (_containsAny(query, const [
      'highlight',
      'lieblingsmoment',
      'favorit',
    ])) {
      return _highlightAnswer(trips, snapshot);
    }
    if (_containsAny(query, const ['foto', 'erinner', 'album', 'notiz'])) {
      return _memoryAnswer(trips, snapshot, today);
    }
    if (_containsAny(query, const ['nächste', 'naechste', 'als nächstes'])) {
      return _nextTripAnswer(snapshot.nextTrip, today);
    }
    if (_containsAny(query, const [
      'land',
      'länder',
      'laender',
      'ziel',
      'wo war',
    ])) {
      return _countryAnswer(trips);
    }
    if (_containsAny(query, const [
      'übersicht',
      'uebersicht',
      'statistik',
      'zusammenfassung',
    ])) {
      return _summaryAnswer(snapshot);
    }
    if (query.contains('wann')) {
      return _nextTripAnswer(snapshot.nextTrip, today);
    }

    if (snapshot.tripCount == 0) {
      return const TravelAssistantAnswer(
        title: 'Noch keine Reisedaten',
        body:
            'Lege zuerst eine Reise an. Danach kann der Assistent Dokumente, '
            'Erinnerungen und Reiseziele auswerten.',
      );
    }

    return TravelAssistantAnswer(
      title: 'Lokale Reiseanalyse',
      body:
          'Ich habe ${snapshot.tripCount} Reisen durchsucht. Frage nach der '
          'nächsten Reise, fehlenden Dokumenten, Erinnerungen, Highlights oder '
          'bereisten Ländern.',
    );
  }

  TravelAssistantAnswer _nextTripAnswer(Trip? trip, DateTime today) {
    if (trip == null) {
      return const TravelAssistantAnswer(
        title: 'Keine kommende Reise',
        body: 'Aktuell ist keine zukünftige oder laufende Reise gespeichert.',
      );
    }

    final days = _dateOnly(trip.startDate).difference(today).inDays;
    final timing = days < 0
        ? 'Die Reise läuft bereits.'
        : days == 0
        ? 'Die Reise beginnt heute.'
        : days == 1
        ? 'Die Reise beginnt morgen.'
        : 'Die Reise beginnt in $days Tagen.';

    return TravelAssistantAnswer(
      title: _tripHeading(trip),
      body:
          '$timing ${_dateRange(trip)} · '
          '${_countLabel(trip.durationDays, 'Reisetag', 'Reisetage')} · '
          '${_countLabel(trip.documentCount, 'Dokument', 'Dokumente')}.',
      tripId: trip.id,
    );
  }

  TravelAssistantAnswer _documentAnswer(List<Trip> trips, DateTime today) {
    if (trips.isEmpty) {
      return const TravelAssistantAnswer(
        title: 'Noch keine Reisedaten',
        body:
            'Lege zuerst eine Reise an, damit Unterlagen geprüft werden '
            'können.',
      );
    }

    final issueTrips = <Trip>[];
    var emptyUpcoming = 0;
    var withoutFile = 0;
    var total = 0;

    for (final trip in trips) {
      total += trip.documentCount;
      final missingFiles = trip.documents
          .where((document) => !document.hasFile)
          .length;
      withoutFile += missingFiles;

      if (!_isPast(trip, today) && trip.documents.isEmpty) {
        emptyUpcoming += 1;
        issueTrips.add(trip);
      } else if (missingFiles > 0) {
        issueTrips.add(trip);
      }
    }

    if (total == 0) {
      final upcomingText = emptyUpcoming == 0
          ? 'Hinterlege Tickets, Buchungen oder Reisedokumente in deinen Reisen.'
          : emptyUpcoming == 1
          ? 'Eine kommende Reise hat noch keine Dokumente.'
          : '$emptyUpcoming kommende Reisen haben noch keine Dokumente.';
      return TravelAssistantAnswer(
        title: 'Noch keine Dokumente gespeichert',
        body: upcomingText,
        tripId: issueTrips.isEmpty ? null : issueTrips.first.id,
      );
    }

    if (emptyUpcoming == 0 && withoutFile == 0) {
      return TravelAssistantAnswer(
        title: 'Dokumente sehen gut aus',
        body:
            '${_countLabel(total, 'Dokument ist', 'Dokumente sind')} erfasst '
            'und alle Einträge haben eine gespeicherte Datei.',
      );
    }

    final affected = issueTrips
        .map(_tripLabel)
        .where((label) => label.isNotEmpty)
        .toSet()
        .take(3)
        .join(', ');
    final details = <String>[
      if (emptyUpcoming > 0)
        emptyUpcoming == 1
            ? 'Eine kommende Reise hat noch keine Dokumente.'
            : '$emptyUpcoming kommende Reisen haben noch keine Dokumente.',
      if (withoutFile > 0)
        withoutFile == 1
            ? 'Ein Dokumenteintrag hat noch keine Datei.'
            : '$withoutFile Dokumenteinträge haben noch keine Datei.',
      if (affected.isNotEmpty) 'Betroffen: $affected.',
    ].join(' ');

    return TravelAssistantAnswer(
      title: 'Unterlagen prüfen',
      body: details,
      tripId: issueTrips.isEmpty ? null : issueTrips.first.id,
    );
  }

  TravelAssistantAnswer _highlightAnswer(
    List<Trip> trips,
    TravelAssistantSnapshot snapshot,
  ) {
    final highlights =
        trips
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
        body:
            'Markiere im Reisealbum einen Eintrag als Highlight oder Favorit.',
      );
    }

    final latest = highlights.first;
    final entryTitle = latest.entry.title.trim().isEmpty
        ? 'Lieblingsmoment'
        : latest.entry.title.trim();
    return TravelAssistantAnswer(
      title: entryTitle,
      body:
          '${_tripLabel(latest.trip)} · '
          '${_formatDate(latest.entry.date)}. Insgesamt sind '
          '${_countLabel(snapshot.highlightCount, 'Lieblingsmoment', 'Lieblingsmomente')} '
          'gespeichert.',
      tripId: latest.trip.id,
    );
  }

  TravelAssistantAnswer _memoryAnswer(
    List<Trip> trips,
    TravelAssistantSnapshot snapshot,
    DateTime today,
  ) {
    final undocumented =
        trips
            .where(
              (trip) =>
                  _isPast(trip, today) &&
                  trip.albumEntries.isEmpty &&
                  trip.notes.trim().isEmpty,
            )
            .toList()
          ..sort((a, b) => b.endDate.compareTo(a.endDate));

    if (undocumented.isNotEmpty) {
      final trip = undocumented.first;
      return TravelAssistantAnswer(
        title: '${_tripLabel(trip)} wartet auf eine Erinnerung',
        body:
            'Diese vergangene Reise hat noch keine Notiz und keinen '
            'Album-Eintrag. Insgesamt sind '
            '${_countLabel(snapshot.memoryCount, 'Erinnerung', 'Erinnerungen')} '
            'und ${_countLabel(snapshot.photoCount, 'Foto', 'Fotos')} erfasst.',
        tripId: trip.id,
      );
    }

    return TravelAssistantAnswer(
      title: 'Deine Erinnerungen',
      body:
          '${_countLabel(snapshot.memoryCount, 'Album-Eintrag', 'Album-Einträge')}, '
          '${_countLabel(snapshot.highlightCount, 'Lieblingsmoment', 'Lieblingsmomente')} '
          'und ${_countLabel(snapshot.photoCount, 'Foto', 'Fotos')} sind '
          'gespeichert.',
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
      ..sort((a, b) {
        final countComparison = b.value.compareTo(a.value);
        if (countComparison != 0) {
          return countComparison;
        }
        return (labels[a.key] ?? a.key).compareTo(labels[b.key] ?? b.key);
      });
    final top = sorted
        .take(3)
        .map((entry) {
          return '${labels[entry.key]} '
              '(${_countLabel(entry.value, 'Reise', 'Reisen')})';
        })
        .join(', ');

    return TravelAssistantAnswer(
      title: 'Deine häufigsten Reiseländer',
      body: top,
    );
  }

  TravelAssistantAnswer _summaryAnswer(TravelAssistantSnapshot snapshot) {
    return TravelAssistantAnswer(
      title: 'Deine Reiseübersicht',
      body:
          '${_countLabel(snapshot.tripCount, 'Reise', 'Reisen')} in '
          '${_countLabel(snapshot.countryCount, 'Land', 'Ländern')} · '
          '${_countLabel(snapshot.documentCount, 'Dokument', 'Dokumente')} · '
          '${_countLabel(snapshot.memoryCount, 'Erinnerung', 'Erinnerungen')} · '
          '${_countLabel(snapshot.photoCount, 'Foto', 'Fotos')}.',
    );
  }

  static bool _containsAny(String source, List<String> values) {
    return values.any(source.contains);
  }

  static String _tripHeading(Trip trip) {
    final destination = trip.destination.trim();
    final country = trip.country.trim();
    if (destination.isNotEmpty && country.isNotEmpty) {
      return '$destination, $country';
    }
    if (destination.isNotEmpty) {
      return destination;
    }
    if (country.isNotEmpty) {
      return country;
    }
    final title = trip.title.trim();
    return title.isEmpty ? 'Nächste Reise' : title;
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

  static String _countLabel(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  static String _dateRange(Trip trip) {
    return '${_formatDate(trip.startDate)} – ${_formatDate(trip.endDate)}';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static bool _isPast(Trip trip, DateTime today) {
    return _dateOnly(trip.endDate).isBefore(today);
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
