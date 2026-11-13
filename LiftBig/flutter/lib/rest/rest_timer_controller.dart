import 'dart:async';

import 'package:flutter/foundation.dart';

import '../companion/companion_bridge.dart';
import '../companion/watch_session.dart';
import '../journal/app_settings.dart';
import '../journal/journal_repository.dart';
import '../utils/weight_units.dart';
import 'rest_alarm.dart';
import 'rest_notifications.dart';
import 'rest_timer_alerts.dart';
import 'rest_timer_state.dart';

/// Saved drag position of the floating rest card. Stopping the alarm clears it.
const String restTimerTileOffsetKey = 'rest_timer_tile_offset';

/// Where the live rest card is drawn. A new rest keeps the last choice.
enum RestTimerChrome { floating, anchored }

/// App-wide rest countdown. Survives tab changes and app restarts.
class RestTimerController extends ChangeNotifier {
  RestTimerController({
    required this.journal,
    RestNotificationScheduler? notifications,
    CompanionBridge? companion,
  }) : _notifications = notifications ?? NoOpRestNotificationScheduler(),
       _companion = companion ?? CompanionBridge.shared;

  final JournalRepository journal;
  final RestNotificationScheduler _notifications;
  final CompanionBridge _companion;

  RestTimerSnapshot _snapshot = RestTimerSnapshot.inactive;
  RestTimerAlertSettings _alerts = RestTimerAlertSettings.defaults;
  RestTimerChrome _chrome = RestTimerChrome.floating;
  var _menuOpen = false;
  Timer? _tick;
  var _playedFinishedFeedback = false;
  var _alarmRinging = false;
  var _alarmEpoch = 0;
  var _watchListening = false;
  var _disposed = false;
  var _restRev = 0;
  late final Future<void> Function() _stopFromOutside = stopAlarm;

  RestTimerSnapshot get snapshot => _snapshot;

  RestTimerChrome get chrome => _chrome;

  bool get menuOpen => _menuOpen;

  bool get isActive => _snapshot.active;

  /// Floating card, including the default. Hidden while the menu is open.
  bool get showsFloatingCard =>
      isActive && _chrome == RestTimerChrome.floating && !_menuOpen;

  /// Lift-tab bar. Absent while the card is floating or rest is off.
  bool get showsAnchored =>
      isActive && _chrome == RestTimerChrome.anchored;

  int get remaining => _snapshot.remainingSeconds(DateTime.now());

  bool get soundEnabled => _alerts.soundEnabled;

  /// True while the in-app rest tone is looping and waiting to be stopped.
  bool get alarmRinging => _alarmRinging;

  bool get isRunning =>
      _snapshot.active &&
      !_snapshot.paused &&
      remaining > 0 &&
      _snapshot.endAtEpochMs != null;

  Future<void> load() async {
    _bindExternalStops();
    _alerts = await journal.loadRestTimerAlertSettings();
    _chrome = await journal.loadRestTimerAnchored()
        ? RestTimerChrome.anchored
        : RestTimerChrome.floating;
    final stored = await journal.loadRestTimerState();
    _snapshot = stored ?? RestTimerSnapshot.inactive;
    _playedFinishedFeedback = false;
    _alarmRinging = false;
    final openedFromStop = await _openedFromNotificationStop();
    final now = DateTime.now();
    if (openedFromStop) {
      if (_snapshot.active && _snapshot.isExpired(now)) {
        _playedFinishedFeedback = true;
      }
      await _clearDragOffset();
      _chrome = RestTimerChrome.anchored;
      await journal.saveRestTimerAnchored(true);
    }
    if (_snapshot.active && _snapshot.isExpired(now)) {
      _maybePlayFinishedFeedback(now);
    } else if (_snapshot.active &&
        !_snapshot.paused &&
        _snapshot.endAtEpochMs != null) {
      await _notifications.scheduleRestFinished(
        DateTime.fromMillisecondsSinceEpoch(_snapshot.endAtEpochMs!),
        options: _notificationOptions(),
      );
      await _syncAlarmSession();
    }
    _publishWatchRest();
    _syncTick();
    notifyListeners();
  }

  Future<void> reloadAlertSettings() async {
    _alerts = await journal.loadRestTimerAlertSettings();
    if (isRunning && _snapshot.endAtEpochMs != null) {
      await _notifications.scheduleRestFinished(
        DateTime.fromMillisecondsSinceEpoch(_snapshot.endAtEpochMs!),
        options: _notificationOptions(),
      );
    }
    await _syncAlarmSession();
    _publishWatchRest();
    notifyListeners();
  }

  RestFinishedNotificationOptions _notificationOptions() {
    return RestFinishedNotificationOptions(
      enabled: _alerts.notificationEnabled,
      sound: _alerts.soundEnabled,
      vibration: _alerts.vibrationEnabled,
      soundId: _alerts.soundId,
    );
  }

