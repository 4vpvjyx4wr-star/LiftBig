import 'dart:async';

import '../journal/journal_repository.dart';
import 'body_weight_health.dart';
import 'health_workout.dart';

/// Debounced Health write for one logged day. Calories come from active energy,
/// or a strength estimate when Apple recorded almost none.
class JournalHealthSync {
  JournalHealthSync({
    required this.journal,
    BodyWeightHealthSync? health,
    this.onStored,
  }) : _health = health ?? BodyWeightHealthSync();

  final JournalRepository journal;
  final BodyWeightHealthSync _health;
  final void Function()? onStored;
  Timer? _timer;
  static final _inflight = <String, Future<void>>{};

  void scheduleDay(String dateKey) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      syncDay(dateKey);
    });
  }

  void dispose() {
    _timer?.cancel();
  }

  Future<void> syncDay(String dateKey, {bool honorToggle = true}) {
    final running = _inflight[dateKey];
    if (running != null) return running;
    final run = _syncDayNow(dateKey, honorToggle: honorToggle);
    _inflight[dateKey] = run;
    return run.whenComplete(() {
      if (identical(_inflight[dateKey], run)) _inflight.remove(dateKey);
    });
  }

  Future<void> _syncDayNow(String dateKey, {bool honorToggle = true}) async {
    if (honorToggle && !await journal.appleHealthSyncEnabled()) return;
    final granted = await _health.requestAccess();
    if (!granted) return;
    final day = await journal.getDay(dateKey);
    if (day == null || day.exercises.isEmpty) {
      if (day != null) {
        await journal.setHealthEnergyKcal(dateKey, null);
        onStored?.call();
      }
      return;
    }
    final liftSeconds = await journal.storedAverageLiftSeconds();
    final restSeconds = await journal.storedAverageRestSeconds();
    final writes = healthWritesForDay(
      day: day,
      averageLiftSeconds: liftSeconds,
      averageRestSeconds: restSeconds,
    );
    if (writes.isEmpty) {
      await journal.setHealthEnergyKcal(dateKey, null);
      onStored?.call();
      return;
    }

    final bodyWeightLbs = await journal.storedBodyWeightLbs();

    // Strength and cardio windows share an end time, so summing each window
    // would count the overlap twice. The day stores one read of the union.
    final startMs = writes
        .map((write) => write.startMs)
        .reduce((a, b) => a < b ? a : b);
    final endMs = writes
        .map((write) => write.endMs)
        .reduce((a, b) => a > b ? a : b);
    final dayEnergy = await _health.readActiveEnergyKcal(
      DateTime.fromMillisecondsSinceEpoch(startMs),
      DateTime.fromMillisecondsSinceEpoch(endMs),
    );

    double? kcalForWindow(double? appleKcal, double minutes) {
      // Apple often returns ~0–3 kcal when the watch missed the session.
      if (minutes >= 10 &&
          (appleKcal == null || appleKcal < 1.5 * minutes)) {
        return estimateStrengthKcal(
          minutes: minutes,
          bodyWeightLbs: bodyWeightLbs,
        );
      }
      return appleKcal;
    }

    final storedWrites = await journal.loadHealthWorkoutWrites();
    var writesChanged = false;
    for (final write in writes) {
      final read = writes.length == 1
          ? dayEnergy
          : await _health.readActiveEnergyKcal(
              DateTime.fromMillisecondsSinceEpoch(write.startMs),
              DateTime.fromMillisecondsSinceEpoch(write.endMs),
            );
      final minutes = (write.endMs - write.startMs).abs() / 60000;
      final apple = read.succeeded ? read.kcal : null;
      write.energyKcal = kcalForWindow(apple, minutes);
      final previous = storedWrites[write.id];
      final action = healthWriteAction(stored: previous, next: write);
      if (action == HealthWriteAction.skip) continue;
      if (action == HealthWriteAction.replace && previous != null) {
        await _health.deleteWorkout(previous.uuid);
      }
      final uuid = await _health.writeWorkoutUuid(write);
      if (uuid == null) continue;
      storedWrites[write.id] = StoredHealthWrite(
        uuid: uuid,
        minutes: healthWriteMinutes(write),
        meters: (write.distanceMeters ?? 0).round(),
        kcal: (write.energyKcal ?? -1).round(),
      );
      writesChanged = true;
    }
    if (writesChanged) await journal.saveHealthWorkoutWrites(storedWrites);
    final dayMinutes = (endMs - startMs).abs() / 60000;
    final appleDay = dayEnergy.succeeded ? dayEnergy.kcal : null;
    final stored = kcalForWindow(appleDay, dayMinutes);
    if (stored == null && !dayEnergy.succeeded) return;
    await journal.setHealthEnergyKcal(dateKey, stored);
    onStored?.call();
  }
}