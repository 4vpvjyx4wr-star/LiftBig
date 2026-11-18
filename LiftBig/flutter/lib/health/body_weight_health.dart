import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../date_key.dart';
import '../journal/app_settings.dart';
import '../utils/weight_units.dart';
import 'health_workout.dart';

/// Apple Health / Health Connect weight, height, workouts, and active energy.
class BodyWeightHealthSync {
  BodyWeightHealthSync({Health? health}) : _health = health ?? Health();

  final Health _health;
  var _configured = false;

  static const _types = [
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];
  static const _permissions = [
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
  ];
  static const _stepTypes = [HealthDataType.STEPS];
  static const _stepPermissions = [HealthDataAccess.READ];

  Future<void> _ensureConfigured() async {
    if (_configured || kIsWeb) return;
    await _health.configure();
    _configured = true;
  }

  Future<bool> requestAccess() async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    try {
      return await _health.requestAuthorization(_types, permissions: _permissions);
    } catch (_) {
      return false;
    }
  }

  /// True when read access appears granted (best-effort; platform APIs vary).
  Future<bool> hasReadAccess() async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    try {
      final has = await _health.hasPermissions(_types, permissions: _permissions);
      return has ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Asks for step read access. Weight and workouts keep their own request.
  Future<bool> requestStepReadAccess() async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    try {
      return await _health.requestAuthorization(
        _stepTypes,
        permissions: _stepPermissions,
      );
    } catch (_) {
      return false;
    }
  }

  /// Body-weight samples from Health, one reading per day, in pounds.
  Future<List<HealthWeightSample>> readBodyWeightHistory() async {
    if (kIsWeb) return const [];
    await _ensureConfigured();
    try {
      final now = DateTime.now();
      final samples = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WEIGHT],
        startTime: now.subtract(const Duration(days: 365 * 5)),
        endTime: now,
      );
      final parsed = <({String dateKey, double lbs, DateTime at})>[];
      for (final sample in samples) {
        if (sample.type != HealthDataType.WEIGHT) continue;
        final kg = _numeric(sample.value);
        final lbs = sanitizeBodyWeightLbs(kg == null ? null : kgToLbs(kg));
        if (lbs == null) continue;
        parsed.add((
          dateKey: toDateKey(sample.dateTo),
          lbs: lbs,
          at: sample.dateTo,
        ));
      }
      return latestWeightPerDay(parsed);
    } catch (_) {
      return const [];
    }
  }

  /// Step totals for the last [days] local days, including zeros.
  Future<List<StepDay>> readRecentSteps({int days = 14}) async {
    if (kIsWeb) return const [];
    await _ensureConfigured();
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days - 1));
    try {
      final samples = await _health.getHealthDataFromTypes(
        types: _stepTypes,
        startTime: start,
        endTime: today,
      );
      final parsed = <({String dateKey, double steps})>[];
      for (final sample in samples) {
        if (sample.type != HealthDataType.STEPS) continue;
        final steps = _numeric(sample.value);
        if (steps == null || steps < 0) continue;
        parsed.add((dateKey: toDateKey(sample.dateFrom), steps: steps));
      }
      return stepSeries(sumStepsPerDay(parsed), today: today, days: days);
    } catch (_) {
      return stepSeries(const [], today: today, days: days);
    }
  }

  /// Latest body weight in pounds, or null if unavailable.
  Future<double?> readBodyWeightLbs() async {
    if (kIsWeb) return null;
    await _ensureConfigured();
    try {
      final now = DateTime.now();
      final samples = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WEIGHT],
        startTime: now.subtract(const Duration(days: 365 * 5)),
        endTime: now,
      );
      final weights = samples
          .where((sample) => sample.type == HealthDataType.WEIGHT)
          .toList();
      if (weights.isEmpty) return null;
      weights.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final latest = weights.first;
      final kg = latest.value is NumericHealthValue
          ? (latest.value as NumericHealthValue).numericValue.toDouble()
          : double.tryParse('${latest.value}');
      if (kg == null || kg <= 0) return null;
      return sanitizeBodyWeightLbs(kgToLbs(kg));
    } catch (_) {
      return null;
    }
  }

  /// Writes [bodyWeightLbs] to Health. Returns false on failure or missing permission.
  Future<bool> writeBodyWeightLbs(double bodyWeightLbs) async {
    if (kIsWeb) return false;
    final lbs = sanitizeBodyWeightLbs(bodyWeightLbs);
    if (lbs == null) return false;
    await _ensureConfigured();
    try {
      final kg = lbsToKg(lbs);
      final now = DateTime.now();
      return await _health.writeHealthData(
        value: kg,
        type: HealthDataType.WEIGHT,
        startTime: now,
        endTime: now,
      );
    } catch (_) {
      return false;
    }
  }

  /// Latest height in inches, or null if unavailable.
  Future<double?> readHeightInches() async {
    if (kIsWeb) return null;
    await _ensureConfigured();
    try {
      final now = DateTime.now();
      final samples = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEIGHT],
        startTime: now.subtract(const Duration(days: 365 * 10)),
        endTime: now,
      );
      if (samples.isEmpty) return null;
      samples.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final latest = samples.first;
      final meters = latest.value is NumericHealthValue
          ? (latest.value as NumericHealthValue).numericValue.toDouble()
          : double.tryParse('${latest.value}');
      if (meters == null || meters <= 0) return null;
      return sanitizeHeightInches(meters / 0.0254);
    } catch (_) {
      return null;
    }
  }

  Future<bool> writeHeightInches(double inches) async {
    if (kIsWeb) return false;
    final sanitized = sanitizeHeightInches(inches);
    if (sanitized == null) return false;
    await _ensureConfigured();
    try {
      final now = DateTime.now();
      return await _health.writeHealthData(
        value: sanitized * 0.0254,
        type: HealthDataType.HEIGHT,
        startTime: now,
        endTime: now,
      );
    } catch (_) {
      return false;
    }
  }

  /// Active energy in the window. [succeeded] is false when the read itself fails.
  Future<EnergyRead> readActiveEnergyKcal(DateTime start, DateTime end) async {
    if (kIsWeb) return const EnergyRead(succeeded: false);
    await _ensureConfigured();
    try {
      final samples = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: end,
      );
      final values = <double>[];
      for (final sample in samples) {
        final value = sample.value;
        final kcal = value is NumericHealthValue
            ? value.numericValue.toDouble()
            : double.tryParse('$value');
        if (kcal == null) continue;
        values.add(kcal);
      }
      return EnergyRead(succeeded: true, kcal: sumActiveEnergyKcal(values));
    } catch (_) {
      return const EnergyRead(succeeded: false);
    }
  }

  Future<bool> workoutAlreadyWritten(HealthWorkoutWrite next) async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    try {
      final start = DateTime.fromMillisecondsSinceEpoch(next.startMs)
          .subtract(const Duration(hours: 12));
      final end = DateTime.fromMillisecondsSinceEpoch(next.endMs)
          .add(const Duration(hours: 12));
      final samples = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WORKOUT],
        startTime: start,
        endTime: end,
      );
      for (final sample in samples) {
        final value = sample.value;
        if (value is! WorkoutHealthValue) continue;
        final activity = healthActivityFromPlugin(value.workoutActivityType);
        if (activity == null) continue;
        if (healthWorkoutDuplicates(
          existingActivity: activity,
          existingStartMs: sample.dateFrom.millisecondsSinceEpoch,
          existingEndMs: sample.dateTo.millisecondsSinceEpoch,
          next: next,
        )) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Writes the workout and returns its Health UUID.
  Future<String?> writeWorkoutUuid(HealthWorkoutWrite write) async {
    if (kIsWeb) return null;
    await _ensureConfigured();
    try {
      final activity = healthPluginActivity(write.activity);
      final kcal = write.energyKcal;
      final uuid = await _health.writeWorkoutDataUUID(
        activityType: activity,
        start: DateTime.fromMillisecondsSinceEpoch(write.startMs),
        end: DateTime.fromMillisecondsSinceEpoch(write.endMs),
        totalEnergyBurned: kcal == null ? null : kcal.round(),
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
        totalDistance: write.distanceMeters == null
            ? null
            : write.distanceMeters!.round(),
        totalDistanceUnit: HealthDataUnit.METER,
        title: 'LiftBig',
        recordingMethod: RecordingMethod.manual,
      );
      if (uuid == null || uuid.isEmpty || uuid == 'null') return null;
      return uuid;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteWorkout(String uuid) async {
    if (kIsWeb || uuid.isEmpty) return;
    await _ensureConfigured();
    try {
      await _health.deleteByUUID(uuid: uuid, type: HealthDataType.WORKOUT);
    } catch (_) {}
  }

  /// Writes the workout. Calories are only attached when [write.energyKcal] is set.
  Future<bool> writeWorkout(HealthWorkoutWrite write) async {
    if (kIsWeb) return false;
    await _ensureConfigured();
    try {
      final activity = healthPluginActivity(write.activity);
      final kcal = write.energyKcal;
      return await _health.writeWorkoutData(
        activityType: activity,
        start: DateTime.fromMillisecondsSinceEpoch(write.startMs),
        end: DateTime.fromMillisecondsSinceEpoch(write.endMs),
        totalEnergyBurned: kcal == null ? null : kcal.round(),
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
        totalDistance: write.distanceMeters == null
            ? null
            : write.distanceMeters!.round(),
        totalDistanceUnit: HealthDataUnit.METER,
        title: 'LiftBig',
        recordingMethod: RecordingMethod.manual,
      );
    } catch (_) {
      return false;
    }
  }
}

double? _numeric(HealthValue value) {
  if (value is NumericHealthValue) return value.numericValue.toDouble();
  return double.tryParse('$value');
}

/// One Health weight reading kept for the chart.
class HealthWeightSample {
  const HealthWeightSample({required this.dateKey, required this.lbs});

  final String dateKey;
  final double lbs;
}

/// Step count for one local day.
class StepDay {
  const StepDay({required this.dateKey, required this.steps});

  final String dateKey;
  final int steps;
}

/// Latest sample wins when several land on the same day.
List<HealthWeightSample> latestWeightPerDay(
  Iterable<({String dateKey, double lbs, DateTime at})> samples,
) {
  final best = <String, ({double lbs, DateTime at})>{};
  for (final sample in samples) {
    if (!isValidDateKey(sample.dateKey)) continue;
    final current = best[sample.dateKey];
    if (current == null || sample.at.isAfter(current.at)) {
      best[sample.dateKey] = (lbs: sample.lbs, at: sample.at);
    }
  }
  final out = [
    for (final entry in best.entries)
      HealthWeightSample(dateKey: entry.key, lbs: entry.value.lbs),
  ]..sort((a, b) => a.dateKey.compareTo(b.dateKey));
  return out;
}

List<StepDay> sumStepsPerDay(
  Iterable<({String dateKey, double steps})> samples,
) {
  final totals = <String, double>{};
  for (final sample in samples) {
    if (!isValidDateKey(sample.dateKey)) continue;
    totals[sample.dateKey] = (totals[sample.dateKey] ?? 0) + sample.steps;
  }
  final out = [
    for (final entry in totals.entries)
      StepDay(dateKey: entry.key, steps: entry.value.round()),
  ]..sort((a, b) => a.dateKey.compareTo(b.dateKey));
  return out;
}

/// [days] local dates ending on [today], with 0 where Health had no samples.
List<StepDay> stepSeries(
  List<StepDay> counted, {
  required DateTime today,
  int days = 14,
}) {
  final byDate = {for (final day in counted) day.dateKey: day.steps};
  final start = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: days <= 0 ? 0 : days - 1));
  final count = days <= 0 ? 0 : days;
  return [
    for (var i = 0; i < count; i++)
      StepDay(
        dateKey: toDateKey(start.add(Duration(days: i))),
        steps: byDate[toDateKey(start.add(Duration(days: i)))] ?? 0,
      ),
  ];
}

