import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/backup/backup_parser.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/date_key.dart';
import 'package:liftbig/journal/journal_repository.dart';
import 'package:liftbig/journal/logged_day.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/sync/day_remote.dart';
import 'package:liftbig/sync/journal_sync.dart';

JournalDay sampleDay({
  String dateKey = '2026-10-01',
  String updatedAt = '2026-10-01T10:00:00.000Z',
  String weight = '135',
}) {
  return JournalDay(
    dateKey: dateKey,
    updatedAt: updatedAt,
    workoutName: 'Push A',
    planName: 'Strength',
    notes: 'solid',
    exercises: [
      JournalExercise(
        id: 'ex1',
        sortOrder: 0,
        name: 'Bench Press',
        sets: [
          JournalSet(
            id: 'warm',
            sortOrder: 0,
            reps: '8',
            weight: '95',
            isWarmup: true,
          ),
          JournalSet(id: 'work', sortOrder: 1, reps: '5', weight: weight),
        ],
      ),
    ],
  );
}

class MemoryRemote implements DayRemote {
  final Map<String, JournalDay> days = {};
  CloudSettings? settings;

  @override
  Future<Map<String, JournalDay>> fetchDays() async => Map.of(days);

  @override
  Future<CloudSettings?> fetchSettings() async => settings;

  @override
  Future<void> putDay(JournalDay day) async {
    days[day.dateKey] = day;
  }

  @override
  Future<void> putSettings(CloudSettings value) async {
    settings = value;
  }
}

