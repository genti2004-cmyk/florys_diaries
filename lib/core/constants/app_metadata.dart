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

  // flutter_map erwartet eine stabile Paketkennung als User-Agent.
  static const String mapUserAgentPackageName = releasePackageId;
}
