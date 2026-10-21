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
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationEnabled;

  static const defaults = RestTimerAlertSettings(
    soundEnabled: true,
    vibrationEnabled: true,
    notificationEnabled: true,
  );

  RestTimerAlertSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notificationEnabled,
  }) {
    return RestTimerAlertSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
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
