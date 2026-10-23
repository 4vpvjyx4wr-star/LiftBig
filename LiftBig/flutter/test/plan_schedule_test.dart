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

  test('catalog supersets are stored on the scheduled day', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(() => journal.db.close());

    final workout = CatalogWorkout(
      id: 'joey-c4',
      name: 'Joey C4',
      folderId: 'joey',
      notes: '',
      lifts: [
        CatalogLift(
          name: 'Incline Press',
          libraryId: 'incline',
          isCardio: false,
          isCore: false,
          isCircuit: false,
          targetDuration: null,
          sets: [CatalogSet(reps: '8', weight: '55')],
          supersetGroupId: 'joey-c4-ss-a',
          supersetLabel: 'A',
          supersetOrder: 1,
        ),
        CatalogLift(
          name: 'Lateral Raise',
          libraryId: 'raise',
          isCardio: false,
          isCore: false,
          isCircuit: false,
          targetDuration: null,
          sets: [CatalogSet(reps: '12', weight: '15')],
          supersetGroupId: 'joey-c4-ss-a',
          supersetLabel: 'A',
          supersetOrder: 2,
        ),
      ],
    );

    await applyPlanScheduleToJournal(
      journal: journal,
      startDateKey: '2026-11-04',
      planName: 'Joey C4',
      workouts: [workout],
      confirmConflict: (_) async => true,
    );

    final day = await journal.getDay('2026-11-04');
    expect(day?.planName, 'Joey C4');
    expect(day?.exercises.map((exercise) => exercise.supersetGroupId).toList(), [
      'joey-c4-ss-a',
      'joey-c4-ss-a',
    ]);
    expect(day?.exercises.map((exercise) => exercise.supersetOrder).toList(), [1, 2]);
  });

  test('calendarPlanName prefers today, then the next scheduled plan', () {
    const days = [
      (dateKey: '2026-10-20', planName: 'Old Plan'),
      (dateKey: '2026-10-22', planName: 'Joey C4'),
      (dateKey: '2026-10-25', planName: 'Later Plan'),
    ];
    expect(calendarPlanName(days, '2026-10-22'), 'Joey C4');
    expect(calendarPlanName(days.where((day) => day.dateKey != '2026-10-22'), '2026-10-22'), 'Later Plan');
    expect(calendarPlanName(const [(dateKey: '2026-10-01', planName: 'Only Past')], '2026-10-22'), 'Only Past');
  });
}
