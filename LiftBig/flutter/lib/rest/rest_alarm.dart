import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// Plays the bundled alarm, ducking other audio, then hands volume back.
  /// True when that tone started.
  static Future<bool> play() async {
    if (kIsWeb) return false;
    try {
      return await _channel.invokeMethod<bool>('play') ?? false;
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
