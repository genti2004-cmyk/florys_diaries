class AppMetadata {
  const AppMetadata._();

  static const String name = 'FlorysDiaries';
  static const String developmentName = 'FlorysDiaries DEV';

  static const String releasePackageId = 'com.florysdiaries.app';
  static const String debugPackageId = 'com.florysdiaries.app.debug';

  static const String version = '1.0.0';
  static const int buildNumber = 7;
  static const String displayVersion = 'v$version';
  static const String fullVersion = '$version+$buildNumber';

  // Interner Entwicklungsstand. Dieser Wert ist bewusst von der späteren
  // Store-Version getrennt, damit Git-Meilensteine und Release-Version nicht
  // miteinander verwechselt werden.
  static const String developmentMilestone = 'v2.5.0-dev';
  static const String releaseDisplayVersion =
      '$displayVersion (Build $buildNumber)';

  // flutter_map erwartet eine stabile Paketkennung als User-Agent.
  static const String mapUserAgentPackageName = releasePackageId;
}
