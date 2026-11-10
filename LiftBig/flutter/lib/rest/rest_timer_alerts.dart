import 'dart:async';

import 'package:flutter/services.dart';

import '../journal/app_settings.dart';
import 'rest_alarm.dart';

/// Foreground feedback when the in-app rest countdown hits zero.
///
/// [onAlarmPlayed] runs only after the in-process tone has started, so the
/// pending notification can be cancelled and a living app does not double-ring.
Future<void> playRestTimerFinishedAlerts(
  RestTimerAlertSettings settings, {
  Future<void> Function()? onAlarmPlayed,
}) async {
  if (settings.vibrationEnabled) {
    unawaited(_pulseHaptics());
  }
  if (!settings.soundEnabled) {
    await RestAlarm.stopKeepAlive();
    return;
  }
  final played = await RestAlarm.play();
  if (played) {
    await onAlarmPlayed?.call();
    return;
  }
  await SystemSound.play(SystemSoundType.alert);
}

Future<void> _pulseHaptics() async {
  final played = await RestAlarm.haptic();
  if (played) return;
  const delays = <int>[0, 220, 440, 720, 980, 1300, 1620, 2000];
  for (final delay in delays) {
    Future<void>.delayed(Duration(milliseconds: delay), () {
      HapticFeedback.heavyImpact();
    });
  }
}
