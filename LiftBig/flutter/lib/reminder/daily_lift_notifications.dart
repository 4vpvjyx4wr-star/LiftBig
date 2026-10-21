import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'daily_lift_reminder.dart';
import '../rest/rest_notifications.dart';

/// Schedules weekly local notifications for the daily lift reminder.
abstract class DailyLiftReminderScheduler {
  Future<void> applySettings(DailyLiftReminderSettings settings);
  Future<void> cancelAll();
  Future<bool> requestPermissionIfNeeded();
}

class NoOpDailyLiftReminderScheduler implements DailyLiftReminderScheduler {
  @override
  Future<void> applySettings(DailyLiftReminderSettings settings) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> requestPermissionIfNeeded() async => true;
}

class FlutterDailyLiftReminderScheduler implements DailyLiftReminderScheduler {
  FlutterDailyLiftReminderScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    RestNotificationScheduler? restScheduler,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _restScheduler = restScheduler ?? NoOpRestNotificationScheduler();

  final FlutterLocalNotificationsPlugin _plugin;
  final RestNotificationScheduler _restScheduler;

  static const _androidChannel = AndroidNotificationChannel(
    'liftbig_daily_reminder',
    'Daily lift reminder',
    description: 'Reminds you to log a workout',
    importance: Importance.defaultImportance,
  );

  static const _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'liftbig_daily_reminder',
      'Daily lift reminder',
      channelDescription: 'Reminds you to log a workout',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _ensureReady() async {
    if (kIsWeb) return;
    await _restScheduler.initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_androidChannel);
  }

  @override
  Future<bool> requestPermissionIfNeeded() async {
    if (kIsWeb) return false;
    return _restScheduler.requestPermissionIfNeeded();
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    for (final id in dailyLiftReminderNotificationIdsForDays(
      DailyLiftReminderSettings.allWeekdays,
    )) {
      await _plugin.cancel(id);
    }
  }

  @override
  Future<void> applySettings(DailyLiftReminderSettings settings) async {
    if (kIsWeb) return;
    await _ensureReady();
    await cancelAll();
    if (!settings.enabled) return;

    final entries = buildDailyLiftReminderSchedule(settings);
    final now = tz.TZDateTime.now(tz.local);
    for (final entry in entries) {
      var scheduled = _nextInstance(entry.weekday, entry.hour, entry.minute, now);
      await _plugin.zonedSchedule(
        entry.notificationId,
        'Lift Big',
        entry.body,
        scheduled,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextInstance(
    int weekday,
    int hour,
    int minute,
    tz.TZDateTime now,
  ) {
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }
}
