import 'package:florys_diaries/features/documents/domain/travel_document.dart';

enum DocumentSortMode { newest, oldest, title, category }

class TripDocumentQuery {
  const TripDocumentQuery({
    this.searchText = '',
    this.categoryId = allCategoriesId,
    this.sortMode = DocumentSortMode.newest,
    this.favoritesOnly = false,
  });

  static const String allCategoriesId = 'all';

  final String searchText;
  final String categoryId;
  final DocumentSortMode sortMode;
  final bool favoritesOnly;

  List<TravelDocument> apply(List<TravelDocument> documents) {
    final normalizedQuery = searchText.trim().toLowerCase();
    final filtered = documents
        .where((document) {
          if (favoritesOnly && !document.isFavorite) {
            return false;
          }
          if (categoryId != allCategoriesId &&
              document.categoryId != categoryId) {
            return false;
          }

          if (normalizedQuery.isEmpty) {
            return true;
          }

          final searchableText = <String>[
            document.title,
            document.category.label,
            document.fileName,
            document.fileExtension,
            document.description,
          ].join(' ').toLowerCase();
          return searchableText.contains(normalizedQuery);
        })
        .toList(growable: false);

    final sorted = List<TravelDocument>.from(filtered)
      ..sort((left, right) {
        return switch (sortMode) {
          DocumentSortMode.newest => right.createdAt.compareTo(left.createdAt),
          DocumentSortMode.oldest => left.createdAt.compareTo(right.createdAt),
          DocumentSortMode.title => left.title.toLowerCase().compareTo(
            right.title.toLowerCase(),
          ),
          DocumentSortMode.category =>
            left.category.label.toLowerCase().compareTo(
              right.category.label.toLowerCase(),
            ),
        };
      });

    return List<TravelDocument>.unmodifiable(sorted);
  }

  TripDocumentQuery copyWith({
    String? searchText,
    String? categoryId,
    DocumentSortMode? sortMode,
    bool? favoritesOnly,
  }) {
    return TripDocumentQuery(
      searchText: searchText ?? this.searchText,
      categoryId: categoryId ?? this.categoryId,
      sortMode: sortMode ?? this.sortMode,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }

  bool hasSameValues(TripDocumentQuery other) {
    return searchText == other.searchText &&
        categoryId == other.categoryId &&
        sortMode == other.sortMode &&
        favoritesOnly == other.favoritesOnly;
  }
}
