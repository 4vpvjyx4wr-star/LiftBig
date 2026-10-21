import 'dart:async';

import '../journal/journal_repository.dart';
import 'body_weight_health.dart';
import 'health_workout.dart';

/// Debounced Health write for one logged day. Calories come only from active energy.
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

  void scheduleDay(String dateKey) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      syncDay(dateKey);
    });
  }

  void dispose() {
    _timer?.cancel();
  }

  Future<void> syncDay(String dateKey) async {
    if (!await journal.appleHealthSyncEnabled()) return;
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

    for (final write in writes) {
      if (writes.length == 1) {
        if (dayEnergy.succeeded) write.energyKcal = dayEnergy.kcal;
      } else {
        final read = await _health.readActiveEnergyKcal(
          DateTime.fromMillisecondsSinceEpoch(write.startMs),
          DateTime.fromMillisecondsSinceEpoch(write.endMs),
        );
        if (read.succeeded) write.energyKcal = read.kcal;
      }
      if (!await _health.workoutAlreadyWritten(write)) {
        await _health.writeWorkout(write);
      }
    }
    if (!dayEnergy.succeeded) return;
    await journal.setHealthEnergyKcal(dateKey, dayEnergy.kcal);
    onStored?.call();
  }
}