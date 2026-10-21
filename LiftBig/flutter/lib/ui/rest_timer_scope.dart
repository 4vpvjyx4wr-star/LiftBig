import 'package:flutter/material.dart';

import '../rest/rest_timer_controller.dart';

class RestTimerScope extends InheritedWidget {
  const RestTimerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final RestTimerController controller;

  static RestTimerController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RestTimerScope>();
    assert(scope != null, 'RestTimerScope not found');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(RestTimerScope oldWidget) {
    return oldWidget.controller != controller;
  }
}
