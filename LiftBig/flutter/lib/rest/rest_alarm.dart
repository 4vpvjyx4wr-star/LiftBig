import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../journal/app_settings.dart';

/// iOS playback alarm and the device IANA timezone.
///
/// Missing on web and on builds without the native handler. Callers fall back.
class RestAlarm {
  static const channelName = 'liftbig/rest_alarm';
  static const _channel = MethodChannel(channelName);

  static Future<String?> deviceTimeZone() async {
    if (kIsWeb) return null;
    try {
      final name = await _channel.invokeMethod<String>('deviceTimeZone');
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Silent playback so a backgrounded app is still alive when rest hits zero.
  /// Does nothing audible and does not duck music. No-op when sound is off.
  static Future<void> startKeepAlive() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('startKeepAlive');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  /// Ends the silent session. Also stops an alarm that is still playing.
  static Future<void> stopKeepAlive() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<bool>('stopKeepAlive');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<void> Function()? _onRemoteStop;
  static var _remoteStopBound = false;

  /// Lock-screen Stop on iOS calls this while the tone is looping.
  static void bindRemoteStop(Future<void> Function() onStop) {
    _onRemoteStop = onStop;
    if (_remoteStopBound || kIsWeb) return;
    _remoteStopBound = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'alarmStopped') return;
      await _onRemoteStop?.call();
    });
  }

  static void clearRemoteStop(Future<void> Function() onStop) {
    if (identical(_onRemoteStop, onStop)) _onRemoteStop = null;
  }

  /// Plays the bundled alarm, ducking other audio, then hands volume back.
  /// True when that tone started. [loop] repeats it until [stopKeepAlive].
  /// [soundId] is `rest_alarm`, `bell`, `chime`, or `horn`.
  /// The killed-app notification does not use this path and stays one play.
  static Future<bool> play({
    bool loop = false,
    String soundId = RestTimerAlertSettings.defaultSoundId,
  }) async {
    if (kIsWeb) return false;
    try {
      return await _channel.invokeMethod<bool>('play', {
            'loop': loop,
            'soundId': RestTimerAlertSettings.canonicalSoundId(soundId),
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Longer Core Haptics on iOS, or a waveform on Android. False when absent.
  static Future<bool> haptic() async {
    if (kIsWeb) return false;
    try {
      return await _channel.invokeMethod<bool>('haptic') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
