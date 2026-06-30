import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/replay/data/replay_builder.dart';
import 'package:florys_diaries/features/replay/domain/replay_event.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  const builder = ReplayBuilder();

  test('replay starts with a map position for a known destination', () {
    final trip = Trip(
      id: 'berlin',
      title: 'Berlin',
      destination: 'Berlin',
      country: 'Deutschland',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 3),
    );

    final timeline = builder.buildForTrip(trip);

    expect(timeline.events.first.type, ReplayEventType.start);
    expect(timeline.events.first.hasPosition, isTrue);
    expect(
      timeline.events.where((event) => event.hasPosition),
      hasLength(timeline.events.length),
    );
  });

  test(
    'replay derives a stable position for an unlisted city in a known country',
    () {
      final trip = Trip(
        id: 'istog',
        title: 'Kosova',
        destination: 'Istog',
        country: 'Kosovo',
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 5),
        albumEntries: <TripAlbumEntry>[
          TripAlbumEntry(
            id: 'peja',
            typeId: TripAlbumEntryTypes.place.id,
            date: DateTime(2026, 7, 3),
            title: 'Ausflug',
            location: 'Peja',
          ),
        ],
      );

      final timeline = builder.buildForTrip(trip);
      final start = timeline.events.first;
      final album = timeline.events.firstWhere(
        (event) => event.id == 'album_peja',
      );

      expect(start.hasPosition, isTrue);
      expect(album.hasPosition, isTrue);
      expect(start.position!.isValid, isTrue);
      expect(album.position!.isValid, isTrue);
    },
  );

  test('replay does not invent a position for an unknown country', () {
    final trip = Trip(
      id: 'unknown',
      title: 'Unbekannt',
      destination: 'Musterstadt',
      country: 'Unbekanntes Land',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 2),
    );

    final timeline = builder.buildForTrip(trip);

    expect(timeline.events.every((event) => !event.hasPosition), isTrue);
  });
}
