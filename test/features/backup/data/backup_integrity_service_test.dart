import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/backup/data/backup_integrity_service.dart';

void main() {
  const service = BackupIntegrityService();
  late Directory testRoot;

  setUp(() async {
    testRoot = await Directory.systemTemp.createTemp(
      'florys_backup_integrity_test_',
    );
    addTearDown(() async {
      if (await testRoot.exists()) {
        await testRoot.delete(recursive: true);
      }
    });
  });

  test('calculates deterministic SHA-256 hashes for bytes and files', () async {
    final file = File('${testRoot.path}${Platform.pathSeparator}data.bin');
    await file.writeAsBytes([1, 2, 3, 4], flush: true);

    final bytesHash = service.hashBytes([1, 2, 3, 4]);
    final fileHash = await service.hashFile(file);

    expect(bytesHash, fileHash);
    expect(bytesHash, matches(BackupIntegrityService.sha256Pattern));
  });

  test('hashes directory contents with stable relative paths', () async {
    final nested = File(
      [testRoot.path, 'Reisen', 'trip-1', 'ticket.pdf'].join(
        Platform.pathSeparator,
      ),
    );
    await nested.parent.create(recursive: true);
    await nested.writeAsBytes([4, 3, 2, 1], flush: true);

    final hashes = await service.hashDirectory(testRoot);

    expect(hashes.keys, ['Reisen/trip-1/ticket.pdf']);
    expect(
      hashes.values.single,
      matches(BackupIntegrityService.sha256Pattern),
    );
  });

  test('rejects malformed SHA-256 values', () {
    expect(
      () => BackupIntegrityService.normalizeSha256(
        'kein-hash',
        label: 'Testwert',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
