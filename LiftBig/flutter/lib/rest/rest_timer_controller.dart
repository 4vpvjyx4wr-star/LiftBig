import 'dart:async';

import 'package:flutter/foundation.dart';

import '../journal/app_settings.dart';
import '../journal/journal_repository.dart';
import 'rest_notifications.dart';
import 'rest_timer_alerts.dart';
import 'rest_timer_state.dart';

/// App-wide rest countdown. Survives tab changes and app restarts.
class RestTimerController extends ChangeNotifier {
  RestTimerController({
    required this.journal,
    RestNotificationScheduler? notifications,
  }) : _notifications = notifications ?? NoOpRestNotificationScheduler();

  final JournalRepository journal;
  final RestNotificationScheduler _notifications;

  RestTimerSnapshot _snapshot = RestTimerSnapshot.inactive;
  RestTimerAlertSettings _alerts = RestTimerAlertSettings.defaults;
  Timer? _tick;
  var _playedFinishedFeedback = false;

  RestTimerSnapshot get snapshot => _snapshot;

  bool get isActive => _snapshot.active;

  int get remaining => _snapshot.remainingSeconds(DateTime.now());

  bool get isRunning =>
      _snapshot.active &&
      !_snapshot.paused &&
      remaining > 0 &&
      _snapshot.endAtEpochMs != null;

  Future<void> load() async {
    _alerts = await journal.loadRestTimerAlertSettings();
    final stored = await journal.loadRestTimerState();
    _snapshot = stored ?? RestTimerSnapshot.inactive;
    _playedFinishedFeedback = false;
    final now = DateTime.now();
    if (_snapshot.active && _snapshot.isExpired(now)) {
      await _notifications.cancelRestFinished();
      _maybePlayFinishedFeedback(now);
    } else if (_snapshot.active &&
        !_snapshot.paused &&
        _snapshot.endAtEpochMs != null) {
      await _notifications.scheduleRestFinished(
        DateTime.fromMillisecondsSinceEpoch(_snapshot.endAtEpochMs!),
        options: _notificationOptions(),
      );
    }
    _syncTick();
    notifyListeners();
  }

  Future<void> reloadAlertSettings() async {
    _alerts = await journal.loadRestTimerAlertSettings();
  }

  RestFinishedNotificationOptions _notificationOptions() {
    return RestFinishedNotificationOptions(
      enabled: _alerts.notificationEnabled,
      sound: _alerts.soundEnabled,
      vibration: _alerts.vibrationEnabled,
    );
  }

  Future<void> start({
    required String exerciseId,
    required String exerciseName,
    required int fullSeconds,
  }) async {
    if (fullSeconds <= 0) return;
    _alerts = await journal.loadRestTimerAlertSettings();
    _playedFinishedFeedback = false;
    if (_alerts.notificationEnabled) {
      await _notifications.requestPermissionIfNeeded();
    }
    final endAt = DateTime.now().add(Duration(seconds: fullSeconds));
    _snapshot = RestTimerSnapshot(
      active: true,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      fullSeconds: fullSeconds,
      paused: false,
      endAtEpochMs: endAt.millisecondsSinceEpoch,
    );
    await _persistAndSchedule(endAt);
    _syncTick();
    notifyListeners();
  }

  Future<void> pause() async {
    if (!_snapshot.active || _snapshot.paused) return;
    final left = remaining;
    if (left <= 0) return;
    await _notifications.cancelRestFinished();
    _snapshot = RestTimerSnapshot(
      active: true,
      exerciseId: _snapshot.exerciseId,
      exerciseName: _snapshot.exerciseName,
      fullSeconds: _snapshot.fullSeconds,
      paused: true,
      pausedRemainingSeconds: left,
    );
    await _persist();
    _syncTick();
    notifyListeners();
  }

  Future<void> resume() async {
    if (!_snapshot.active || !_snapshot.paused) return;
    final left = remaining;
    if (left <= 0) return;
    if (_alerts.notificationEnabled) {
      await _notifications.requestPermissionIfNeeded();
    }
    final endAt = DateTime.now().add(Duration(seconds: left));
    _snapshot = RestTimerSnapshot(
      active: true,
      exerciseId: _snapshot.exerciseId,
      exerciseName: _snapshot.exerciseName,
      fullSeconds: _snapshot.fullSeconds,
      paused: false,
      endAtEpochMs: endAt.millisecondsSinceEpoch,
    );
    await _persistAndSchedule(endAt);
    _syncTick();
    notifyListeners();
  }

  Future<void> reset({
    String? exerciseId,
    String? exerciseName,
    required int fullSeconds,
  }) async {
    if (fullSeconds <= 0) return;
    await _notifications.cancelRestFinished();
    _snapshot = RestTimerSnapshot(
      active: true,
      exerciseId: exerciseId ?? _snapshot.exerciseId,
      exerciseName: exerciseName ?? _snapshot.exerciseName,
      fullSeconds: fullSeconds,
      paused: true,
      pausedRemainingSeconds: fullSeconds,
    );
    await _persist();
    _syncTick();
    notifyListeners();
  }

  Future<void> dismiss() async {
    await _notifications.cancelRestFinished();
    _snapshot = RestTimerSnapshot.inactive;
    await journal.clearRestTimerState();
    _syncTick();
    notifyListeners();
  }

  Future<void> togglePause() async {
    if (!_snapshot.active) return;
    if (remaining <= 0) return;
    if (_snapshot.paused) {
      await resume();
    } else {
      await pause();
    }
  }

  Future<void> _persistAndSchedule(DateTime endAt) async {
    await journal.saveRestTimerState(_snapshot);
    await _notifications.scheduleRestFinished(
      endAt,
      options: _notificationOptions(),
    );
  }

  void _maybePlayFinishedFeedback(DateTime now) {
    if (_playedFinishedFeedback) return;
    if (!_snapshot.active || !_snapshot.isExpired(now)) return;
    _playedFinishedFeedback = true;
    playRestTimerFinishedAlerts(_alerts);
  }

  Future<void> _persist() async {
    if (!_snapshot.active) {
      await journal.clearRestTimerState();
      return;
    }
    await journal.saveRestTimerState(_snapshot);
  }

  void _syncTick() {
    _tick?.cancel();
    _tick = null;
    if (!_snapshot.active) return;
    if (_snapshot.paused) return;
    if (remaining <= 0) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (!_snapshot.active || _snapshot.paused) return;
    final now = DateTime.now();
    if (_snapshot.isExpired(now)) {
      _tick?.cancel();
      _tick = null;
      _notifications.cancelRestFinished();
      _maybePlayFinishedFeedback(now);
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}
