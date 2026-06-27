import 'package:flutter/widgets.dart';

import 'trip_store.dart';

class TripStoreScope extends InheritedNotifier<TripStore> {
  const TripStoreScope({
    required TripStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static TripStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TripStoreScope>();
    assert(scope != null, 'TripStoreScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
