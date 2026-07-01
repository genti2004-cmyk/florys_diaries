import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/features/documents/data/travel_document_path_policy.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';

void main() {
  late Directory testRoot;
  late Directory managedRoot;
  late TravelFileService service;

  setUp(() async {
    testRoot = await Directory.systemTemp.createTemp(
      'florys_travel_file_test_',
    );
    managedRoot = Directory(
      '${testRoot.path}${Platform.pathSeparator}FlorysDiaries',
    );
    await managedRoot.create(recursive: true);

    service = TravelFileService(
      now: () => DateTime(2026, 6, 29, 12),
      rootDirectoryProvider: () async => managedRoot,
    );

    addTearDown(() async {
      if (await testRoot.exists()) {
        await testRoot.delete(recursive: true);
      }
    });
  });

  test('sanitizes imported ids before creating a managed file', () async {
    final source = File(
      '${testRoot.path}${Platform.pathSeparator}mein ticket.pdf',
    );
    await source.writeAsBytes([1, 2, 3, 4], flush: true);

    final result = await service.copyFileToTrip(
      tripId: 'trip-1',
      sourcePath: source.path,
      documentId: '../document/1',
    );

    expect(
      TravelDocumentPathPolicy.isDocumentPathForTrip(
        result.relativePath,
        'trip-1',
      ),
      isTrue,
    );
    expect(result.relativePath, isNot(contains('..')));
    expect(result.relativePath, isNot(contains(r'\')));
    expect(result.fileSizeBytes, 4);

    final copied = File(
      [
        managedRoot.path,
        ...result.relativePath.split('/'),
      ].join(Platform.pathSeparator),
    );
    expect(await copied.exists(), isTrue);
  });

  test('does not resolve or delete a path outside the managed root', () async {
    final outside = File(
      '${testRoot.path}${Platform.pathSeparator}outside.txt',
    );
    await outside.writeAsString('nicht löschen', flush: true);

    final document = _document(relativePath: '../outside.txt');

    expect(await service.resolveDocumentFile(document), isNull);
    await expectLater(
      service.deleteDocumentFile(document),
      throwsA(isA<FileSystemException>()),
    );
    expect(await outside.readAsString(), 'nicht löschen');
  });

  test('resolves and deletes a valid managed document file', () async {
    const relativePath = 'Reisen/trip-1/documents/ticket.pdf';
    final file = File(
      [
        managedRoot.path,
        ...relativePath.split('/'),
      ].join(Platform.pathSeparator),
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes([1, 2, 3], flush: true);

    final document = _document(relativePath: relativePath);
    final resolved = await service.resolveDocumentFile(document);
    final existing = await service.resolveExistingDocumentFile(document);

    expect(resolved?.path, file.path);
    expect(existing?.path, file.path);
    expect(await service.documentFileExists(document), isTrue);

    await service.deleteDocumentFile(document);
    expect(await file.exists(), isFalse);
    expect(await service.resolveExistingDocumentFile(document), isNull);
  });
}

TravelDocument _document({required String relativePath}) {
  return TravelDocument(
    id: 'document-1',
    title: 'Ticket',
    categoryId: 'other',
    createdAt: DateTime(2026, 6, 29),
    fileName: 'ticket.pdf',
    relativePath: relativePath,
    fileSizeBytes: 3,
    fileExtension: 'pdf',
  );
}
