import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/search/data/search_history_service.dart';

void main() {
  late Directory directory;
  late SearchHistoryService service;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('florys-search-test-');
    service = SearchHistoryService(
      directoryProvider: () async => directory,
      maxItems: 3,
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('stores newest queries first and removes duplicates', () async {
    await service.add('Hotel');
    await service.add('Berlin');
    await service.add('hotel');

    expect(await service.load(), <String>['hotel', 'Berlin']);
  });

  test('limits history and clears it safely', () async {
    await service.add('eins');
    await service.add('zwei');
    await service.add('drei');
    await service.add('vier');

    expect(await service.load(), <String>['vier', 'drei', 'zwei']);

    await service.clear();
    expect(await service.load(), isEmpty);
  });
}
