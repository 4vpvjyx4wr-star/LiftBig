import 'dart:convert';

/// Fixed notification id for the rest-finished alert.
const int restFinishedNotificationId = 9001;

/// Pure remaining seconds from persisted timer fields.
int restTimerRemainingSeconds({
  required DateTime now,
  required bool active,
  required bool paused,
  required int fullSeconds,
  int? pausedRemainingSeconds,
  int? endAtEpochMs,
}) {
  if (!active) return 0;
  if (paused) {
    final remaining = pausedRemainingSeconds ?? fullSeconds;
    return remaining < 0 ? 0 : remaining;
  }
  if (endAtEpochMs == null) return fullSeconds;
  final remaining =
      (endAtEpochMs - now.millisecondsSinceEpoch) ~/ 1000;
  return remaining < 0 ? 0 : remaining;
}

/// Running timers expire at [endAtEpochMs]. Paused timers never read as expired.
bool restTimerIsExpired({
  required DateTime now,
  required bool active,
  required bool paused,
  required int fullSeconds,
  int? pausedRemainingSeconds,
  int? endAtEpochMs,
}) {
  if (!active || paused) return false;
  if (endAtEpochMs == null) return false;
  return now.millisecondsSinceEpoch >= endAtEpochMs;
}

String formatRestClock(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

/// Serializable rest timer snapshot stored in `local_settings`.
class RestTimerSnapshot {
  const RestTimerSnapshot({
    required this.active,
    this.exerciseId,
    this.exerciseName,
    required this.fullSeconds,
    required this.paused,
    this.pausedRemainingSeconds,
    this.endAtEpochMs,
  });

  final bool active;
  final String? exerciseId;
  final String? exerciseName;
  final int fullSeconds;
  final bool paused;
  final int? pausedRemainingSeconds;
  final int? endAtEpochMs;

  static const inactive = RestTimerSnapshot(
    active: false,
    fullSeconds: 0,
    paused: true,
  );

  int remainingSeconds(DateTime now) {
    return restTimerRemainingSeconds(
      now: now,
      active: active,
      paused: paused,
      fullSeconds: fullSeconds,
      pausedRemainingSeconds: pausedRemainingSeconds,
      endAtEpochMs: endAtEpochMs,
    );
  }

  bool isExpired(DateTime now) {
    return restTimerIsExpired(
      now: now,
      active: active,
      paused: paused,
      fullSeconds: fullSeconds,
      pausedRemainingSeconds: pausedRemainingSeconds,
      endAtEpochMs: endAtEpochMs,
    );
  }

  Map<String, Object?> toJson() => {
    'active': active,
    if (exerciseId != null) 'exerciseId': exerciseId,
    if (exerciseName != null) 'exerciseName': exerciseName,
    'fullSeconds': fullSeconds,
    'paused': paused,
    if (pausedRemainingSeconds != null)
      'pausedRemainingSeconds': pausedRemainingSeconds,
    if (endAtEpochMs != null) 'endAtMs': endAtEpochMs,
  };

  static RestTimerSnapshot? fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final active = decoded['active'] == true;
      if (!active) return inactive;
      final full = decoded['fullSeconds'];
      if (full is! num || full <= 0) return null;
      final paused = decoded['paused'] == true;
      int? pausedRemaining;
      final pausedRaw = decoded['pausedRemainingSeconds'];
      if (pausedRaw is num) pausedRemaining = pausedRaw.round();
      int? endAtMs;
      final endRaw = decoded['endAtMs'];
      if (endRaw is num) endAtMs = endRaw.round();
      return RestTimerSnapshot(
        active: true,
        exerciseId: decoded['exerciseId']?.toString(),
        exerciseName: decoded['exerciseName']?.toString(),
        fullSeconds: full.round(),
        paused: paused,
        pausedRemainingSeconds: pausedRemaining,
        endAtEpochMs: endAtMs,
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode(toJson());
}
