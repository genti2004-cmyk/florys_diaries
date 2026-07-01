import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/report/domain/travel_report_options.dart';

void main() {
  test('copyWith changes only selected report sections', () {
    const options = TravelReportOptions();
    final compact = options.copyWith(
      detailed: false,
      includePhotos: false,
      includeBudget: false,
    );

    expect(compact.detailed, isFalse);
    expect(compact.includePhotos, isFalse);
    expect(compact.includeBudget, isFalse);
    expect(compact.includePlan, isTrue);
    expect(compact.includeDocuments, isTrue);
  });
}