  void _bindExternalStops() {
    RestAlarm.bindRemoteStop(_stopFromOutside);
    if (_watchListening) return;
    _watchListening = true;
    _companion.addListener(_onWatchMessage);
  }

  Future<bool> _openedFromNotificationStop() async {
    final notifications = _notifications;
    if (notifications is! FlutterRestNotificationScheduler) return false;
    notifications.bindStopHandler(_stopFromOutside);
    return notifications.consumeLaunchStop();
  }

  void _onWatchMessage(String raw) {
    final message = parseCompanionMessage(raw, fallbackUnit: WeightUnit.lb);
    if (message == null) return;
    if (message.isStopAlarm) {
      unawaited(stopAlarm());
      return;
    }
    if (message.isSkipRest) {
      unawaited(dismiss());
      return;
    }
    if (message.isPauseRest) {
      unawaited(pause(remainingSeconds: message.restRemaining));
      return;
    }
    if (message.isResumeRest) {
      unawaited(resume());
    }
  }

  Future<void> start({
    required String exerciseId,
    required String exerciseName,
    required int fullSeconds,
  }) async {
    if (fullSeconds <= 0) return;
    _claimRev();
    _alerts = await journal.loadRestTimerAlertSettings();
    _playedFinishedFeedback = false;
    _alarmEpoch += 1;
    _alarmRinging = false;
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
    await _syncAlarmSession();
    _publishWatchRest();
    _syncTick();
    notifyListeners();
  }

  Future<void> pause({int? remainingSeconds}) async {
    if (!_snapshot.active || _snapshot.paused) return;
    var left = remaining;
    if (remainingSeconds != null && remainingSeconds > 0) {
      left = remainingSeconds;
    }
    if (left <= 0) return;
    _claimRev();
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
    await _syncAlarmSession();
    _publishWatchRest();
    _syncTick();
    notifyListeners();
  }

  Future<void> resume() async {
    if (!_snapshot.active || !_snapshot.paused) return;
    final left = remaining;
    if (left <= 0) return;
    _claimRev();
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
    await _syncAlarmSession();
    _publishWatchRest();
    _syncTick();
    notifyListeners();
  }

  /// Moves the end time to [remainingSeconds] from now. Does not restart from
  /// the original full duration and does not play the finished alert.
  Future<void> setRemaining(int remainingSeconds) async {
    if (!_snapshot.active) return;
    _claimRev();
    await _silenceAlarm();
    final seconds = remainingSeconds < 0 ? 0 : remainingSeconds;
    if (_snapshot.paused) {
      _snapshot = RestTimerSnapshot(
        active: true,
        exerciseId: _snapshot.exerciseId,
        exerciseName: _snapshot.exerciseName,
        fullSeconds: _snapshot.fullSeconds,
        paused: true,
        pausedRemainingSeconds: seconds,
      );
      await _persist();
      _publishWatchRest();
      _syncTick();
      notifyListeners();
      return;
    }
    if (seconds <= 0) {
      _playedFinishedFeedback = true;
      _snapshot = RestTimerSnapshot(
        active: true,
        exerciseId: _snapshot.exerciseId,
        exerciseName: _snapshot.exerciseName,
        fullSeconds: _snapshot.fullSeconds,
        paused: false,
        endAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      );
      await _persist();
      await _notifications.cancelRestFinished();
      await RestAlarm.stopKeepAlive();
      _publishWatchRest();
      _syncTick();
      notifyListeners();
      return;
    }
    final endAt = DateTime.now().add(Duration(seconds: seconds));
    _playedFinishedFeedback = false;
    _snapshot = RestTimerSnapshot(
      active: true,
      exerciseId: _snapshot.exerciseId,
      exerciseName: _snapshot.exerciseName,
      fullSeconds: _snapshot.fullSeconds,
      paused: false,
      endAtEpochMs: endAt.millisecondsSinceEpoch,
    );
    await _persistAndSchedule(endAt);
    await _syncAlarmSession();
    _publishWatchRest();
    _syncTick();
    notifyListeners();
  }

  /// Restarts the current rest from its full duration and keeps counting.
  Future<void> reset({
    String? exerciseId,
    String? exerciseName,
    int? fullSeconds,
  }) async {
    final seconds = fullSeconds ?? _snapshot.fullSeconds;
    if (!_snapshot.active || seconds <= 0) return;
    await _notifications.cancelRestFinished();
    _playedFinishedFeedback = false;
    _alarmEpoch += 1;
    _alarmRinging = false;
    if (_alerts.notificationEnabled) {
      await _notifications.requestPermissionIfNeeded();
    }
    final endAt = DateTime.now().add(Duration(seconds: seconds));
    _snapshot = RestTimerSnapshot(
      active: true,
      exerciseId: exerciseId ?? _snapshot.exerciseId,
      exerciseName: exerciseName ?? _snapshot.exerciseName,
      fullSeconds: seconds,
      paused: false,
      endAtEpochMs: endAt.millisecondsSinceEpoch,
    );
    await _persistAndSchedule(endAt);
    await _syncAlarmSession();
    _publishWatchRest();
    _syncTick();
    notifyListeners();
  }

