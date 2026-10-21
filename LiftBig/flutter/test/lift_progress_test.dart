import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/progress/lift_progress.dart';

JournalDay day(
  String dateKey,
  List<JournalExercise> exercises, {
  bool rest = false,
}) {
  return JournalDay(
    dateKey: dateKey,
    updatedAt: '2026-01-01T00:00:00.000Z',
    exercises: exercises,
    isRestDay: rest,
  );
}

JournalExercise lift(
  String name,
  List<JournalSet> sets, {
  String? libraryId,
  bool cardio = false,
  bool core = false,
}) {
  return JournalExercise(
    id: name,
    sortOrder: 0,
    name: name,
    sets: sets,
    libraryId: libraryId,
    isCardio: cardio,
    isCore: core,
  );
}

JournalSet working(String reps, String weight, {bool warmup = false, String? seconds}) {
  return JournalSet(
    id: '$reps-$weight-$warmup',
    sortOrder: 0,
    reps: reps,
    weight: weight,
    isWarmup: warmup,
    durationSeconds: seconds,
  );
}

void main() {
  test('warmup sets do not move the lift series or the first workout', () {
    final days = [
      day('2026-03-01', [
        lift('Bench Press', [working('5', '315', warmup: true)]),
      ]),
    ];

    expect(strengthSeries(days), isEmpty);
    expect(unlockedAchievements(days), isEmpty);
    expect(collectLiftHistory(days, 'Bench Press'), isEmpty);
  });

  test('a working bench set charts the load and unlocks two plates', () {
    final days = [
      day('2026-03-01', [
        lift('Bench Press', [
          working('5', '135', warmup: true),
          working('5', '225'),
        ]),
      ]),
      day('2026-03-08', [
        lift('Bench Press', [working('3', '245')]),
      ]),
    ];

    final series = collectLiftHistory(days, 'Bench Press');
    expect(series.map((point) => point.maxWeightLbs), [225, 245]);
    expect(series.first.setCount, 1);

    final earned = unlockedAchievements(days);
    expect(earned, contains('first-workout'));
    expect(earned, contains('bench-2-plates'));
    expect(earned, isNot(contains('bench-3-plates')));
  });

  test('plate rules use the library id when the logged name differs', () {
    final days = [
      day('2026-04-01', [
        lift(
          'Competition Bench',
          [working('1', '405')],
          libraryId: 'bench-press',
        ),
      ]),
    ];

    expect(unlockedAchievements(days), contains('bench-4-plates'));
  });
}
