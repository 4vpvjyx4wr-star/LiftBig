import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'rest_timer_state.dart';

/// Schedules and cancels the rest-finished lock-screen notification.
class RestFinishedNotificationOptions {
  const RestFinishedNotificationOptions({
    this.enabled = true,
    this.sound = true,
    this.vibration = true,
  });

  final bool enabled;
  final bool sound;
  final bool vibration;

  static const defaults = RestFinishedNotificationOptions();
}

abstract class RestNotificationScheduler {
  Future<void> initialize();
  Future<bool> requestPermissionIfNeeded();
  Future<void> scheduleRestFinished(
    DateTime endTime, {
    RestFinishedNotificationOptions options = RestFinishedNotificationOptions.defaults,
  });
  Future<void> cancelRestFinished();
}

class NoOpRestNotificationScheduler implements RestNotificationScheduler {
  @override
  Future<void> cancelRestFinished() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissionIfNeeded() async => true;

  @override
  Future<void> scheduleRestFinished(
    DateTime endTime, {
    RestFinishedNotificationOptions options = RestFinishedNotificationOptions.defaults,
  }) async {}
}

class FlutterRestNotificationScheduler implements RestNotificationScheduler {
  FlutterRestNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  var _initialized = false;

  static const _androidChannel = AndroidNotificationChannel(
    'liftbig_rest',
    'Rest timer',
    description: 'Alerts when your rest period ends',
    importance: Importance.high,
  );

  @override
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
    _initialized = true;
  }

  @override
  Future<bool> requestPermissionIfNeeded() async {
    if (kIsWeb) return false;
    await initialize();
    var granted = true;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      granted = await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      granted =
          await android.requestNotificationsPermission() ?? granted;
    }
    return granted;
  }

  @override
  Future<void> scheduleRestFinished(
    DateTime endTime, {
    RestFinishedNotificationOptions options = RestFinishedNotificationOptions.defaults,
  }) async {
    if (kIsWeb || !options.enabled) return;
    await initialize();
    await cancelRestFinished();
    final when = tz.TZDateTime.from(endTime, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'liftbig_rest',
        'Rest timer',
        channelDescription: 'Alerts when your rest period ends',
        importance: Importance.high,
        priority: Priority.high,
        playSound: options.sound,
        enableVibration: options.vibration,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: options.sound,
        presentAlert: true,
      ),
    );
    await _plugin.zonedSchedule(
      restFinishedNotificationId,
      'Rest is done',
      'LiftBig',
      when,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelRestFinished() async {
    if (kIsWeb) return;
    await _plugin.cancel(restFinishedNotificationId);
  }
}
