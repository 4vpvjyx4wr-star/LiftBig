import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/journal/progressive_overload.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/progress/exercise_forecast.dart';
import 'package:liftbig/progress/lift_progress.dart';

HistorySet benchSet({
  required String dateKey,
  required String reps,
  required String weight,
  bool isWarmup = false,
}) {
  return HistorySet(
    dateKey: dateKey,
    exerciseName: 'Bench Press',
    reps: reps,
    weight: weight,
    isWarmup: isWarmup,
  );
}

void main() {
  test(
    'projects five sessions from the overload step and does not persist',
    () {
      final history = [
        benchSet(dateKey: '2026-01-01', reps: '8', weight: '100'),
      ];
      final series = predictFutureLiftSessions(
        exerciseName: 'Bench Press',
        history: history,
      );
      final first = predictWorkoutGoals('Bench Press', history);

      expect(history, hasLength(1));
      expect(history.single.weight, '100');
      expect(series, hasLength(5));
      expect(series.first.weightLbs, closeTo(first.suggestedWeightLbs, 0.001));
      expect(series.first.weightLbs, closeTo(102.5, 0.001));
      expect(series.first.reps, 6);
      expect(series.first.reps, int.parse(first.suggestedLogReps));
      expect(series[1].weightLbs, closeTo(102.5, 0.001));
      expect(series[1].reps, 7);
      expect(series[2].weightLbs, closeTo(102.5, 0.001));
      expect(series[2].reps, 8);
      expect(series[3].weightLbs, closeTo(105, 0.001));
      expect(series[3].reps, 6);
      expect(series[4].weightLbs, closeTo(105, 0.001));
      expect(series[4].reps, 7);
    },
  );

  test('warmup sets do not change the forecast and no history omits it', () {
    final working = [benchSet(dateKey: '2026-01-01', reps: '8', weight: '100')];
    final withWarmup = [
      benchSet(dateKey: '2026-01-01', reps: '5', weight: '300', isWarmup: true),
      ...working,
    ];
    final fromWorking = predictFutureLiftSessions(
      exerciseName: 'Bench Press',
      history: working,
    );
    final fromWarmup = predictFutureLiftSessions(
      exerciseName: 'Bench Press',
      history: withWarmup,
    );

    expect(fromWarmup, hasLength(fromWorking.length));
    for (var i = 0; i < fromWorking.length; i++) {
      expect(fromWarmup[i].weightLbs, closeTo(fromWorking[i].weightLbs, 0.001));
      expect(fromWarmup[i].reps, fromWorking[i].reps);
    }
    expect(
      predictFutureLiftSessions(exerciseName: 'Bench Press', history: const []),
      isEmpty,
    );
    expect(
      predictFutureLiftSessions(
        exerciseName: 'Bench Press',
        history: [
          benchSet(
            dateKey: '2026-01-01',
            reps: '5',
            weight: '300',
            isWarmup: true,
          ),
        ],
      ),
      isEmpty,
    );
  });

  test('heaviest working set keeps its own reps, warmups excluded', () {
    final point = sessionPoint(
      '2026-01-01',
      const JournalExercise(
        id: 'bench',
        sortOrder: 0,
        name: 'Bench Press',
        sets: [
          JournalSet(
            id: 'warm',
            sortOrder: 0,
            reps: '5',
            weight: '300',
            isWarmup: true,
          ),
          JournalSet(id: 'light', sortOrder: 1, reps: '12', weight: '80'),
          JournalSet(id: 'heavy-low', sortOrder: 2, reps: '5', weight: '100'),
          JournalSet(id: 'heavy-high', sortOrder: 3, reps: '8', weight: '100'),
        ],
      ),
    );

    expect(point, isNotNull);
    expect(point!.maxWeightLbs, 100);
    expect(point.maxReps, 8);
    expect(point.setCount, 3);
  });

  test('library id matches that lift; otherwise the normalized name', () {
    final days = [
      JournalDay(
        dateKey: '2026-02-01',
        updatedAt: '2026-02-01T00:00:00.000Z',
        exercises: const [
          JournalExercise(
            id: 'comp',
            sortOrder: 0,
            name: 'Competition Bench',
            libraryId: 'bench-press',
            sets: [JournalSet(id: 'c', sortOrder: 0, reps: '5', weight: '100')],
          ),
        ],
      ),
      JournalDay(
        dateKey: '2026-02-08',
        updatedAt: '2026-02-08T00:00:00.000Z',
        exercises: const [
          JournalExercise(
            id: 'named',
            sortOrder: 0,
            name: 'Bench Press',
            sets: [JournalSet(id: 'n', sortOrder: 0, reps: '3', weight: '200')],
          ),
          JournalExercise(
            id: 'squat',
            sortOrder: 1,
            name: 'Squat',
            libraryId: 'squat',
            sets: [JournalSet(id: 's', sortOrder: 0, reps: '5', weight: '300')],
          ),
        ],
      ),
      JournalDay(
        dateKey: '2026-02-15',
        updatedAt: '2026-02-15T00:00:00.000Z',
        exercises: const [
          JournalExercise(
            id: 'again',
            sortOrder: 0,
            name: 'Pause Bench',
            libraryId: 'bench-press',
            sets: [JournalSet(id: 'p', sortOrder: 0, reps: '4', weight: '110')],
          ),
        ],
      ),
    ];

    final byId = collectSameLiftHistory(
      days,
      name: 'Competition Bench',
      libraryId: 'bench-press',
    );
    expect(byId.map((point) => point.maxWeightLbs), [100, 110]);

    final byName = collectSameLiftHistory(days, name: 'Bench-Press');
    expect(byName.map((point) => point.maxWeightLbs), [200]);
  });
}
