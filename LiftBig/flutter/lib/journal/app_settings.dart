import 'dart:convert';

import 'logged_day.dart';

const int defaultAverageLiftSeconds = 60;

const int minBodyWeightLbs = 50;
const int maxBodyWeightLbs = 700;
const double minHeightInches = 36;
const double maxHeightInches = 96;

/// Clamps height the way Vue `sanitizeHeightInches` does. Zero or invalid clears it.
double? sanitizeHeightInches(double? value) {
  if (value == null || !value.isFinite || value <= 0) return null;
  final clamped = value.clamp(minHeightInches, maxHeightInches);
  return (clamped * 10).round() / 10;
}

/// Clamps body weight the way Vue `sanitizeBodyWeightLbs` does.
double? sanitizeBodyWeightLbs(double? value) {
  if (value == null || !value.isFinite || value <= 0) return null;
  final clamped = value.clamp(minBodyWeightLbs.toDouble(), maxBodyWeightLbs.toDouble());
  return (clamped * 10).round() / 10;
}

int averageLiftSecondsFromSettings(String? settingsJson) {
  final raw = _settingsValue(settingsJson, 'averageLiftSeconds');
  if (raw is num) return clampAverageRestSeconds(raw.round());
  return defaultAverageLiftSeconds;
}

/// Dedicated local key wins, then imported JSON, then 60.
int resolveAverageRestSeconds({
  String? storedKeyValue,
  String? settingsJson,
}) {
  final fromKey = int.tryParse(storedKeyValue?.trim() ?? '');
  if (fromKey != null) return clampAverageRestSeconds(fromKey);
  return averageRestSecondsFromSettings(settingsJson);
}

int resolveAverageLiftSeconds({
  String? storedKeyValue,
  String? settingsJson,
}) {
  final fromKey = int.tryParse(storedKeyValue?.trim() ?? '');
  if (fromKey != null) return clampAverageRestSeconds(fromKey);
  return averageLiftSecondsFromSettings(settingsJson);
}

bool boolSettingFromStored(String? raw, {required bool defaultValue}) {
  if (raw == null || raw.trim().isEmpty) return defaultValue;
  if (raw == 'true') return true;
  if (raw == 'false') return false;
  return defaultValue;
}

class RestTimerAlertSettings {
  const RestTimerAlertSettings({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.notificationEnabled,
    this.ringUntilStopped = false,
    this.soundId = defaultSoundId,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationEnabled;

  /// When rest ends, the in-app tone repeats until the lifter stops it.
  /// Off unless the stored value is the word `true`. The lock-screen
  /// notification stays a single play.
  final bool ringUntilStopped;

  /// Bundled tone id. One of [soundIds]. Unknown values become [defaultSoundId].
  final String soundId;

  static const defaultSoundId = 'rest_alarm';
  static const soundIds = <String>['rest_alarm', 'bell', 'chime', 'horn'];

  static const defaults = RestTimerAlertSettings(
    soundEnabled: true,
    vibrationEnabled: true,
    notificationEnabled: true,
  );

  static String canonicalSoundId(String? raw) {
    final id = raw?.trim() ?? '';
    if (soundIds.contains(id)) return id;
    return defaultSoundId;
  }

  RestTimerAlertSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notificationEnabled,
    bool? ringUntilStopped,
    String? soundId,
  }) {
    return RestTimerAlertSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      ringUntilStopped: ringUntilStopped ?? this.ringUntilStopped,
      soundId: soundId ?? this.soundId,
    );
  }
}

/// Which phone-to-watch links the user has left on.
/// Apple and Garmin match today's sync. Samsung is stored only.
class WatchCompanionSettings {
  const WatchCompanionSettings({
    required this.apple,
    required this.garmin,
    required this.samsung,
  });

  final bool apple;
  final bool garmin;
  final bool samsung;

  static const defaults = WatchCompanionSettings(
    apple: true,
    garmin: true,
    samsung: false,
  );

  WatchCompanionSettings copyWith({
    bool? apple,
    bool? garmin,
    bool? samsung,
  }) {
    return WatchCompanionSettings(
      apple: apple ?? this.apple,
      garmin: garmin ?? this.garmin,
      samsung: samsung ?? this.samsung,
    );
  }
}

Object? _settingsValue(String? settingsJson, String key) {
  if (settingsJson == null || settingsJson.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(settingsJson);
    if (decoded is Map) return decoded[key];
  } catch (_) {
    return null;
  }
  return null;
}
