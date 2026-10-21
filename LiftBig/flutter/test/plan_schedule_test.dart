import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/catalog/liftbig_catalog.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/plans/plan_schedule.dart';

JournalDay _outsideDay() {
  return JournalDay(
    dateKey: '2026-10-10',
    updatedAt: '2026-10-10T10:00:00.000Z',
    workoutName: 'Push A',
    planName: 'Strength',
    exercises: [
      JournalExercise(
        id: 'ex-outside',
        sortOrder: 0,
        name: 'Bench Press',
        sets: [
          JournalSet(id: 's1', sortOrder: 0, reps: '5', weight: '225'),
        ],
      ),
    ],
  );
}

void main() {
  test('scheduledDateForPlanIndex uses consecutive days when restEvery is 0', () {
    expect(scheduledDateForPlanIndex('2026-11-01', 0, 0), '2026-11-01');
    expect(scheduledDateForPlanIndex('2026-11-01', 1, 0), '2026-11-02');
    expect(scheduledDateForPlanIndex('2026-11-01', 2, 0), '2026-11-03');
  });

  test('scheduling three workouts writes three days and leaves others alone', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(() => journal.db.close());

    await journal.replaceDay(_outsideDay());

    final workouts = [
      CatalogWorkout(
        id: 'w1',
        name: 'Day 1',
        folderId: 'p',
        notes: '',
        lifts: [
          CatalogLift(
            name: 'Bench',
            libraryId: 'bench',
            isCardio: false,
            isCore: false,
            isCircuit: false,
            targetDuration: null,
            sets: [CatalogSet(reps: '8', weight: '')],
          ),
        ],
      ),
      CatalogWorkout(
        id: 'w2',
        name: 'Day 2',
        folderId: 'p',
        notes: '',
        lifts: [
          CatalogLift(
            name: 'Row',
            libraryId: 'row',
            isCardio: false,
            isCore: false,
            isCircuit: false,
            targetDuration: null,
            sets: [CatalogSet(reps: '8', weight: '')],
          ),
        ],
      ),
      CatalogWorkout(
        id: 'w3',
        name: 'Day 3',
        folderId: 'p',
        notes: '',
        lifts: [
          CatalogLift(
            name: 'Deadlift',
            libraryId: 'dead',
            isCardio: false,
            isCore: false,
            isCircuit: false,
            targetDuration: null,
            sets: [CatalogSet(reps: '5', weight: '')],
          ),
        ],
      ),
    ];

    final count = await applyPlanScheduleToJournal(
      journal: journal,
      startDateKey: '2026-11-01',
      planName: 'Three-Day Plan',
      workouts: workouts,
      confirmConflict: (_) async => true,
    );
    expect(count, 3);

    final day1 = await journal.getDay('2026-11-01');
    final day2 = await journal.getDay('2026-11-02');
    final day3 = await journal.getDay('2026-11-03');
    final untouched = await journal.getDay('2026-10-10');

    expect(day1?.workoutName, 'Day 1');
    expect(day1?.planName, 'Three-Day Plan');
    expect(day1?.exercises.single.name, 'Bench');
    expect(day2?.workoutName, 'Day 2');
    expect(day3?.workoutName, 'Day 3');
    expect(untouched?.exercises.single.sets.last.weight, '225');
  });
}
