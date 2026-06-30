import 'package:florys_diaries/features/checklist/domain/trip_checklist_item.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripChecklistSuggestion {
  const TripChecklistSuggestion({
    required this.sourceKey,
    required this.title,
    required this.category,
    required this.priority,
    required this.dueDate,
    this.notes = '',
  });

  final String sourceKey;
  final String title;
  final TripChecklistCategory category;
  final TripChecklistPriority priority;
  final DateTime dueDate;
  final String notes;

  TripChecklistItem toItem(String id) {
    return TripChecklistItem(
      id: id,
      title: title,
      category: category,
      priority: priority,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      notes: notes,
      sourceKey: sourceKey,
    );
  }
}

class TravelChecklistSuggestionService {
  const TravelChecklistSuggestionService();

  List<TripChecklistSuggestion> suggestionsFor(Trip trip) {
    if (trip.isPast) {
      return const [];
    }

    final existingKeys = trip.checklistItems
        .map((item) => item.sourceKey)
        .whereType<String>()
        .toSet();
    final categoryIds = trip.documents
        .map((document) => document.categoryId)
        .toSet();
    final suggestions = <TripChecklistSuggestion>[];

    void add(TripChecklistSuggestion suggestion) {
      if (!existingKeys.contains(suggestion.sourceKey)) {
        suggestions.add(suggestion);
      }
    }

    if (!categoryIds.contains(DocumentCategories.passport.id)) {
      add(
        TripChecklistSuggestion(
          sourceKey: 'assistant-passport',
          title: 'Ausweis oder Reisepass prüfen',
          category: TripChecklistCategory.documents,
          priority: TripChecklistPriority.high,
          dueDate: _beforeStart(trip, 14),
          notes:
              'Gültigkeit prüfen und bei Bedarf eine Kopie im Dokumentenbereich sichern.',
        ),
      );
    }

    if (!categoryIds.contains(DocumentCategories.hotel.id)) {
      add(
        TripChecklistSuggestion(
          sourceKey: 'assistant-accommodation',
          title: 'Unterkunft bestätigen',
          category: TripChecklistCategory.bookings,
          priority: TripChecklistPriority.high,
          dueDate: _beforeStart(trip, 7),
          notes:
              'Adresse, Check-in-Zeit und Buchungsbestätigung kontrollieren.',
        ),
      );
    }

    final hasTransport =
        categoryIds.contains(DocumentCategories.flight.id) ||
        categoryIds.contains(DocumentCategories.train.id) ||
        categoryIds.contains(DocumentCategories.car.id);
    if (!hasTransport) {
      add(
        TripChecklistSuggestion(
          sourceKey: 'assistant-transport',
          title: 'Anreise und Tickets prüfen',
          category: TripChecklistCategory.bookings,
          priority: TripChecklistPriority.high,
          dueDate: _beforeStart(trip, 7),
          notes:
              'Abfahrtszeiten, Buchungsnummern und Gepäckregeln kontrollieren.',
        ),
      );
    }

    final documentsWithoutFile = trip.documents
        .where((document) => !document.hasFile)
        .length;
    if (documentsWithoutFile > 0) {
      add(
        TripChecklistSuggestion(
          sourceKey: 'assistant-missing-files',
          title: 'Fehlende Dokumentdateien ergänzen',
          category: TripChecklistCategory.documents,
          priority: TripChecklistPriority.medium,
          dueDate: _beforeStart(trip, 3),
          notes: documentsWithoutFile == 1
              ? 'Ein Dokumenteintrag hat noch keine Datei.'
              : '$documentsWithoutFile Dokumenteinträge haben noch keine Datei.',
        ),
      );
    }

    if (!trip.checklistItems.any(
      (item) => item.category == TripChecklistCategory.luggage,
    )) {
      add(
        TripChecklistSuggestion(
          sourceKey: 'assistant-luggage',
          title: 'Gepäck vorbereiten',
          category: TripChecklistCategory.luggage,
          priority: TripChecklistPriority.medium,
          dueDate: _beforeStart(trip, 2),
          notes: 'Kleidung, Ladegeräte und persönliche Dinge abhaken.',
        ),
      );
    }

    if (!trip.checklistItems.any(
      (item) => item.category == TripChecklistCategory.health,
    )) {
      add(
        TripChecklistSuggestion(
          sourceKey: 'assistant-health',
          title: 'Reiseapotheke und Medikamente prüfen',
          category: TripChecklistCategory.health,
          priority: TripChecklistPriority.medium,
          dueDate: _beforeStart(trip, 5),
          notes:
              'Regelmäßige Medikamente und wichtige Gesundheitsunterlagen vorbereiten.',
        ),
      );
    }

    if (trip.notes.trim().isEmpty) {
      add(
        TripChecklistSuggestion(
          sourceKey: 'assistant-contacts',
          title: 'Wichtige Adressen und Kontakte notieren',
          category: TripChecklistCategory.other,
          priority: TripChecklistPriority.low,
          dueDate: _beforeStart(trip, 3),
          notes:
              'Unterkunft, Treffpunkte und Notfallkontakte an einem Ort sammeln.',
        ),
      );
    }

    return suggestions;
  }

  static DateTime _beforeStart(Trip trip, int days) {
    return DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    ).subtract(Duration(days: days));
  }
}
