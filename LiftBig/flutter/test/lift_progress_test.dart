import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/catalog/liftbig_catalog.dart';
import 'package:liftbig/journal/lift_name_convergence.dart';
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

  test('a library id groups plural names onto one lift', () {
    final deadBug = LibraryLift(
      id: 'dead-bug',
      name: 'Dead Bug',
      muscleGroups: const ['core'],
      tags: const [],
      equipment: 'Bodyweight',
      summary: '',
      instructions: const [],
      tips: const [],
      cues: const [],
      tutorialUrl: '',
      isCardio: false,
      repBasedCore: true,
    );
    final days = [
      day('2026-03-01', [
        lift('Dead Bugs', [working('10', '5')], libraryId: 'dead-bug'),
      ]),
      day('2026-03-02', [
        lift('Dead Bug', [working('12', '5')], libraryId: 'dead-bug'),
      ]),
    ];

    final series = strengthSeries(days, lifts: [deadBug]);
    expect(series, hasLength(1));
    expect(series.single.name, 'Dead Bug');
    expect(series.single.sessions, hasLength(2));
    expect(LibraryNameIndex([deadBug]).matchName('Deadbugs')?.id, 'dead-bug');
    final aliased = strengthSeries(
      [
        day('2026-04-01', [
          lift('Deadbug', [working('8', '5')], libraryId: 'deadbug'),
        ]),
        day('2026-04-02', [
          lift('Dead Bugs', [working('10', '5')]),
        ]),
      ],
      lifts: [deadBug],
    );
    expect(aliased, hasLength(1));
    expect(aliased.single.name, 'Dead Bug');
    expect(
      LibraryNameIndex([
        deadBug,
        LibraryLift(
          id: 'deadlift',
          name: 'Deadlift',
          muscleGroups: const ['back'],
          tags: const [],
          equipment: 'Barbell',
          summary: '',
          instructions: const [],
          tips: const [],
          cues: const [],
          tutorialUrl: '',
          isCardio: false,
          repBasedCore: false,
        ),
      ]).matchName('Romanian Deadlift'),
      isNull,
    );
  });

  test('current streak counts through yesterday and the next mark is 3', () {
    final today = DateTime(2026, 3, 10);
    expect(
      currentTrainingStreak(['2026-03-08', '2026-03-09'], today: today),
      2,
    );
    expect(currentTrainingStreak(['2026-03-07'], today: today), 0);
    final snapshot = trainingSnapshot([
      day('2026-03-08', [lift('Squat', [working('5', '225')])]),
      day('2026-03-09', [lift('Squat', [working('5', '230')])]),
    ], today: today);
    expect(snapshot.currentStreak, 2);
    expect(snapshot.nextStreakGoal, 3);
    expect(snapshot.weekTrained, hasLength(7));
  });

  test('journal milestones unlock the extra badges', () {
    final days = [
      day('2026-03-02', [
        lift('Squat', [working('5', '200')]),
        lift('Bench', [working('5', '150')]),
        lift('Row', [working('8', '100')]),
        lift('Press', [working('8', '80')]),
        lift('Curl', [working('10', '40')]),
      ]),
      day('2026-03-03', [
        lift('Squat', [working('5', '210')]),
      ]),
      day('2026-03-04', [
        lift('Squat', [working('5', '215')]),
      ]),
      day('2026-03-05', [
        lift('Squat', [working('5', '220')]),
      ]),
      day('2026-03-20', [
        lift('Squat', [working('5', '225')]),
      ]),
    ];
    final earned = unlockedAchievements(days);
    expect(earned, contains('five-lifts'));
    expect(earned, contains('personal-record'));
    expect(earned, contains('week-4'));
    expect(earned, contains('comeback'));
  });
}
