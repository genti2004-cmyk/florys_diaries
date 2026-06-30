import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:florys_diaries/core/constants/app_metadata.dart';

void main() {
  test('Android release and debug identities are separated', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/florysdiaries/app/MainActivity.kt',
    ).readAsStringSync();

    expect(gradle, contains('namespace = "${AppMetadata.releasePackageId}"'));
    expect(
      gradle,
      contains('applicationId = "${AppMetadata.releasePackageId}"'),
    );
    expect(gradle, isNot(contains('namespace = releaseApplicationId')));
    expect(gradle, contains('val releaseAppLabel = "${AppMetadata.name}"'));
    expect(
      gradle,
      contains('val debugAppLabel = "${AppMetadata.developmentName}"'),
    );
    expect(gradle, contains('applicationIdSuffix = ".debug"'));
    expect(AppMetadata.debugPackageId, '${AppMetadata.releasePackageId}.debug');
    expect(
      manifest,
      contains('android:name="${AppMetadata.releasePackageId}.MainActivity"'),
    );
    expect(activity, contains('package ${AppMetadata.releasePackageId}'));
  });

  test('iOS release and debug identities are separated', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(project, isNot(contains('com.example.florysDiaries')));
    expect(
      project,
      contains('PRODUCT_BUNDLE_IDENTIFIER = ${AppMetadata.releasePackageId};'),
    );
    expect(
      project,
      contains('PRODUCT_BUNDLE_IDENTIFIER = ${AppMetadata.debugPackageId};'),
    );
    expect(project, contains('APP_DISPLAY_NAME = "${AppMetadata.name}";'));
    expect(
      project,
      contains('APP_DISPLAY_NAME = "${AppMetadata.developmentName}";'),
    );
    expect(plist, contains(r'<string>$(APP_DISPLAY_NAME)</string>'));
    expect(plist, contains('<string>${AppMetadata.name}</string>'));
  });

  test('all map views use the central release identity', () {
    final worldMap = File(
      'lib/features/map/widgets/professional_world_map.dart',
    ).readAsStringSync();
    final replayMap = File(
      'lib/features/replay/presentation/widgets/replay_map_view.dart',
    ).readAsStringSync();

    expect(worldMap, contains('AppMetadata.mapUserAgentPackageName'));
    expect(replayMap, contains('AppMetadata.mapUserAgentPackageName'));
    expect(replayMap, isNot(contains('com.florysdiaries.travel')));
  });
}
