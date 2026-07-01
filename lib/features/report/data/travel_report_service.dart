import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:florys_diaries/features/budget/domain/trip_budget_expense.dart';
import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';
import 'package:florys_diaries/features/report/domain/travel_report_options.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

typedef ReportDirectoryProvider = Future<Directory> Function();

class TravelReportService {
  const TravelReportService({
    this.directoryProvider,
    this.fileService = const TravelFileService(),
  });

  final ReportDirectoryProvider? directoryProvider;
  final TravelFileService fileService;

  Future<File> createPdf(
    Trip trip, {
    TravelReportOptions options = const TravelReportOptions(),
  }) async {
    final reportPhotos = options.includePhotos
        ? await _loadReportPhotos(trip)
        : const <_ReportPhoto>[];
    final document = pw.Document(
      title: 'FlorysDiaries - ${trip.title}',
      author: 'FlorysDiaries',
      subject: 'Reisebericht ${trip.destination}',
    );
    final accent = PdfColor.fromHex('#2D5BDE');
    final soft = PdfColor.fromHex('#EEF3FF');
    final muted = PdfColor.fromHex('#667085');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
          italic: pw.Font.helveticaOblique(),
        ),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: soft, width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'FlorysDiaries',
                style: pw.TextStyle(
                  color: accent,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Reisebericht',
                style: pw.TextStyle(color: muted, fontSize: 10),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Seite ${context.pageNumber} von ${context.pagesCount}',
            style: pw.TextStyle(color: muted, fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(22),
            decoration: pw.BoxDecoration(
              color: accent,
              borderRadius: pw.BorderRadius.circular(18),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  trip.title,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 25,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '${trip.destination}, ${trip.country}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)} · ${trip.durationDays} ${trip.durationDays == 1 ? 'Tag' : 'Tage'}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Überblick', accent),
          _overviewTable(trip, soft),
          if (trip.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('Notizen', accent),
            pw.Text(trip.notes),
          ],
          if (options.includeParticipants && trip.participants.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Reiseteilnehmer', accent),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trip.participants
                  .map(
                    (participant) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: soft,
                        borderRadius: pw.BorderRadius.circular(99),
                      ),
                      child: pw.Text(participant.name),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (options.includePlan && trip.planItems.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Tagesplan', accent),
            ..._planWidgets(trip, options.detailed, soft),
          ],
          if (options.includeBudget &&
              (trip.budgetAmountCents > 0 || trip.budgetExpenses.isNotEmpty)) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Budget', accent),
            _budgetSummary(trip, soft),
            if (options.detailed && trip.budgetExpenses.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              _expenseTable(trip),
            ],
          ],
          if (options.includeChecklist && trip.checklistItems.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Checkliste', accent),
            ...trip.checklistItems.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.isCompleted ? '[x]' : '[ ]'),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: pw.Text(item.title)),
                  ],
                ),
              ),
            ),
          ],
          if (options.includeDocuments && trip.documents.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Dokumentenliste', accent),
            pw.Text(
              'Aus Datenschutzgründen werden nur Titel und Kategorien aufgeführt. Originaldateien werden nicht in das PDF eingebettet.',
              style: pw.TextStyle(color: muted, fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            ...trip.documents.map(
              (document) => pw.Bullet(
                text: '${document.title} · ${document.categoryId}',
              ),
            ),
          ],
          if (options.includePhotos && reportPhotos.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Reisefotos', accent),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: reportPhotos
                  .map(
                    (photo) => pw.Container(
                      width: 245,
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: soft,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.ClipRRect(
                            horizontalRadius: 7,
                            verticalRadius: 7,
                            child: pw.Image(
                              pw.MemoryImage(photo.bytes),
                              width: 233,
                              height: 145,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            photo.title,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (options.includeMoments && trip.albumEntries.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Momente', accent),
            ...trip.albumEntries.map(
              (entry) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: soft,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      entry.title.trim().isEmpty ? 'Moment' : entry.title,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${_formatDate(entry.date)}${entry.location.trim().isEmpty ? '' : ' · ${entry.location}'}',
                      style: pw.TextStyle(color: muted, fontSize: 9),
                    ),
                    if (options.detailed &&
                        entry.description.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 5),
                      pw.Text(entry.description),
                    ],
                  ],
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            'Erstellt mit FlorysDiaries am ${_formatDate(DateTime.now())}.',
            style: pw.TextStyle(color: muted, fontSize: 9),
          ),
        ],
      ),
    );

    final directory = directoryProvider == null
        ? await fileService.tripExportDirectory(trip.id)
        : await directoryProvider!();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = File(
      '${directory.path}/${_safeFileName(trip.title)}_Reisebericht.pdf',
    );
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  Future<List<_ReportPhoto>> _loadReportPhotos(Trip trip) async {
    final candidates = trip.documents.where(_isSupportedPhoto).toList(
      growable: true,
    )..sort((left, right) {
        if (left.isFavorite != right.isFavorite) {
          return left.isFavorite ? -1 : 1;
        }
        return right.createdAt.compareTo(left.createdAt);
      });
    final result = <_ReportPhoto>[];
    for (final document in candidates.take(4)) {
      try {
        final file = await fileService.resolveExistingDocumentFile(document);
        if (file == null || await file.length() > 12 * 1024 * 1024) {
          continue;
        }
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          continue;
        }
        result.add(
          _ReportPhoto(
            title: document.title.trim().isEmpty
                ? document.fileName
                : document.title.trim(),
            bytes: bytes,
          ),
        );
      } catch (_) {
        // Ein einzelnes nicht lesbares Foto verhindert den Bericht nicht.
      }
    }
    return List<_ReportPhoto>.unmodifiable(result);
  }

  static bool _isSupportedPhoto(TravelDocument document) {
    final extension = document.fileExtension.trim().toLowerCase();
    return document.hasFile &&
        const <String>{'jpg', 'jpeg', 'png'}.contains(extension);
  }

  static pw.Widget _sectionTitle(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _overviewTable(Trip trip, PdfColor soft) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            _metric('Programmpunkte', '${trip.planItemCount}', soft),
            _metric('Dokumente', '${trip.documentCount}', soft),
            _metric('Momente', '${trip.albumEntryCount}', soft),
          ],
        ),
      ],
    );
  }

  static pw.Widget _metric(String label, String value, PdfColor soft) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: soft,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static List<pw.Widget> _planWidgets(
    Trip trip,
    bool detailed,
    PdfColor soft,
  ) {
    final items = [...trip.planItems]
      ..sort((a, b) {
        final date = a.dateOnly.compareTo(b.dateOnly);
        return date != 0 ? date : a.sortValue.compareTo(b.sortValue);
      });
    DateTime? lastDate;
    final widgets = <pw.Widget>[];
    for (final item in items) {
      if (lastDate != item.dateOnly) {
        lastDate = item.dateOnly;
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 5),
            child: pw.Text(
              _formatDate(item.dateOnly),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        );
      }
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 5),
          padding: const pw.EdgeInsets.all(9),
          decoration: pw.BoxDecoration(
            color: soft,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${_formatTime(item.startMinutes)} · ${item.title}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              if (item.location.trim().isNotEmpty)
                pw.Text(item.location, style: const pw.TextStyle(fontSize: 9)),
              if (detailed && item.notes.trim().isNotEmpty)
                pw.Text(item.notes),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  static pw.Widget _budgetSummary(Trip trip, PdfColor soft) {
    final values = [
      ('Budget', TripMoney.format(trip.budgetAmountCents, trip.budgetCurrency)),
      ('Bezahlt', TripMoney.format(trip.paidExpenseCents, trip.budgetCurrency)),
      ('Geplant', TripMoney.format(trip.plannedExpenseCents, trip.budgetCurrency)),
      (
        'Voraussichtlich übrig',
        TripMoney.format(
          trip.forecastRemainingBudgetCents,
          trip.budgetCurrency,
        ),
      ),
    ];
    return pw.Wrap(
      spacing: 7,
      runSpacing: 7,
      children: values
          .map(
            (item) => pw.Container(
              width: 120,
              padding: const pw.EdgeInsets.all(9),
              decoration: pw.BoxDecoration(
                color: soft,
                borderRadius: pw.BorderRadius.circular(9),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(item.$1, style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    item.$2,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  static pw.Widget _expenseTable(Trip trip) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Datum', 'Ausgabe', 'Status', 'Betrag'],
      data: trip.budgetExpenses
          .map(
            (expense) => [
              _formatDate(expense.date),
              expense.title,
              expense.status.label,
              TripMoney.format(expense.amountCents, trip.budgetCurrency),
            ],
          )
          .toList(growable: false),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    );
  }

  static String _formatTime(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String _safeFileName(String value) {
    final safe = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9äöüÄÖÜß_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safe.isEmpty ? 'FlorysDiaries' : safe;
  }
}

class _ReportPhoto {
  const _ReportPhoto({required this.title, required this.bytes});

  final String title;
  final Uint8List bytes;
}
