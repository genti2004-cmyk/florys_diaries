enum ReleaseCheckState { ready, attention, blocked }

class ReleaseQualityCheck {
  const ReleaseQualityCheck({
    required this.id,
    required this.title,
    required this.detail,
    required this.state,
  });

  final String id;
  final String title;
  final String detail;
  final ReleaseCheckState state;
}

class ReleaseQualityReport {
  const ReleaseQualityReport({
    required this.generatedAt,
    required this.isReleaseBuild,
    required this.tripCount,
    required this.documentCount,
    required this.momentCount,
    required this.planItemCount,
    required this.expenseCount,
    required this.participantCount,
    required this.checks,
  });

  final DateTime generatedAt;
  final bool isReleaseBuild;
  final int tripCount;
  final int documentCount;
  final int momentCount;
  final int planItemCount;
  final int expenseCount;
  final int participantCount;
  final List<ReleaseQualityCheck> checks;

  int get blockedCount {
    return checks
        .where((check) => check.state == ReleaseCheckState.blocked)
        .length;
  }

  int get attentionCount {
    return checks
        .where((check) => check.state == ReleaseCheckState.attention)
        .length;
  }

  int get readyCount {
    return checks
        .where((check) => check.state == ReleaseCheckState.ready)
        .length;
  }

  ReleaseCheckState get state {
    if (blockedCount > 0) {
      return ReleaseCheckState.blocked;
    }
    if (attentionCount > 0) {
      return ReleaseCheckState.attention;
    }
    return ReleaseCheckState.ready;
  }

  String get statusTitle {
    return switch (state) {
      ReleaseCheckState.ready => 'Bereit für den Release-Test',
      ReleaseCheckState.attention => 'Prüfung vor Release nötig',
      ReleaseCheckState.blocked => 'Release derzeit blockiert',
    };
  }

  String toPlainText({
    required String appName,
    required String releaseVersion,
    required String developmentMilestone,
    required String packageId,
  }) {
    final buffer = StringBuffer()
      ..writeln('$appName – Release- und Qualitätsbericht')
      ..writeln('Release-Version: $releaseVersion')
      ..writeln('Entwicklungsstand: $developmentMilestone')
      ..writeln('Paketkennung: $packageId')
      ..writeln('Buildmodus: ${isReleaseBuild ? 'Release' : 'Debug/Profile'}')
      ..writeln('Erstellt: ${generatedAt.toIso8601String()}')
      ..writeln()
      ..writeln('Datenbestand:')
      ..writeln('- Reisen: $tripCount')
      ..writeln('- Dokumente: $documentCount')
      ..writeln('- Momente: $momentCount')
      ..writeln('- Programmpunkte: $planItemCount')
      ..writeln('- Ausgaben: $expenseCount')
      ..writeln('- Teilnehmer: $participantCount')
      ..writeln()
      ..writeln('Prüfungen:');

    for (final check in checks) {
      final marker = switch (check.state) {
        ReleaseCheckState.ready => 'OK',
        ReleaseCheckState.attention => 'PRÜFEN',
        ReleaseCheckState.blocked => 'BLOCKIERT',
      };
      buffer.writeln('- [$marker] ${check.title}: ${check.detail}');
    }

    return buffer.toString().trimRight();
  }
}
