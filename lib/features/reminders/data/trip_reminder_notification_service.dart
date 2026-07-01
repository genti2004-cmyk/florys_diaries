import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:florys_diaries/features/reminders/domain/trip_reminder_entry.dart';
import 'package:florys_diaries/features/trips/domain/trip.dart';

class ReminderPermissionStatus {
  const ReminderPermissionStatus({
    required this.isAvailable,
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
  });

  const ReminderPermissionStatus.unavailable()
    : isAvailable = false,
      notificationsAllowed = false,
      exactAlarmsAllowed = false;

  final bool isAvailable;
  final bool notificationsAllowed;
  final bool exactAlarmsAllowed;

  bool get canNotify => !isAvailable || notificationsAllowed;
}

class TripReminderNotificationService {
  TripReminderNotificationService._();

  static final TripReminderNotificationService instance =
      TripReminderNotificationService._();

  static const String _payloadPrefix = 'florys-reminder:';
  static const int _maximumScheduledNotifications = 250;
  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'florys_travel_reminders_v1',
        'Reiseerinnerungen',
        channelDescription:
            'Erinnerungen für Reisepläne und ablaufende Reisedokumente.',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.private,
        icon: 'ic_stat_florys_reminder',
      );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _initializationFailed = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  Future<bool> initialize() async {
    if (!_isAndroid) {
      return false;
    }
    if (_initialized) {
      return true;
    }
    if (_initializationFailed) {
      return false;
    }

    try {
      tz_data.initializeTimeZones();
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_florys_reminder'),
      );
      await _plugin.initialize(settings: settings);
      _initialized = true;
      return true;
    } catch (error, stackTrace) {
      _initializationFailed = true;
      debugPrint('Erinnerungsdienst konnte nicht initialisiert werden: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<ReminderPermissionStatus> permissionStatus() async {
    if (!_isAndroid) {
      return const ReminderPermissionStatus.unavailable();
    }
    if (!await initialize()) {
      return const ReminderPermissionStatus(
        isAvailable: true,
        notificationsAllowed: false,
        exactAlarmsAllowed: false,
      );
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    if (android == null) {
      return const ReminderPermissionStatus.unavailable();
    }

    final notificationsAllowed =
        await android.areNotificationsEnabled() ?? true;
    final exactAlarmsAllowed =
        await android.canScheduleExactNotifications() ?? true;
    return ReminderPermissionStatus(
      isAvailable: true,
      notificationsAllowed: notificationsAllowed,
      exactAlarmsAllowed: exactAlarmsAllowed,
    );
  }

  Future<ReminderPermissionStatus> requestPermissions() async {
    if (!_isAndroid) {
      return const ReminderPermissionStatus.unavailable();
    }
    if (!await initialize()) {
      return const ReminderPermissionStatus(
        isAvailable: true,
        notificationsAllowed: false,
        exactAlarmsAllowed: false,
      );
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    if (android == null) {
      return const ReminderPermissionStatus.unavailable();
    }

    var notificationsAllowed =
        await android.areNotificationsEnabled() ?? true;
    if (!notificationsAllowed) {
      notificationsAllowed =
          await android.requestNotificationsPermission() ?? false;
    }

    var exactAlarmsAllowed =
        await android.canScheduleExactNotifications() ?? true;
    if (!exactAlarmsAllowed) {
      exactAlarmsAllowed =
          await android.requestExactAlarmsPermission() ?? false;
    }

    return ReminderPermissionStatus(
      isAvailable: true,
      notificationsAllowed: notificationsAllowed,
      exactAlarmsAllowed: exactAlarmsAllowed,
    );
  }

  Future<bool> showTestNotification() async {
    if (!_isAndroid || !await initialize()) {
      return false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    if (android == null) {
      return false;
    }

    var notificationsAllowed =
        await android.areNotificationsEnabled() ?? true;
    if (!notificationsAllowed) {
      notificationsAllowed =
          await android.requestNotificationsPermission() ?? false;
    }
    if (!notificationsAllowed) {
      return false;
    }

    await _plugin.show(
      id: 2147483000,
      title: 'FlorysDiaries Erinnerung',
      body: 'Benachrichtigungen funktionieren auf diesem Gerät.',
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
      ),
      payload: '${_payloadPrefix}test',
    );
    return true;
  }

  Future<void> syncAll(Iterable<Trip> trips, {DateTime? now}) async {
    if (!_isAndroid || !await initialize()) {
      return;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    final notificationsAllowed =
        await android?.areNotificationsEnabled() ?? true;
    await _cancelManagedPendingNotifications();
    if (!notificationsAllowed) {
      return;
    }

    final exactAlarmsAllowed =
        await android?.canScheduleExactNotifications() ?? true;
    final scheduleMode = exactAlarmsAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final current = now ?? DateTime.now();
    final entries = TripReminderEntry.fromTrips(trips)
        .where((entry) => entry.isFuture(current))
        .take(_maximumScheduledNotifications);

    for (final entry in entries) {
      try {
        await _plugin.zonedSchedule(
          id: entry.notificationId,
          title: entry.title,
          body: entry.body,
          scheduledDate: tz.TZDateTime.from(entry.scheduledAt, tz.local),
          notificationDetails: const NotificationDetails(
            android: _androidDetails,
          ),
          androidScheduleMode: scheduleMode,
          payload: entry.payload,
        );
      } catch (error) {
        debugPrint(
          'Erinnerung konnte nicht geplant werden '
          '(${entry.sourceId}): $error',
        );
      }
    }
  }

  Future<void> _cancelManagedPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith(_payloadPrefix) ?? false) {
        await _plugin.cancel(id: request.id);
      }
    }
  }
}
