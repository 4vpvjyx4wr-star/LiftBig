import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'watch_session.dart';

/// Phone side of the watch link. Native handlers may be absent; that means no watch.
class CompanionBridge {
  CompanionBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('liftbig/companion');

  /// One channel handler for the running app. Pages share it so a later
  /// page does not replace the listener that writes the journal.
  static final CompanionBridge shared = CompanionBridge();

  final MethodChannel _channel;
  final List<void Function(String messageJson)> _listeners = [];
  var _handlerInstalled = false;
  String? _lastRawSession;
  WatchRestPublish? _watchRest;

  /// Remembers the phone rest clock and republishes the last workout with it.
  /// [WatchRestPublish.restCancelled] is sent once, then cleared.
  void notePhoneRest(WatchRestPublish publish) {
    _watchRest = publish;
    unawaited(republishSession());
  }

  Future<bool> republishSession() async {
    final raw = _lastRawSession;
    if (raw == null) return false;
    await _send(annotateSession(raw));
    return true;
  }

  Future<void> startWorkout(String sessionJson) async {
    _lastRawSession = sessionJson;
    try {
      await _channel.invokeMethod<void>('startWorkout', {
        'sessionJson': annotateSession(sessionJson),
      });
    } on MissingPluginException {
      // No watch bridge in this build.
    } on PlatformException {
      // The watch can be unpaired or asleep. The phone workout still continues.
    }
  }

  Future<void> publishSession(String sessionJson) async {
    _lastRawSession = sessionJson;
    await _send(annotateSession(sessionJson));
  }

  String annotateSession(String sessionJson) {
    final rest = _watchRest;
    if (rest == null) return sessionJson;
    Object? decoded;
    try {
      decoded = jsonDecode(sessionJson);
    } catch (_) {
      return sessionJson;
    }
    if (decoded is! Map) return sessionJson;
    final next = withWatchRest(Map<String, Object?>.from(decoded), rest);
    if (rest.restCancelled) {
      _watchRest = WatchRestPublish(soundEnabled: rest.soundEnabled);
    }
    return jsonEncode(next);
  }

  Future<void> _send(String sessionJson) async {
    try {
      await _channel.invokeMethod<void>('publishSession', {
        'sessionJson': sessionJson,
      });
    } on MissingPluginException {
      // No watch bridge in this build.
    } on PlatformException {
      // The companion target is optional.
    }
  }

  void addListener(void Function(String messageJson) listener) {
    _listeners.add(listener);
    _ensureHandler();
  }

  void removeListener(void Function(String messageJson) listener) {
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      _channel.setMethodCallHandler(null);
      _handlerInstalled = false;
    }
  }

  void _ensureHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'companionMessage') return;
      final json = _messageJson(call.arguments);
      if (json == null || _listeners.isEmpty) return;
      for (final listener in List<void Function(String)>.of(_listeners)) {
        listener(json);
      }
    });
  }

  String? _messageJson(Object? arguments) {
    if (arguments is String) return arguments;
    if (arguments is Map) {
      final json = arguments['messageJson'];
      if (json is String) return json;
    }
    return null;
  }
}