  /// Hides the floating card or brings it back. Does not stop the countdown.
  Future<void> setChrome(RestTimerChrome chrome) async {
    if (_chrome == chrome) return;
    _chrome = chrome;
    await journal.saveRestTimerAnchored(chrome == RestTimerChrome.anchored);
    notifyListeners();
  }

  /// The menu can cover the card. Opening it does not pause the countdown.
  void setMenuOpen(bool open) {
    if (_menuOpen == open) return;
    _menuOpen = open;
    notifyListeners();
  }

  Future<void> dismiss() async {
    _claimRev();
    _snapshot = RestTimerSnapshot.inactive;
    _playedFinishedFeedback = true;
    _alarmEpoch += 1;
    _alarmRinging = false;
    _syncTick();
    await _notifications.cancelRestFinished();
    await RestAlarm.stopKeepAlive();
    await journal.clearRestTimerState();
    _publishWatchRest(cancelled: true);
    notifyListeners();
  }

  Future<void> togglePause() async {
    if (!_snapshot.active) return;
    if (remaining <= 0) {
      await stopAlarm();
      return;
    }
    if (_snapshot.paused) {
      await resume();
    } else {
      await pause();
    }
  }

  /// Stops a looping in-app tone and parks the finished rest at the top of
  /// the lift page. Cancel uses [dismiss], which stops the tone and clears
  /// the timer.
  Future<void> stopAlarm() async {
    if (_disposed) return;
    _claimRev();
    await _silenceAlarm();
    if (_disposed) return;
    await _clearDragOffset();
    if (_disposed) return;
    await setChrome(RestTimerChrome.anchored);
    if (_disposed) return;
    _publishWatchRest();
    notifyListeners();
  }

  Future<void> _clearDragOffset() async {
    try {
      await (journal.db.delete(journal.db.localSettings)
            ..where((setting) => setting.key.equals(restTimerTileOffsetKey)))
          .go();
    } catch (_) {
      // The tone still stops if the saved position cannot be cleared.
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
    final loop = _alerts.soundEnabled && _alerts.ringUntilStopped;
    _alarmRinging = loop;
    _publishWatchRest();
    final epoch = _alarmEpoch;
    unawaited(_playFinished(epoch));
  }

  Future<void> _playFinished(int epoch) async {
    final looping = await playRestTimerFinishedAlerts(
      _alerts,
      onAlarmPlayed: _notifications.cancelRestFinished,
    );
    if (epoch != _alarmEpoch) {
      if (isRunning && _alerts.soundEnabled) {
        await RestAlarm.stopKeepAlive();
        await RestAlarm.startKeepAlive();
      } else {
        await RestAlarm.stopKeepAlive();
      }
      return;
    }
    if (_alarmRinging == looping) return;
    _alarmRinging = looping;
    _publishWatchRest();
    notifyListeners();
  }

  Future<void> _silenceAlarm() async {
    _alarmEpoch += 1;
    _alarmRinging = false;
    await RestAlarm.stopKeepAlive();
  }

  Future<void> _syncAlarmSession() async {
    if (_alarmRinging &&
        _alerts.soundEnabled &&
        _alerts.ringUntilStopped &&
        !isRunning) {
      return;
    }
    _alarmRinging = false;
    if (_alerts.soundEnabled && isRunning) {
      await RestAlarm.stopKeepAlive();
      await RestAlarm.startKeepAlive();
      return;
    }
    await RestAlarm.stopKeepAlive();
  }

  void _claimRev() {
    if (_companion.latestRestRev > _restRev) {
      _restRev = _companion.latestRestRev;
    }
    _restRev += 1;
  }

  void _publishWatchRest({bool cancelled = false}) {
    final ends = _snapshot.endAtEpochMs;
    final running = isRunning && ends != null;
    _companion.notePhoneRest(
      WatchRestPublish(
        soundEnabled: _alerts.soundEnabled,
        restCancelled: cancelled,
        restPaused: _snapshot.active && _snapshot.paused,
        restRemaining: _snapshot.active ? remaining : null,
        restEndsAtEpochSeconds: running ? (ends / 1000).round() : null,
        alarmRinging: _alarmRinging,
        restRevision: _restRev,
      ),
    );
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
      _maybePlayFinishedFeedback(now);
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    if (_watchListening) {
      _companion.removeListener(_onWatchMessage);
      _watchListening = false;
    }
    RestAlarm.clearRemoteStop(_stopFromOutside);
    unawaited(RestAlarm.stopKeepAlive());
    super.dispose();
  }
}
