import 'package:flutter/services.dart';

/// Phone side of the watch link. Native handlers may be absent; that means no watch.
class CompanionBridge {
  CompanionBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('liftbig/companion');

  final MethodChannel _channel;
  final List<void Function(String messageJson)> _listeners = [];
  var _handlerInstalled = false;

  Future<void> publishSession(String sessionJson) async {
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
      _listeners.last(json);
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
