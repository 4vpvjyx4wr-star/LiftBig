import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../journal/app_settings.dart';
import 'rest_alarm.dart';
import 'rest_timer_state.dart';

/// Schedules and cancels the rest-finished lock-screen notification.
class RestFinishedNotificationOptions {
  const RestFinishedNotificationOptions({
    this.enabled = true,
    this.sound = true,
    this.vibration = true,
    this.soundId = RestTimerAlertSettings.defaultSoundId,
  });

  final bool enabled;
  final bool sound;
  final bool vibration;
  final String soundId;

  static const defaults = RestFinishedNotificationOptions();
}

/// Action id shared by the Android action and the Darwin category.
const String restAlarmStopActionId = 'stop';

/// Darwin category that shows Stop on the finished-rest notification.
const String restAlarmDarwinCategoryId = 'liftbig.rest.stop';

DarwinNotificationCategory restAlarmDarwinCategory() {
  return DarwinNotificationCategory(
    restAlarmDarwinCategoryId,
    actions: [
      DarwinNotificationAction.plain(restAlarmStopActionId, 'Stop'),
    ],
  );
}

/// Bundled tone shared by the in-app alarm and the killed-app notification.
/// The notification plays this file once. iOS will not loop it until a tap.
const String restAlarmSoundFile = 'rest_alarm.wav';

/// Android `res/raw` name, without the extension.
const String restAlarmAndroidRaw = 'rest_alarm';

/// Channel ids stay split because Android freezes sound and vibration
/// on a channel the first time it is created.
String restNotificationChannelId({
  required bool sound,
  required bool vibration,
  String soundId = RestTimerAlertSettings.defaultSoundId,
}) {
  final String base;
  if (sound && vibration) {
    base = 'liftbig_rest_tone_vibe';
  } else if (sound) {
    base = 'liftbig_rest_tone';
  } else if (vibration) {
    base = 'liftbig_rest_vibe';
  } else {
    base = 'liftbig_rest_quiet';
  }
  final id = RestTimerAlertSettings.canonicalSoundId(soundId);
  if (sound && id != RestTimerAlertSettings.defaultSoundId) {
    return '${base}_$id';
  }
  return base;
}

/// Exact when the system allows it. Otherwise the alarm is allowed to drift.
AndroidScheduleMode restAlarmAndroidScheduleMode({
  required bool canScheduleExact,
}) {
  if (canScheduleExact) return AndroidScheduleMode.exactAllowWhileIdle;
  return AndroidScheduleMode.inexactAllowWhileIdle;
}

NotificationDetails restFinishedNotificationDetails(
  RestFinishedNotificationOptions options,
) {
  final sound = options.sound;
  final soundId = RestTimerAlertSettings.canonicalSoundId(options.soundId);
  return NotificationDetails(
    android: AndroidNotificationDetails(
      restNotificationChannelId(
        sound: sound,
        vibration: options.vibration,
        soundId: soundId,
      ),
      'Rest timer',
      channelDescription: 'Alerts when your rest period ends',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: sound,
      sound: sound ? RawResourceAndroidNotificationSound(soundId) : null,
      enableVibration: options.vibration,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      actions: const [
        AndroidNotificationAction(
          restAlarmStopActionId,
          'Stop',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(
      presentSound: sound,
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      sound: sound ? '$soundId.wav' : null,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: restAlarmDarwinCategoryId,
    ),
  );
}

/// Wall clock of [endTime] in [location]. [endTime] is the device's local
/// instant. The location has to be that device zone. Leaving it at UTC makes
/// the plugin name the trigger "UTC", which US devices treat as already past.
tz.TZDateTime zonedRestEnd(DateTime endTime, [tz.Location? location]) {
  return tz.TZDateTime.from(endTime, location ?? tz.local);
}

Future<void> _useDeviceTimeZone() async {
  tz_data.initializeTimeZones();
  try {
    final name = await RestAlarm.deviceTimeZone();
    if (name == null) return;
    tz.setLocalLocation(tz.getLocation(name));
  } catch (_) {
    // Keep the last location. [zonedRestEnd] still uses the absolute instant.
  }
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
  var _consumedLaunchStop = false;
  var _pendingStop = false;
  Future<void> Function()? _onStop;

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
    final ios = DarwinInitializationSettings(
      notificationCategories: [restAlarmDarwinCategory()],
    );
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationResponse,
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
      final canExact = await android.canScheduleExactNotifications();
      if (canExact == false) {
        await android.requestExactAlarmsPermission();
      }
    }
    return granted;
  }

  @override
  Future<void> scheduleRestFinished(
    DateTime endTime, {
    RestFinishedNotificationOptions options = RestFinishedNotificationOptions.defaults,
  }) async {
    if (kIsWeb) return;
    if (!options.enabled) {
      await cancelRestFinished();
      return;
    }
    await initialize();
    await _useDeviceTimeZone();
    await cancelRestFinished();
    final when = zonedRestEnd(endTime);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      restFinishedNotificationId,
      'Rest is done',
      'LiftBig',
      when,
      restFinishedNotificationDetails(options),
      androidScheduleMode: restAlarmAndroidScheduleMode(
        canScheduleExact: canExact,
      ),
    );
  }

  @override
  Future<void> cancelRestFinished() async {
    if (kIsWeb) return;
    await _plugin.cancel(restFinishedNotificationId);
  }

  /// Stop on the finished notification calls [handler], including a tap that
  /// launched the app from a killed process.
  void bindStopHandler(Future<void> Function() handler) {
    _onStop = handler;
    if (!_pendingStop) return;
    _pendingStop = false;
    unawaited(handler());
  }

  /// True once, when this process was opened from the notification Stop action.
  Future<bool> consumeLaunchStop() async {
    if (_consumedLaunchStop || kIsWeb) return false;
    _consumedLaunchStop = true;
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      return launch?.didNotificationLaunchApp == true &&
          launch?.notificationResponse?.actionId == restAlarmStopActionId;
    } catch (_) {
      return false;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId != restAlarmStopActionId) return;
    final stop = _onStop;
    if (stop == null) {
      _pendingStop = true;
      return;
    }
    unawaited(stop());
  }
}
