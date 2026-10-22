import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/journal/logged_day.dart';
import 'package:liftbig/model/journal_day.dart';

void main() {
  test('rest uses the exercise prescription, otherwise the settings average', () {
    const exercise = JournalExercise(
      id: 'ex',
      sortOrder: 0,
      name: 'Bench',
      targetRestSeconds: 90,
      sets: [],
    );
    expect(
      restSecondsForExercise(exercise, averageRestSeconds: 60),
      90,
    );
    expect(
      restSecondsForExercise(
        const JournalExercise(
          id: 'ex',
          sortOrder: 0,
          name: 'Bench',
          sets: [],
        ),
        averageRestSeconds: 60,
      ),
      60,
    );
    expect(
      restSecondsForExercise(
        const JournalExercise(
          id: 'ex',
          sortOrder: 0,
          name: 'Bench',
          targetRestSeconds: 0,
          sets: [],
        ),
        averageRestSeconds: 75,
      ),
      75,
    );
  });

  test('average rest follows the Vue clamps and default', () {
    expect(averageRestSecondsFromSettings(null), 60);
    expect(averageRestSecondsFromSettings('{"theme":"default"}'), 60);
    expect(averageRestSecondsFromSettings('{"averageRestSeconds":90}'), 90);
    expect(averageRestSecondsFromSettings('{"averageRestSeconds":1}'), 5);
    expect(averageRestSecondsFromSettings('{"averageRestSeconds":900}'), 600);
    expect(averageRestSecondsFromSettings('not json'), 60);
  });

  test('exercise completion follows checked sets only', () {
    const incomplete = JournalExercise(
      id: 'ex',
      sortOrder: 0,
      name: 'Bench',
      sets: [
        JournalSet(id: 'a', sortOrder: 0, reps: '5', weight: '135', checked: true),
        JournalSet(id: 'b', sortOrder: 1, reps: '5', weight: '135'),
      ],
    );
    const complete = JournalExercise(
      id: 'ex',
      sortOrder: 0,
      name: 'Bench',
      sets: [
        JournalSet(id: 'a', sortOrder: 0, reps: '5', weight: '135', checked: true),
        JournalSet(
          id: 'b',
          sortOrder: 1,
          reps: '5',
          weight: '135',
          isWarmup: true,
          checked: true,
        ),
      ],
    );
    expect(exerciseAllSetsChecked(incomplete), isFalse);
    expect(exerciseAllSetsChecked(complete), isTrue);
    expect(
      exerciseAllSetsChecked(
        const JournalExercise(id: 'ex', sortOrder: 0, name: 'Bench', sets: []),
      ),
      isFalse,
    );
  });

  test('auto-advance moves weight to reps to the next weight', () {
    expect(autoAdvanceFromSettings(null), isTrue);
    expect(
      autoAdvanceFromSettings('{"autoAdvanceRepsToWeight":false}'),
      isFalse,
    );
    expect(
      advanceAfterWeight(enabled: true, weight: '135', setId: 'a'),
      isA<FieldAdvance>().having((advance) => advance.toReps, 'toReps', isTrue),
    );
    expect(
      advanceAfterWeight(enabled: true, weight: '  ', setId: 'a'),
      isNull,
    );
    expect(
      advanceAfterWeight(enabled: false, weight: '135', setId: 'a'),
      isNull,
    );
    final next = advanceAfterReps(enabled: true, reps: '5', nextSetId: 'b');
    expect(next!.setId, 'b');
    expect(next.toReps, isFalse);
    expect(advanceAfterReps(enabled: true, reps: '5', nextSetId: null), isNull);
    expect(advanceAfterReps(enabled: true, reps: '', nextSetId: 'b'), isNull);
  });

  test('rest labels speak minutes once the value reaches one minute', () {
    expect(formatRestDurationLabel(30), '30 seconds');
    expect(formatRestDurationLabel(70), '1 minute 10 seconds');
    expect(formatRestDurationLabel(60), '1 minute');
    expect(formatRestDurationLabel(120), '2 minutes');
  });

  test('auto rest waits until the second lift in a superset', () {
    const first = JournalExercise(
      id: 'a',
      sortOrder: 0,
      name: 'Bench',
      supersetGroupId: 'ss-1',
      supersetLabel: 'A',
      supersetOrder: 1,
      sets: [],
    );
    const second = JournalExercise(
      id: 'b',
      sortOrder: 1,
      name: 'Row',
      supersetGroupId: 'ss-1',
      supersetLabel: 'A',
      supersetOrder: 2,
      sets: [],
    );
    const alone = JournalExercise(
      id: 'c',
      sortOrder: 2,
      name: 'Squat',
      sets: [],
    );
    expect(startsRestAfterSet(first, [first, second, alone]), isFalse);
    expect(startsRestAfterSet(second, [first, second, alone]), isTrue);
    expect(startsRestAfterSet(alone, [first, second, alone]), isTrue);
  });
}
