enum GlobalSearchResultType {
  trip,
  planItem,
  document,
  memory,
  expense,
  reminder,
  place,
}

extension GlobalSearchResultTypeX on GlobalSearchResultType {
  String get label {
    return switch (this) {
      GlobalSearchResultType.trip => 'Reisen',
      GlobalSearchResultType.planItem => 'Planung',
      GlobalSearchResultType.document => 'Dokumente',
      GlobalSearchResultType.memory => 'Momente',
      GlobalSearchResultType.expense => 'Ausgaben',
      GlobalSearchResultType.reminder => 'Erinnerungen',
      GlobalSearchResultType.place => 'Orte',
    };
  }

  String get singularLabel {
    return switch (this) {
      GlobalSearchResultType.trip => 'Reise',
      GlobalSearchResultType.planItem => 'Programmpunkt',
      GlobalSearchResultType.document => 'Dokument',
      GlobalSearchResultType.memory => 'Moment',
      GlobalSearchResultType.expense => 'Ausgabe',
      GlobalSearchResultType.reminder => 'Erinnerung',
      GlobalSearchResultType.place => 'Ort',
    };
  }
}

enum GlobalSearchTarget { overview, planning, documents, memories }

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.id,
    required this.type,
    required this.target,
    required this.tripId,
    required this.tripTitle,
    required this.title,
    required this.subtitle,
    required this.searchableText,
    required this.date,
  });

  final String id;
  final GlobalSearchResultType type;
  final GlobalSearchTarget target;
  final String tripId;
  final String tripTitle;
  final String title;
  final String subtitle;
  final String searchableText;
  final DateTime date;

  int get year => date.year;
}
