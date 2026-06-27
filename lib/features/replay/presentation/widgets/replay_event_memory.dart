import 'package:flutter/material.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/replay/domain/replay_event.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_album_moment.dart';
import 'package:florys_diaries/features/replay/presentation/widgets/replay_document_moment.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class ReplayEventMemory extends StatelessWidget {
  const ReplayEventMemory({
    required this.trip,
    required this.event,
    super.key,
  });

  final Trip trip;
  final ReplayEvent event;

  @override
  Widget build(BuildContext context) {
    final document = _documentForEvent();
    if (document != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ReplayDocumentMoment(document: document),
      );
    }

    final albumEntry = _albumEntryForEvent();
    if (albumEntry != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ReplayAlbumMoment(entry: albumEntry),
      );
    }

    if (event.id == '${trip.id}_photos' && trip.photoCount > 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ReplayPhotoSummary(photoCount: trip.photoCount),
      );
    }

    return const SizedBox.shrink();
  }

  TravelDocument? _documentForEvent() {
    for (final document in trip.documents) {
      if (event.id == 'document_${document.id}') {
        return document;
      }
    }
    return null;
  }

  TripAlbumEntry? _albumEntryForEvent() {
    for (final entry in trip.albumEntries) {
      if (event.id == 'album_${entry.id}') {
        return entry;
      }
    }
    return null;
  }
}
