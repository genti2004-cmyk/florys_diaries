import 'package:latlong2/latlong.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/map/data/world_geo_lookup.dart';
import 'package:florys_diaries/features/replay/domain/replay_event.dart';
import 'package:florys_diaries/features/replay/domain/replay_geo_point.dart';
import 'package:florys_diaries/features/replay/domain/replay_timeline.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class ReplayBuilder {
  const ReplayBuilder();

  ReplayTimeline buildForTrip(Trip trip) {
    final destinationPosition = _knownPosition(
      country: trip.country,
      city: trip.destination,
    );

    final events = <ReplayEvent>[
      ReplayEvent(
        id: '${trip.id}_start',
        type: ReplayEventType.start,
        title: 'Reise gestartet',
        subtitle: trip.title,
        date: trip.startDate,
        location: trip.destination,
        description: trip.notes,
        badge: '${trip.durationDays} Tage',
      ),
      ReplayEvent(
        id: '${trip.id}_destination',
        type: ReplayEventType.destination,
        title: trip.destination,
        subtitle: trip.country,
        date: trip.startDate,
        location: trip.destination,
        description: 'Ziel deiner Reise: ${trip.destination}, ${trip.country}.',
        badge: 'Zielort',
        position: destinationPosition,
      ),
      ...trip.documents.map(_documentEvent),
      ...trip.albumEntries.map(
        (entry) => _albumEvent(entry, country: trip.country),
      ),
      if (trip.photoCount > 0)
        ReplayEvent(
          id: '${trip.id}_photos',
          type: ReplayEventType.photo,
          title: '${trip.photoCount} Fotos',
          subtitle: 'Fotomomente dieser Reise',
          date: trip.endDate,
          location: trip.destination,
          description: 'Gespeicherte Fotoanzahl für diese Reise.',
          badge: 'Fotos',
          position: destinationPosition,
        ),
      ReplayEvent(
        id: '${trip.id}_end',
        type: ReplayEventType.end,
        title: 'Reise abgeschlossen',
        subtitle: '${trip.destination}, ${trip.country}',
        date: trip.endDate,
        location: trip.destination,
        description:
            '${trip.durationDays} Reisetage, ${trip.documentCount} Dokumente, ${trip.highlightCount} Highlights.',
        badge: 'Rückblick',
        position: destinationPosition,
      ),
    ];

    return ReplayTimeline(events: events);
  }

  ReplayEvent _documentEvent(TravelDocument document) {
    return ReplayEvent(
      id: 'document_${document.id}',
      type: _isImageDocument(document)
          ? ReplayEventType.photo
          : ReplayEventType.document,
      title: document.title,
      subtitle: document.category.label,
      date: document.createdAt,
      description: document.description,
      badge: document.isFavorite
          ? 'Favorit · ${document.fileTypeLabel}'
          : document.fileTypeLabel,
    );
  }

  bool _isImageDocument(TravelDocument document) {
    final extension = document.fileExtension.toLowerCase().trim();
    return extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp';
  }

  ReplayEvent _albumEvent(TripAlbumEntry entry, {required String country}) {
    return ReplayEvent(
      id: 'album_${entry.id}',
      type: _typeForAlbumEntry(entry),
      title: entry.title,
      subtitle: TripAlbumEntryTypes.byId(entry.typeId).label,
      date: entry.date,
      location: entry.location,
      description: entry.description,
      badge: entry.isFavorite ? 'Favorit' : '',
      position: _knownPosition(country: country, city: entry.location),
    );
  }

  ReplayGeoPoint? _knownPosition({
    required String country,
    required String city,
  }) {
    if (country.trim().isEmpty || city.trim().isEmpty) {
      return null;
    }

    final position = knownCityPosition(country, city);
    return position == null ? null : _toReplayGeoPoint(position);
  }

  ReplayGeoPoint _toReplayGeoPoint(LatLng position) {
    return ReplayGeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  ReplayEventType _typeForAlbumEntry(TripAlbumEntry entry) {
    if (entry.typeId == TripAlbumEntryTypes.highlight.id) {
      return ReplayEventType.highlight;
    }
    if (entry.typeId == TripAlbumEntryTypes.place.id) {
      return ReplayEventType.place;
    }
    if (entry.typeId == TripAlbumEntryTypes.food.id) {
      return ReplayEventType.food;
    }
    if (entry.typeId == TripAlbumEntryTypes.memory.id) {
      return ReplayEventType.memory;
    }
    return ReplayEventType.note;
  }
}
