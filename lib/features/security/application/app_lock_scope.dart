import 'package:flutter/widgets.dart';

import 'package:florys_diaries/features/security/application/app_lock_controller.dart';

class AppLockScope extends InheritedNotifier<AppLockController> {
  const AppLockScope({
    required AppLockController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppLockController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLockScope>();
    assert(scope != null, 'AppLockScope fehlt im Widget-Baum.');
    return scope!.notifier!;
  }

  static AppLockController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppLockScope>()
        ?.notifier;
  }
}