class EnergyRead {
  const EnergyRead({required this.succeeded, this.kcal});

  final bool succeeded;
  final double? kcal;
}

HealthWorkoutActivityType healthPluginActivity(HealthActivity activity) {
  return switch (activity) {
    HealthActivity.strength =>
      HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
    HealthActivity.walking => HealthWorkoutActivityType.WALKING,
    HealthActivity.running => HealthWorkoutActivityType.RUNNING,
    HealthActivity.cycling => HealthWorkoutActivityType.BIKING,
    HealthActivity.swimming => HealthWorkoutActivityType.SWIMMING,
    HealthActivity.rowing => HealthWorkoutActivityType.ROWING,
    HealthActivity.hiking => HealthWorkoutActivityType.HIKING,
    HealthActivity.elliptical => HealthWorkoutActivityType.ELLIPTICAL,
    HealthActivity.stairs => HealthWorkoutActivityType.STAIR_CLIMBING,
    HealthActivity.mixedCardio => HealthWorkoutActivityType.MIXED_CARDIO,
  };
}

HealthActivity? healthActivityFromPlugin(HealthWorkoutActivityType type) {
  return switch (type) {
    HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING =>
      HealthActivity.strength,
    HealthWorkoutActivityType.WALKING ||
    HealthWorkoutActivityType.WALKING_TREADMILL => HealthActivity.walking,
    HealthWorkoutActivityType.RUNNING ||
    HealthWorkoutActivityType.RUNNING_TREADMILL => HealthActivity.running,
    HealthWorkoutActivityType.BIKING ||
    HealthWorkoutActivityType.BIKING_STATIONARY => HealthActivity.cycling,
    HealthWorkoutActivityType.SWIMMING ||
    HealthWorkoutActivityType.SWIMMING_POOL ||
    HealthWorkoutActivityType.SWIMMING_OPEN_WATER => HealthActivity.swimming,
    HealthWorkoutActivityType.ROWING ||
    HealthWorkoutActivityType.ROWING_MACHINE => HealthActivity.rowing,
    HealthWorkoutActivityType.HIKING => HealthActivity.hiking,
    HealthWorkoutActivityType.ELLIPTICAL => HealthActivity.elliptical,
    HealthWorkoutActivityType.STAIR_CLIMBING ||
    HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE => HealthActivity.stairs,
    HealthWorkoutActivityType.MIXED_CARDIO => HealthActivity.mixedCardio,
    _ => null,
  };
}
