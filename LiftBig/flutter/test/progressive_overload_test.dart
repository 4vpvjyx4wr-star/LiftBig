import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/journal/progressive_overload.dart';
import 'package:liftbig/journal/strength_standards.dart';
import 'package:liftbig/model/journal_day.dart';

HistorySet benchSet({
  required String dateKey,
  required String reps,
  required String weight,
  bool isWarmup = false,
  String? targetReps,
  String? difficulty,
  String exerciseName = 'Bench Press',
}) {
  return HistorySet(
    dateKey: dateKey,
    exerciseName: exerciseName,
    reps: reps,
    weight: weight,
    isWarmup: isWarmup,
    targetReps: targetReps,
    difficulty: difficulty,
  );
}

LoggedSetFill fillFor(List<HistorySet> history, {String displayUnit = 'lb', String name = 'Bench Press', String? target = '8-12'}) {
  final fill = loggedSetFill(
    exerciseName: name,
    history: history,
    currentTargetReps: target,
    displayUnit: displayUnit,
  );
  expect(fill, isNotNull);
  return fill!;
}

void main() {
  test('prediction uses prior working sets for that lift', () {
    final fill = loggedSetFill(
      exerciseName: 'Bench Press',
      history: [
        benchSet(dateKey: '2026-01-01', reps: '8', weight: '100'),
      ],
      excludeDateKey: '2026-01-08',
    );
    expect(fill, isNotNull);
    // 8 reps infers 6-8, which is the top, so the load steps up and reps reset.
    expect(fill!.weight, '102.5');
    expect(fill.reps, '6');
    expect(setCountsTowardProgress(benchSet(
      dateKey: '2026-01-01',
      reps: '8',
      weight: '100',
    )), isTrue);
  });

  test('warmup sets do not count toward the prediction', () {
    final working = loggedSetFill(
      exerciseName: 'Bench Press',
      history: [
        benchSet(dateKey: '2026-01-01', reps: '8', weight: '100'),
      ],
    );
    final withWarmup = loggedSetFill(
      exerciseName: 'Bench Press',
      history: [
        benchSet(
          dateKey: '2026-01-01',
          reps: '5',
          weight: '300',
          isWarmup: true,
          difficulty: setDifficultyEasy,
        ),
        benchSet(dateKey: '2026-01-01', reps: '8', weight: '100'),
      ],
    );
    expect(withWarmup, working);
    expect(
      setCountsTowardProgress(
        benchSet(
          dateKey: '2026-01-01',
          reps: '5',
          weight: '300',
          isWarmup: true,
        ),
      ),
      isFalse,
    );
    expect(
      loggedSetFill(
        exerciseName: 'Bench Press',
        history: [
          benchSet(
            dateKey: '2026-01-01',
            reps: '5',
            weight: '300',
            isWarmup: true,
          ),
        ],
        bodyWeightLbs: defaultAssumedBodyWeightLbs,
      )?.weight,
      isNotNull,
    );
  });

  test('no history does not invent a starting weight', () {
    final predicted = predictWorkoutGoals('Bench Press', const []);
    expect(predicted.hasHistory, isFalse);
    expect(predicted.suggestedWeightLbs, 0);
    expect(predicted.suggestedLogReps, isEmpty);
    expect(predicted.reason, 'No history yet');
  });

  test('no history uses Strength Level bodyweight standards', () {
    final fill = loggedSetFill(
      exerciseName: 'Bench Press',
      libraryId: 'bench-press',
      bodyWeightLbs: 180,
      history: const [],
    );
    expect(fill, isNotNull);
    expect(fill!.reps, '12');
    expect(double.parse(fill.weight), closeTo(165, 20));
  });

  test('reps increase inside the range before the load does', () {
    final fill = fillFor([
      benchSet(
        dateKey: '2026-01-01',
        reps: '10',
        weight: '100',
        targetReps: '8-12',
      ),
      benchSet(
        dateKey: '2026-01-01',
        reps: '9',
        weight: '100',
        targetReps: '8-12',
      ),
    ]);
    expect(fill.weight, '100');
    expect(fill.reps, '10');
    expect(predictWorkoutGoals('Bench Press', [
      benchSet(dateKey: '2026-01-01', reps: '9', weight: '100', targetReps: '8-12'),
    ]).reason, contains('Add reps before adding weight'));
  });

  test('load increases by one increment at the top of the range', () {
    final bench = fillFor([
      benchSet(dateKey: '2026-01-01', reps: '12', weight: '100', targetReps: '8-12'),
      benchSet(dateKey: '2026-01-01', reps: '12', weight: '100', targetReps: '8-12'),
    ]);
    expect(bench.weight, '102.5');
    expect(bench.reps, '8');

    final squat = fillFor(
      [
        benchSet(
          dateKey: '2026-01-01',
          reps: '5',
          weight: '200',
          targetReps: '5',
          exerciseName: 'Squat',
        ),
      ],
      name: 'Squat',
      target: '5',
    );
    expect(squat.weight, '205');
    expect(squat.reps, '5');
  });

  test('an unset rating matches the no-rating path', () {
    final rated = fillFor([
      benchSet(
        dateKey: '2026-01-01',
        reps: '9',
        weight: '100',
        targetReps: '8-12',
        difficulty: null,
      ),
    ]);
    final omitted = fillFor([
      benchSet(dateKey: '2026-01-01', reps: '9', weight: '100', targetReps: '8-12'),
    ]);
    expect(rated, omitted);
    expect(rated.reps, '10');
    expect(rated.weight, '100');
  });

  test('Easy moves reps up faster and still adds load at the top', () {
    final inside = fillFor([
      benchSet(
        dateKey: '2026-01-01',
        reps: '8',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyEasy,
      ),
    ]);
    expect(inside.weight, '100');
    expect(inside.reps, '10');
    expect(
      predictWorkoutGoals('Bench Press', [
        benchSet(
          dateKey: '2026-01-01',
          reps: '8',
          weight: '100',
          targetReps: '8-12',
          difficulty: setDifficultyEasy,
        ),
      ]).reason,
      contains('Rated Easy'),
    );

    final top = fillFor([
      benchSet(
        dateKey: '2026-01-01',
        reps: '12',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyEasy,
      ),
    ]);
    expect(top.weight, '102.5');
    expect(top.reps, '8');
  });

  test('Moderate matches standard double progression', () {
    final inside = fillFor([
      benchSet(
        dateKey: '2026-01-01',
        reps: '8',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyModerate,
      ),
    ]);
    final plain = fillFor([
      benchSet(dateKey: '2026-01-01', reps: '8', weight: '100', targetReps: '8-12'),
    ]);
    expect(inside.weight, plain.weight);
    expect(inside.reps, plain.reps);
    expect(inside.reps, '9');
    expect(
      predictWorkoutGoals('Bench Press', [
        benchSet(
          dateKey: '2026-01-01',
          reps: '8',
          weight: '100',
          targetReps: '8-12',
          difficulty: setDifficultyModerate,
        ),
      ]).reason,
      contains('Rated Moderate'),
    );

    final top = fillFor([
      benchSet(
        dateKey: '2026-01-01',
        reps: '12',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyModerate,
      ),
    ]);
    expect(top.weight, '102.5');
    expect(top.reps, '8');
  });

  test('Difficult holds, and one short set steps back a single increment', () {
    final held = fillFor([
      benchSet(
        dateKey: '2026-01-01',
        reps: '12',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyDifficult,
      ),
    ]);
    expect(held.weight, '100');
    expect(held.reps, '12');
    expect(double.parse(held.weight), greaterThan(90));

    final short = fillFor([
      benchSet(
        dateKey: '2026-01-01',
        reps: '6',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyDifficult,
      ),
    ]);
    expect(short.weight, '97.5');
    expect(short.reps, '6');
    expect(double.parse(short.weight), greaterThan(90));
    expect(
      predictWorkoutGoals('Bench Press', [
        benchSet(
          dateKey: '2026-01-01',
          reps: '6',
          weight: '100',
          targetReps: '8-12',
          difficulty: setDifficultyDifficult,
        ),
      ]).reason,
      contains('Rated Difficult'),
    );
  });

  test('one Difficult set does not slash the load when the session was Easy', () {
    final fill = fillFor([
      benchSet(
        dateKey: '2026-01-01',
        reps: '12',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyEasy,
      ),
      benchSet(
        dateKey: '2026-01-01',
        reps: '12',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyEasy,
      ),
      benchSet(
        dateKey: '2026-01-01',
        reps: '12',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyDifficult,
      ),
    ]);
    expect(fill.weight, '102.5');
    expect(double.parse(fill.weight), greaterThan(100));
  });

  test('repeated Difficult sessions take one small step back', () {
    final history = [
      benchSet(
        dateKey: '2026-01-01',
        reps: '12',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyDifficult,
      ),
      benchSet(
        dateKey: '2026-01-08',
        reps: '12',
        weight: '100',
        targetReps: '8-12',
        difficulty: setDifficultyDifficult,
      ),
    ];
    final fill = fillFor(history);
    expect(fill.weight, '97.5');
    expect(fill.reps, '8');
    expect(double.parse(fill.weight), greaterThan(90));
    expect(
      predictWorkoutGoals('Bench Press', history).reason,
      contains('Several Difficult sessions'),
    );
  });

  test('missing the bottom of the range does not increase the load', () {
    final fill = fillFor([
      benchSet(dateKey: '2026-01-01', reps: '6', weight: '100', targetReps: '8-12'),
    ]);
    expect(fill.weight, '100');
    expect(fill.reps, '6');
    expect(
      predictWorkoutGoals('Bench Press', [
        benchSet(dateKey: '2026-01-01', reps: '6', weight: '100', targetReps: '8-12'),
      ]).reason,
      contains('Short of the rep range'),
    );
  });

  test('kilogram display uses a 1 kg upper-body step and a 2.5 kg lower-body step', () {
    final bench = fillFor(
      [
        benchSet(dateKey: '2026-01-01', reps: '12', weight: '100', targetReps: '8-12'),
      ],
      displayUnit: 'kg',
    );
    expect(double.parse(bench.weight), closeTo(46 * 2.2046226218, 0.02));
    expect(bench.reps, '8');
    expect(
      predictWorkoutGoals(
        'Bench Press',
        [
          benchSet(dateKey: '2026-01-01', reps: '12', weight: '100', targetReps: '8-12'),
        ],
        currentTargetReps: '8-12',
        lockRepGoal: true,
        displayUnit: 'kg',
      ).reason,
      contains('1 kg'),
    );

    final squat = fillFor(
      [
        benchSet(
          dateKey: '2026-01-01',
          reps: '5',
          weight: '200',
          targetReps: '5',
          exerciseName: 'Squat',
        ),
      ],
      name: 'Squat',
      target: '5',
      displayUnit: 'kg',
    );
    expect(double.parse(squat.weight), closeTo(92.5 * 2.2046226218, 0.02));
    expect(squat.reps, '5');
  });
}
