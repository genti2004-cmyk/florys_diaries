class TravelReportOptions {
  const TravelReportOptions({
    this.detailed = true,
    this.includePlan = true,
    this.includeBudget = true,
    this.includeChecklist = true,
    this.includeDocuments = true,
    this.includeMoments = true,
    this.includePhotos = true,
    this.includeParticipants = true,
  });

  final bool detailed;
  final bool includePlan;
  final bool includeBudget;
  final bool includeChecklist;
  final bool includeDocuments;
  final bool includeMoments;
  final bool includePhotos;
  final bool includeParticipants;

  TravelReportOptions copyWith({
    bool? detailed,
    bool? includePlan,
    bool? includeBudget,
    bool? includeChecklist,
    bool? includeDocuments,
    bool? includeMoments,
    bool? includePhotos,
    bool? includeParticipants,
  }) {
    return TravelReportOptions(
      detailed: detailed ?? this.detailed,
      includePlan: includePlan ?? this.includePlan,
      includeBudget: includeBudget ?? this.includeBudget,
      includeChecklist: includeChecklist ?? this.includeChecklist,
      includeDocuments: includeDocuments ?? this.includeDocuments,
      includeMoments: includeMoments ?? this.includeMoments,
      includePhotos: includePhotos ?? this.includePhotos,
      includeParticipants: includeParticipants ?? this.includeParticipants,
    );
  }
}
