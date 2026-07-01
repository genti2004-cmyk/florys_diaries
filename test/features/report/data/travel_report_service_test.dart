import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/report/data/travel_report_service.dart';
import 'package:florys_diaries/features/report/domain/travel_report_options.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

void main() {
  test('creates a readable PDF file in the provided directory', () async {
    final directory = await Directory.systemTemp.createTemp('florys-report-');
    addTearDown(() => directory.delete(recursive: true));
    final service = TravelReportService(
      directoryProvider: () async => directory,
    );
    final trip = Trip(
      id: 'trip-1',
      title: 'Rom Reise',
      destination: 'Rom',
      country: 'Italien',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 3),
    );

    final file = await service.createPdf(
      trip,
      options: const TravelReportOptions(
        includePlan: false,
        includeBudget: false,
        includeChecklist: false,
        includeDocuments: false,
        includeMoments: false,
        includePhotos: false,
        includeParticipants: false,
      ),
    );

    expect(await file.exists(), isTrue);
    final header = await file.openRead(0, 4).fold<List<int>>(
      <int>[],
      (bytes, chunk) => bytes..addAll(chunk),
    );
    expect(String.fromCharCodes(header), '%PDF');
  });
}
