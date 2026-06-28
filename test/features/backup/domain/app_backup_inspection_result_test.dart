import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/backup/domain/app_backup_result.dart';
import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  test('erstellt eine vollständige Inhaltsübersicht aus Reisen', () {
    final inspection = AppBackupInspectionResult.fromTrips(
      backupCreatedAt: DateTime.utc(2026, 6, 28, 12),
      trips: [
        Trip(
          id: 'one',
          title: 'Berlin',
          destination: 'Berlin',
          country: 'Deutschland',
          startDate: DateTime(2025, 1, 5),
          endDate: DateTime(2025, 1, 8),
          documents: [
            TravelDocument(
              id: 'document-1',
              title: 'Ticket',
              categoryId: DocumentCategories.flight.id,
              createdAt: DateTime(2025, 1, 2),
              fileName: 'ticket.pdf',
              relativePath: 'documents/ticket.pdf',
              fileSizeBytes: 2048,
              fileExtension: 'pdf',
            ),
          ],
          albumEntries: [
            TripAlbumEntry(
              id: 'album-1',
              typeId: TripAlbumEntryTypes.highlight.id,
              date: DateTime(2025, 1, 6),
              title: 'Brandenburger Tor',
              location: 'Berlin',
            ),
          ],
          checklistItems: [
            TripChecklistItem(
              id: 'check-1',
              title: 'Koffer packen',
              category: TripChecklistCategory.luggage,
              priority: TripChecklistPriority.high,
              createdAt: DateTime(2025, 1, 1),
            ),
          ],
        ),
        Trip(
          id: 'two',
          title: 'Rom',
          destination: 'Rom',
          country: 'Italien',
          startDate: DateTime(2026, 8, 10),
          endDate: DateTime(2026, 8, 20),
        ),
        Trip(
          id: 'three',
          title: 'Berlin erneut',
          destination: ' berlin ',
          country: ' deutschland ',
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2026, 9, 2),
        ),
      ],
      fileCount: 2,
      sizeBytes: 4096,
      appVersion: '0.19.0',
    );

    expect(inspection.tripCount, 3);
    expect(inspection.countryCount, 2);
    expect(inspection.destinationCount, 2);
    expect(inspection.documentCount, 1);
    expect(inspection.albumEntryCount, 1);
    expect(inspection.checklistItemCount, 1);
    expect(inspection.firstTripStartAt, DateTime(2025, 1, 5));
    expect(inspection.lastTripEndAt, DateTime(2026, 9, 2));
    expect(inspection.appVersion, '0.19.0');
    expect(inspection.hasTravelPeriod, isTrue);
  });

  test('leeres Backup besitzt keinen Reisezeitraum', () {
    final inspection = AppBackupInspectionResult.fromTrips(
      backupCreatedAt: DateTime.utc(2026, 6, 28),
      trips: const [],
      fileCount: 0,
      sizeBytes: 300,
      appVersion: '',
    );

    expect(inspection.tripCount, 0);
    expect(inspection.hasTravelPeriod, isFalse);
    expect(inspection.firstTripStartAt, isNull);
    expect(inspection.lastTripEndAt, isNull);
    expect(inspection.appVersion, 'Unbekannt');
  });
}