void main() {
  test('import writes workouts and they survive a database reopen', () async {
    final file = File(
      '${Directory.systemTemp.path}/liftbig-journal-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final backup = jsonEncode({
      'exportedAt': '2026-10-03T12:00:00.000Z',
      'liftbig_local_storage': {
        'liftbig_workouts': jsonEncode({
          '2026-10-01': {
            'exercises': [
              {
                'id': 'ex1',
                'name': 'Bench Press',
                'sets': [
                  {'id': 'warm', 'reps': '8', 'weight': '95', 'isWarmup': true},
                  {'id': 'work', 'reps': '5', 'weight': '185'},
                ],
              },
            ],
            'notes': 'push',
            'planName': 'Push A',
            'planFolderName': 'Strength',
            'planNotes': 'week 1',
          },
          '2026-10-02': {'exercises': [], 'isRestDay': true},
        }),
        'liftbig_day_stamps': jsonEncode({
          '2026-10-01': '2026-10-01T15:00:00.000Z',
        }),
        'liftbig_templates': '[]',
        'liftbig_settings': jsonEncode({
          'weightUnit': 'lb',
          'bodyWeightLbs': 180,
        }),
      },
    });

    final first = JournalRepository(AppDatabase(NativeDatabase(file)));
    final count = await first.importBackup(parseLiftBigBackup(backup));
    expect(count, 2);
    expect(await first.isSyncEnabled(), isFalse);
    await first.db.close();

    final second = JournalRepository(AppDatabase(NativeDatabase(file)));
    final day = await second.getDay('2026-10-01');
    expect(day, isNotNull);
    expect(day!.workoutName, 'Push A');
    expect(day.planName, 'Strength');
    expect(day.workoutNotes, 'week 1');
    expect(day.notes, 'push');
    expect(day.updatedAt, '2026-10-01T15:00:00.000Z');
    expect(day.exercises.single.sets.first.isWarmup, isTrue);
    expect(day.exercises.single.sets.first.weight, '95');
    expect(day.exercises.single.sets.last.weight, '185');
    final rest = await second.getDay('2026-10-02');
    expect(rest!.isRestDay, isTrue);
    expect(await second.isSyncEnabled(), isFalse);
    final settings = await second.localCloudSettings();
    expect(settings!.weightUnit, 'lb');
    expect(settings.bodyWeightLbs, 180);
    await second.db.close();
    await file.delete();
  });

  test('imports a large multi-year backup through the parser', () async {
    const dayCount = 500;
    const names = ['Squat', 'Bench Press', 'Row', 'Deadlift'];
    final start = DateTime.utc(2023, 1, 1);
    final workouts = <String, Object?>{};
    final stamps = <String, String>{};
    for (var i = 0; i < dayCount; i++) {
      final date = start.add(Duration(days: i));
      final key = toDateKey(date);
      final weight = (135 + (i % 80)).toString();
      workouts[key] = {
        'notes': 'session $i',
        'planName': i.isEven ? 'Push' : 'Pull',
        'exercises': [
          for (final name in names)
            {
              'id': '$name-$i',
              'name': name,
              'notes': 'work',
              'sets': [
                {
                  'id': '$name-$i-w',
                  'reps': '5',
                  'weight': '95',
                  'isWarmup': true,
                },
                {'id': '$name-$i-1', 'reps': '5', 'weight': weight},
                {'id': '$name-$i-2', 'reps': '3', 'weight': weight},
              ],
            },
        ],
      };
      stamps[key] = date.toIso8601String();
    }
    final backup = jsonEncode({
      'formatVersion': 2,
      'exportedAt': '2026-10-14T12:00:00.000Z',
      'app': 'liftbig',
      'liftbig_local_storage': {
        'liftbig_workouts': jsonEncode(workouts),
        'liftbig_day_stamps': jsonEncode(stamps),
        'liftbig_templates': jsonEncode([
          {'id': 't1', 'name': 'Push', 'exercises': []},
        ]),
        'liftbig_settings': jsonEncode({
          'weightUnit': 'lb',
          'bodyWeightLbs': 190,
        }),
      },
    });
    expect(backup.length, greaterThan(200000));

    final parsed = parseLiftBigBackup(backup);
    expect(parsed.days, hasLength(dayCount));
    expect(parsed.skippedDays, 0);
    expect(parsed.days.first.dateKey, '2023-01-01');
    expect(
      parsed.days.last.dateKey,
      toDateKey(start.add(const Duration(days: dayCount - 1))),
    );
    expect(parsed.weightUnit, 'lb');
    expect(parsed.bodyWeightLbs, 190);

    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    await journal.replaceDay(sampleDay(dateKey: '2019-06-01', weight: '45'));

    final count = await journal.importBackup(parsed);
    expect(count, dayCount);

    final first = await journal.getDay('2023-01-01');
    expect(first!.workoutName, 'Push');
    expect(first.notes, 'session 0');
    expect(first.updatedAt, start.toIso8601String());
    expect(first.exercises, hasLength(names.length));
    expect(first.exercises.first.name, 'Squat');
    expect(first.exercises.first.sets.first.isWarmup, isTrue);
    expect(first.exercises.first.sets.first.weight, '95');
    expect(first.exercises.first.sets.last.weight, '135');

    final mid = await journal.getDay(
      toDateKey(start.add(const Duration(days: 200))),
    );
    expect(mid!.workoutName, 'Push');
    expect(mid.exercises, hasLength(names.length));
    expect(mid.exercises.last.sets.last.weight, '${135 + (200 % 80)}');

    final lastKey = toDateKey(start.add(const Duration(days: dayCount - 1)));
    final last = await journal.getDay(lastKey);
    expect(last!.notes, 'session ${dayCount - 1}');
    expect(last.workoutName, 'Pull');
    expect(
      last.exercises
          .singleWhere((exercise) => exercise.name == 'Deadlift')
          .sets
          .last
          .weight,
      '${135 + ((dayCount - 1) % 80)}',
    );

    final kept = await journal.getDay('2019-06-01');
    expect(kept!.exercises.single.sets.last.weight, '45');
    final settings = await journal.localCloudSettings();
    expect(settings!.weightUnit, 'lb');
    expect(settings.bodyWeightLbs, 190);
    expect(settings.templatesJson, contains('Push'));
  });

  test('logging a set updates the day and clears rest', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);

    expect(await journal.setRestDay('2026-10-14', rest: true), isTrue);
    await journal.addExercise(
      dateKey: '2026-10-14',
      name: 'Deadlift',
      sets: [const JournalSet(id: '', sortOrder: 0, reps: '3', weight: '315')],
    );

    final day = await journal.getDay('2026-10-14');
    expect(day!.isRestDay, isFalse);
    expect(day.exercises.single.name, 'Deadlift');
    expect(day.exercises.single.sets.single.reps, '3');
    expect(day.exercises.single.sets.single.weight, '315');
    expect(await journal.setRestDay('2026-10-14', rest: true), isFalse);
  });

  test('sync keeps the newer day on each side', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);
    await journal.replaceDay(
      sampleDay(weight: '185', updatedAt: '2026-10-01T12:00:00.000Z'),
    );
    await journal.replaceDay(
      JournalDay(
        dateKey: '2026-10-04',
        updatedAt: '2026-10-04T08:00:00.000Z',
        isRestDay: true,
        exercises: const [],
      ),
    );

    final remote = MemoryRemote()
      ..days['2026-10-01'] = sampleDay(
        weight: '135',
        updatedAt: '2026-10-01T09:00:00.000Z',
      )
      ..days['2026-10-05'] = sampleDay(
        dateKey: '2026-10-05',
        weight: '225',
        updatedAt: '2026-10-05T18:00:00.000Z',
      );

    final result = await JournalSync(journal: journal, remote: remote).sync();
    expect(result.uploaded, greaterThan(0));
    expect(result.downloaded, 1);

    final localBench = await journal.getDay('2026-10-01');
    expect(localBench!.exercises.single.sets.last.weight, '185');
    expect(remote.days['2026-10-01']!.exercises.single.sets.last.weight, '185');
    expect(
      (await journal.getDay('2026-10-05'))!.exercises.single.sets.last.weight,
      '225',
    );
    expect(remote.days.containsKey('2026-10-04'), isTrue);
  });

  test(
    'second exercise, set edits, and set deletes survive a database reopen',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/liftbig-day-log-${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      final first = JournalRepository(AppDatabase(NativeDatabase(file)));

      await first.addExercise(
        dateKey: '2026-10-14',
        name: 'Bench Press',
        sets: const [
          JournalSet(
            id: 'bench-1',
            sortOrder: 0,
            reps: '5',
            weight: '135',
            durationSeconds: '30',
          ),
        ],
      );
      await first.addExercise(
        dateKey: '2026-10-14',
        name: 'Squat',
        sets: const [
          JournalSet(id: 'squat-1', sortOrder: 0, reps: '5', weight: '225'),
          JournalSet(id: 'squat-2', sortOrder: 1, reps: '3', weight: '245'),
        ],
      );

      final created = await first.getDay('2026-10-14');
      expect(created!.exercises.map((exercise) => exercise.name), [
        'Bench Press',
        'Squat',
      ]);
      final added = await first.addSet(created.exercises.first.id);
      await first.updateSet(added.id, reps: '8', weight: '155');
      await first.updateSet('bench-1', checked: true, isWarmup: true);
      await first.updateSet('bench-1', reps: '6');
      await first.deleteSet('squat-2');

      final edited = await first.getDay('2026-10-14');
      final bench = edited!.exercises.first;
      expect(bench.sets, hasLength(2));
      expect(bench.sets.first.id, 'bench-1');
      expect(bench.sets.first.reps, '6');
      expect(bench.sets.first.weight, '135');
      expect(bench.sets.first.durationSeconds, '30');
      expect(bench.sets.first.checked, isTrue);
      expect(bench.sets.first.isWarmup, isTrue);
      expect(bench.sets.last.id, added.id);
      expect(bench.sets.last.reps, '8');
      expect(bench.sets.last.weight, '155');
      expect(bench.sets.last.checked, isFalse);
      expect(bench.sets.last.isWarmup, isFalse);
      final squat = edited.exercises.last;
      expect(squat.name, 'Squat');
      expect(squat.sets, hasLength(1));
      expect(squat.sets.single.id, 'squat-1');
      expect(squat.sets.single.reps, '5');
      expect(squat.sets.single.weight, '225');
      await first.db.close();

      final second = JournalRepository(AppDatabase(NativeDatabase(file)));
      final reopened = await second.getDay('2026-10-14');
      expect(reopened!.exercises, hasLength(2));
      expect(reopened.exercises.first.name, 'Bench Press');
      expect(reopened.exercises.first.sets.first.reps, '6');
      expect(reopened.exercises.first.sets.first.weight, '135');
      expect(reopened.exercises.first.sets.first.durationSeconds, '30');
      expect(reopened.exercises.first.sets.first.checked, isTrue);
      expect(reopened.exercises.first.sets.first.isWarmup, isTrue);
      expect(reopened.exercises.first.sets.last.weight, '155');
      expect(reopened.exercises.last.name, 'Squat');
      expect(reopened.exercises.last.sets.single.id, 'squat-1');

      await second.deleteExercise(reopened.exercises.last.id);
      final afterDelete = await second.getDay('2026-10-14');
      expect(afterDelete!.exercises.single.name, 'Bench Press');
      expect(afterDelete.exercises.single.sets, hasLength(2));
      expect(afterDelete.exercises.single.sets.first.weight, '135');
      await second.db.close();
      await file.delete();
    },
  );

  test('schema v2 copies the old plan columns onto the new names', () async {
    final probe = AppDatabase(NativeDatabase.memory());
    final rows = await probe
        .customSelect(
          "SELECT type, name, sql FROM sqlite_master WHERE sql IS NOT NULL",
        )
        .get();
    await probe.close();

    final tables = <String, String>{};
    final indexes = <String>[];
    for (final row in rows) {
      final sql = row.read<String>('sql');
      if (row.read<String>('type') == 'index') {
        indexes.add(sql);
      } else if (row.read<String>('type') == 'table') {
        tables[row.read<String>('name')] = sql;
      }
    }
    final daysSql = tables.remove('days');
    expect(daysSql, isNotNull);
    final v1Days = daysSql!
        .replaceAll(', "chosen_rest_seconds" INTEGER NULL', '')
        .replaceAll(', "health_energy_kcal" REAL NULL', '')
        .replaceAll('workout_notes', 'plan_notes')
        .replaceAll('workout_name', '@@session@@')
        .replaceAll('plan_name', 'plan_folder_name')
        .replaceAll('@@session@@', 'plan_name');

    final file = File(
      '${Directory.systemTemp.path}/liftbig-migrate-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final journal = JournalRepository(
      AppDatabase(
        NativeDatabase(
          file,
          setup: (database) {
            final existing = database.select(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'days'",
            );
            if (existing.isNotEmpty) return;
            database.execute(v1Days);
            for (final name in ['exercises', 'sets', 'local_settings']) {
              var sql = tables[name]!;
              if (name == 'sets') {
                // v1 predates per-set difficulty. The v3 migration adds it.
                sql = sql.replaceAll(', "difficulty" TEXT NULL', '');
              }
              if (name == 'exercises') {
                // v1 predates goal snapshots. The v4 migration adds them.
                sql = sql
                    .replaceAll(', "prescribed_reps" TEXT NULL', '')
                    .replaceAll(', "prescribed_weight" TEXT NULL', '')
                    .replaceAll(', "prescribed_set_count" INTEGER NULL', '');
              }
              database.execute(sql);
            }
            for (final index in indexes) {
              database.execute(index);
            }
            database.execute(
              "INSERT INTO days (date_key, notes, is_rest_day, plan_name, "
              "plan_folder_name, plan_notes, updated_at) VALUES "
              "('2026-04-01', 'push', 0, 'Push A', 'Strength', 'week 1', "
              "'2026-04-01T12:00:00.000Z')",
            );
            database.userVersion = 1;
          },
        ),
      ),
    );
    addTearDown(() async {
      await journal.db.close();
      await file.delete();
    });

    final day = await journal.getDay('2026-04-01');
    expect(day!.workoutName, 'Push A');
    expect(day.planName, 'Strength');
    expect(day.workoutNotes, 'week 1');
    expect(day.notes, 'push');

    final columns = await journal.db.customSelect('PRAGMA table_info(days)').get();
    final names = columns.map((row) => row.read<String>('name')).toSet();
    expect(names, containsAll(['workout_name', 'plan_name', 'workout_notes']));
    expect(names, isNot(contains('plan_folder_name')));
    expect(names, isNot(contains('plan_notes')));
  });

  test('day header, rest day, special exercises, order, copy, and move', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(journal.db.close);

    await journal.updateDayHeader(
      '2026-05-01',
      notes: 'easy day',
      workoutName: 'Push A',
      setNotes: true,
      setWorkoutName: true,
    );
    expect(await journal.setRestDay('2026-05-01', rest: true), isTrue);

    final header = await journal.getDay('2026-05-01');
    expect(header!.notes, 'easy day');
    expect(header.workoutName, 'Push A');
    expect(header.isRestDay, isTrue);

    await journal.replaceDay(
      JournalDay(
        dateKey: '2026-05-02',
        updatedAt: '2026-05-02T12:00:00.000Z',
        workoutName: 'Conditioning',
        planName: 'Strength',
        workoutNotes: 'keep moving',
        exercises: [
          JournalExercise(
            id: 'run',
            sortOrder: 0,
            name: 'Run',
            isCardio: true,
            targetDuration: '30',
            targetDistance: '3',
            loggedCalories: '240',
            targetRestSeconds: 45,
            sets: const [
              JournalSet(id: 'run-1', sortOrder: 0, reps: '28', weight: '2.5'),
            ],
          ),
          JournalExercise(
            id: 'plank',
            sortOrder: 1,
            name: 'Plank',
            isCore: true,
            targetTimeSeconds: '45',
            targetReps: '1',
            sets: const [
              JournalSet(
                id: 'plank-1',
                sortOrder: 0,
                reps: '1',
                weight: '',
                durationSeconds: '40',
              ),
            ],
          ),
          JournalExercise(
            id: 'circuit',
            sortOrder: 2,
            name: 'Finisher',
            isCircuit: true,
            targetReps: '12',
            sets: const [
              JournalSet(id: 'c1', sortOrder: 0, reps: '12', weight: '25'),
              JournalSet(id: 'c2', sortOrder: 1, reps: '10', weight: '25'),
            ],
          ),
          JournalExercise(
            id: 'press',
            sortOrder: 3,
            name: 'Press',
            supersetGroupId: 'ss-1',
            supersetLabel: 'A',
            supersetOrder: 1,
            sets: const [
              JournalSet(id: 'p1', sortOrder: 0, reps: '8', weight: '95'),
            ],
          ),
          JournalExercise(
            id: 'row',
            sortOrder: 4,
            name: 'Row',
            supersetGroupId: 'ss-1',
            supersetLabel: 'A',
            supersetOrder: 2,
            sets: const [
              JournalSet(id: 'r1', sortOrder: 0, reps: '8', weight: '85'),
            ],
          ),
        ],
      ),
    );

    final logged = await journal.getDay('2026-05-02');
    expect(logged!.workoutName, 'Conditioning');
    expect(logged.exercises.map((exercise) => exercise.name), [
      'Run',
      'Plank',
      'Finisher',
      'Press',
      'Row',
    ]);
    expect(logged.exercises[0].isCardio, isTrue);
    expect(logged.exercises[0].targetDuration, '30');
    expect(logged.exercises[0].sets.single.reps, '28');
    expect(logged.exercises[0].targetRestSeconds, 45);
    expect(logged.exercises[1].isCore, isTrue);
    expect(logged.exercises[1].sets.single.durationSeconds, '40');
    expect(logged.exercises[2].isCircuit, isTrue);
    expect(logged.exercises[3].supersetGroupId, 'ss-1');
    expect(logged.exercises[4].supersetOrder, 2);

    await journal.reorderExercises('2026-05-02', [
      'press',
      'row',
      'run',
      'plank',
      'circuit',
    ]);
    await journal.reorderSets('circuit', ['c2', 'c1']);
    final reordered = await journal.getDay('2026-05-02');
    expect(reordered!.exercises.map((exercise) => exercise.id), [
      'press',
      'row',
      'run',
      'plank',
      'circuit',
    ]);
    expect(reordered.exercises.last.sets.map((set) => set.id), ['c2', 'c1']);

    expect(await journal.copyDay('2026-05-02', '2026-05-03'), isTrue);
    final copied = await journal.getDay('2026-05-03');
    expect(copied!.exercises.map((exercise) => exercise.name), [
      'Press',
      'Row',
      'Run',
      'Plank',
      'Finisher',
    ]);
    expect(copied.workoutName, isNull);
    expect(copied.exercises.first.sets.single.reps, isEmpty);
    expect(copied.exercises.first.sets.single.weight, isEmpty);
    final copiedCircuit = copied.exercises.last;
    expect(copiedCircuit.isCircuit, isTrue);
    expect(copiedCircuit.sets.first.reps, '10');
    expect(copiedCircuit.sets.first.checked, isFalse);
    final sourceStill = await journal.getDay('2026-05-02');
    expect(sourceStill!.exercises.first.name, 'Press');
    expect(sourceStill.exercises.first.sets.single.weight, '95');

    expect(await journal.moveDay('2026-05-02', '2026-05-04'), 'moved');
    expect(await journal.getDay('2026-05-02'), isNull);
    final moved = await journal.getDay('2026-05-04');
    expect(moved!.workoutName, 'Conditioning');
    expect(moved.planName, 'Strength');
    expect(moved.workoutNotes, 'keep moving');
    expect(moved.exercises.first.id, 'press');

    expect(await journal.moveDay('2026-05-04', '2026-05-03'), 'swapped');
    final back = await journal.getDay('2026-05-04');
    expect(back!.exercises.first.name, 'Press');
    expect(back.exercises.first.sets.single.reps, isEmpty);
    final swapped = await journal.getDay('2026-05-03');
    expect(swapped!.workoutName, 'Conditioning');
    expect(swapped.exercises.first.sets.single.weight, '95');

    final groups = groupExercisesForDisplay(swapped.exercises);
    expect(groups.first.map((exercise) => exercise.name), ['Press', 'Row']);
    expect(
      startsRestAfterSet(groups.first.first, swapped.exercises),
      isFalse,
    );
    expect(startsRestAfterSet(groups.first.last, swapped.exercises), isTrue);
    expect(
      restSecondsForExercise(
        swapped.exercises.firstWhere((exercise) => exercise.name == 'Run'),
        averageRestSeconds: 60,
      ),
      45,
    );
  });

  test('auto-fill defaults on and timer-on-done defaults off', () async {
    final file = File(
      '${Directory.systemTemp.path}/liftbig-logging-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final first = JournalRepository(AppDatabase(NativeDatabase(file)));
    expect(await first.autoFillSetsEnabled(), isTrue);
    expect(await first.startTimerOnDone(), isFalse);
    expect(await first.logSetDifficultyEnabled(), isFalse);

    await first.addExercise(
      dateKey: '2026-01-01',
      name: 'Bench Press',
      sets: const [
        JournalSet(
          id: 'warm',
          sortOrder: 0,
          reps: '5',
          weight: '300',
          isWarmup: true,
        ),
        JournalSet(id: 'work', sortOrder: 1, reps: '8', weight: '100'),
      ],
    );
    await first.addExercise(
      dateKey: '2026-01-08',
      name: 'Bench Press',
      sets: const [],
    );
    final created = await first.getDay('2026-01-08');
    // The new lift starts with one empty row. Add set copies that row.
    final filled = await first.addSet(created!.exercises.single.id);
    expect(filled.weight, isEmpty);
    expect(filled.reps, isEmpty);

    await first.setAutoFillSetsEnabled(false);
    final blank = await first.addSet(created.exercises.single.id);
    expect(blank.weight, isEmpty);
    expect(blank.reps, isEmpty);
    await first.setAutoFillSetsEnabled(true);
    // Starter row plus the two sets added above are still empty.
    expect(await first.prefillEmptySets('2026-01-08'), 3);
    final prefilled = await first.getDay('2026-01-08');
    expect(prefilled!.exercises.single.sets, hasLength(3));
    for (final set in prefilled.exercises.single.sets) {
      expect(set.weight, '102.5');
      expect(set.reps, '6');
    }

    await first.addExercise(
      dateKey: '2026-02-01',
      name: 'Curl',
      sets: const [
        JournalSet(
          id: 'curl-warm',
          sortOrder: 0,
          reps: '10',
          weight: '50',
          isWarmup: true,
        ),
      ],
    );
    await first.addExercise(
      dateKey: '2026-02-08',
      name: 'Curl',
      sets: const [],
    );
    final curlDay = await first.getDay('2026-02-08');
    final curlSet = await first.addSet(curlDay!.exercises.single.id);
    expect(curlSet.weight, isEmpty);
    expect(curlSet.reps, isEmpty);
    expect(await first.prefillEmptySets('2026-02-08'), 2);
    final curlFilled = await first.getDay('2026-02-08');
    for (final set in curlFilled!.exercises.single.sets) {
      expect(set.weight, isNotEmpty);
      expect(set.reps, '12');
    }

    await first.updateSet('work', difficulty: 'Easy', setDifficulty: true);
    final rated = await first.getDay('2026-01-01');
    expect(rated!.exercises.single.sets.last.difficulty, 'Easy');
    await first.updateSet('work', setDifficulty: true);
    final cleared = await first.getDay('2026-01-01');
    expect(cleared!.exercises.single.sets.last.difficulty, isNull);

    await first.setAutoFillSetsEnabled(false);
    await first.setStartTimerOnDone(true);
    await first.setLogSetDifficultyEnabled(true);
    await first.db.close();

    final second = JournalRepository(AppDatabase(NativeDatabase(file)));
    expect(await second.autoFillSetsEnabled(), isFalse);
    expect(await second.startTimerOnDone(), isTrue);
    expect(await second.logSetDifficultyEnabled(), isTrue);
    await second.db.close();
    if (file.existsSync()) file.deleteSync();
  });

  test('mergeExerciseNameVariants renames every matching log entry', () async {
    final file = File(
      '${Directory.systemTemp.path}/liftbig-merge-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final journal = JournalRepository(AppDatabase(NativeDatabase(file)));
    await journal.addExercise(
      dateKey: '2026-03-01',
      name: 'bench press',
      sets: const [],
    );
    await journal.addExercise(
      dateKey: '2026-03-02',
      name: 'Bench  Press',
      sets: const [],
    );
    await journal.addExercise(
      dateKey: '2026-03-02',
      name: 'Squat',
      sets: const [],
    );
    final updated = await journal.mergeExerciseNameVariants(
      key: 'bench press',
      canonicalName: 'Bench Press',
      libraryId: 'bench-press',
    );
    expect(updated, 2);
    expect(
      (await journal.getDay('2026-03-01'))!.exercises.single.name,
      'Bench Press',
    );
    expect(
      (await journal.getDay('2026-03-01'))!.exercises.single.libraryId,
      'bench-press',
    );
    final second = (await journal.getDay('2026-03-02'))!.exercises;
    expect(second.map((exercise) => exercise.name), ['Bench Press', 'Squat']);
    await journal.db.close();
    if (file.existsSync()) file.deleteSync();
  });

  test('favorite plans survive a database reopen', () async {
    final file = File(
      '${Directory.systemTemp.path}/liftbig-favorites-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final first = JournalRepository(AppDatabase(NativeDatabase(file)));
    expect(await first.favoritePlanIds(), isEmpty);
    await first.saveFavoritePlanIds([' push ', 'pull', 'push', '']);
    expect(await first.favoritePlanIds(), {'push', 'pull'});
    await first.saveFavoritePlanIds(['pull']);
    await first.db.close();

    final second = JournalRepository(AppDatabase(NativeDatabase(file)));
    expect(await second.favoritePlanIds(), {'pull'});
    await second.db.close();
    if (file.existsSync()) file.deleteSync();
  });
}
