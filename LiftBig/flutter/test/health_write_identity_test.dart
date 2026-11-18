import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/health/body_weight_health.dart';
import 'package:liftbig/health/health_workout.dart';

void main() {
  HealthWorkoutWrite sample({int minutes = 40, double? kcal = 300}) {
    final end = DateTime(2026, 11, 12, 18).millisecondsSinceEpoch;
    return HealthWorkoutWrite(
      id: 'liftbig-2026-11-12-strength',
      activity: HealthActivity.strength,
      startMs: end - minutes * 60 * 1000,
      endMs: end,
      energyKcal: kcal,
    );
  }

  test('an unchanged fingerprint skips another Health write', () {
    final next = sample();
    final stored = StoredHealthWrite(
      uuid: 'abc',
      minutes: healthWriteMinutes(next),
      meters: 0,
      kcal: 300,
    );
    expect(
      healthWriteAction(stored: stored, next: next),
      HealthWriteAction.skip,
    );
  });

  test('a longer session replaces the stored workout', () {
    final stored = const StoredHealthWrite(
      uuid: 'abc',
      minutes: 40,
      meters: 0,
      kcal: 300,
    );
    expect(
      healthWriteAction(stored: stored, next: sample(minutes: 42)),
      HealthWriteAction.replace,
    );
  });

  test('weight samples keep the latest reading each day and steps sum', () {
    final weights = latestWeightPerDay([
      (dateKey: '2026-03-01', lbs: 180, at: DateTime(2026, 3, 1, 8)),
      (dateKey: '2026-03-01', lbs: 181, at: DateTime(2026, 3, 1, 20)),
      (dateKey: '2026-03-02', lbs: 179, at: DateTime(2026, 3, 2, 8)),
    ]);
    expect(weights.map((point) => point.lbs), [181, 179]);
    final steps = stepSeries(
      sumStepsPerDay([
        (dateKey: '2026-03-02', steps: 1000),
        (dateKey: '2026-03-02', steps: 500),
      ]),
      today: DateTime(2026, 3, 2),
      days: 2,
    );
    expect(steps.map((day) => day.steps), [0, 1500]);
  });

  test('a missing uuid inserts once', () {
    expect(
      healthWriteAction(stored: null, next: sample()),
      HealthWriteAction.insert,
    );
  });
}
