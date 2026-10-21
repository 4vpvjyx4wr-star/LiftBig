import 'package:flutter/services.dart';

import '../journal/app_settings.dart';

/// Foreground feedback when the in-app rest countdown hits zero.
void playRestTimerFinishedAlerts(RestTimerAlertSettings settings) {
  if (settings.vibrationEnabled) {
    HapticFeedback.heavyImpact();
  }
  if (settings.soundEnabled) {
    SystemSound.play(SystemSoundType.alert);
  }
}
