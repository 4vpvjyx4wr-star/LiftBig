import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/backup/backup_parser.dart';
import 'package:liftbig/model/journal_day.dart';

void main() {
  test('reads workouts from liftbig_local_storage and keeps pounds', () {
    const workouts = {
      '2026-10-01': {
        'exercises': [
          {
            'id': 'ex1',
            'name': 'Bench Press',
            'notes': 'felt good',
            'libraryId': 'bench',
            'preferredSwapLibraryIds': ['db-bench'],
            'sets': [
              {
                'id': 's1',
                'reps': '8',
                'weight': '95',
                'isWarmup': true,
              },
              {'id': 's2', 'reps': '5', 'weight': '185', 'difficulty': 'Moderate'},
            ],
          },
        ],
        'notes': 'push',
        'isRestDay': false,
        'planName': 'Push A',
        'planFolderName': 'Strength',
        'planNotes': 'week 1',
      },
      '2026-10-02': {
        'exercises': [],
        'isRestDay': true,
      },
    };
    final backup = jsonEncode({
      'formatVersion': 2,
      'exportedAt': '2026-10-03T12:00:00.000Z',
      'app': 'liftbig',
      'liftbig_local_storage': {
        'liftbig_workouts': jsonEncode(workouts),
        'liftbig_day_stamps': jsonEncode({
          '2026-10-01': '2026-10-01T15:00:00.000Z',
          '2026-10-02': '2026-10-02T08:00:00.000Z',
        }),
        'liftbig_templates': jsonEncode([
          {'id': 't1', 'name': 'Push A', 'exercises': []},
        ]),
        'liftbig_settings': jsonEncode({
          'weightUnit': 'lb',
          'bodyWeightLbs': 180,
        }),
      },
    });

    final parsed = parseLiftBigBackup(backup);
    expect(parsed.days, hasLength(2));
    final push = parsed.days.first;
    expect(push.dateKey, '2026-10-01');
    expect(push.workoutName, 'Push A');
    expect(push.planName, 'Strength');
    expect(push.workoutNotes, 'week 1');
    expect(push.notes, 'push');
    expect(push.updatedAt, '2026-10-01T15:00:00.000Z');
    expect(push.exercises.single.notes, 'felt good');
    expect(push.exercises.single.preferredSwapLibraryIds, ['db-bench']);
    expect(push.exercises.single.sets.first.isWarmup, isTrue);
    expect(push.exercises.single.sets.first.difficulty, isNull);
    expect(push.exercises.single.sets.last.difficulty, 'Moderate');
    expect(push.exercises.single.sets.first.weight, '95');
    expect(push.exercises.single.sets.last.weight, '185');
    expect(push.exercises.single.sets.last.reps, '5');
    expect(parsed.days.last.isRestDay, isTrue);
    expect(parsed.days.last.exercises, isEmpty);
    expect(parsed.weightUnit, 'lb');
    expect(parsed.bodyWeightLbs, 180);
    expect(parsed.templatesJson, contains('Push A'));
  });

  test('accepts typed liftbig_workouts without the storage bundle', () {
    final parsed = parseLiftBigBackup(
      jsonEncode({
        'liftbig_workouts': {
          '2026-09-01': [
            {
              'id': 'ex',
              'name': 'Squat',
              'sets': [
                {'id': 's', 'reps': '3', 'weight': '225'},
              ],
            },
          ],
        },
        'liftbig_templates': [],
        'liftbig_settings': {'weightUnit': 'kg'},
      }),
    );

    expect(parsed.days.single.exercises.single.name, 'Squat');
    expect(parsed.days.single.exercises.single.sets.single.weight, '225');
    expect(parsed.days.single.workoutName, isNull);
    expect(parsed.days.single.planName, isNull);
    expect(parsed.weightUnit, 'kg');
  });

  test('reads a backup wrapped in data', () {
    final parsed = parseLiftBigBackup(
      jsonEncode({
        'data': {
          'liftbig_workouts': {
            '2026-08-15': {
              'exercises': [
                {
                  'id': 'ex',
                  'name': 'Row',
                  'sets': [
                    {'reps': 10, 'weight': 135},
                  ],
                },
              ],
              'planName': 'Pull',
            },
          },
        },
      }),
    );

    expect(parsed.days.single.workoutName, 'Pull');
    expect(parsed.days.single.planName, isNull);
    expect(parsed.days.single.exercises.single.sets.single.reps, '10');
    expect(parsed.days.single.exercises.single.sets.single.weight, '135');
  });

  test('rejects JSON that is not a LiftBig backup', () {
    expect(
      () => parseLiftBigBackup('{"hello":1}'),
      throwsA(
        isA<BackupParseException>().having(
          (error) => error.message,
          'message',
          contains('liftbig_workouts'),
        ),
      ),
    );
    expect(() => parseLiftBigBackup('not json'), throwsA(isA<BackupParseException>()));
  });

  test('round-trips prescriptions, per-day rest, and day stamps', () {
    const stamp = '2026-10-01T15:00:00.000Z';
    const exportedAt = '2026-10-03T12:00:00.000Z';
    const day = JournalDay(
      dateKey: '2026-10-01',
      updatedAt: stamp,
      notes: 'push',
      workoutName: 'Push A',
      planName: 'Strength',
      workoutNotes: 'week 1',
      chosenRestSeconds: 90,
      exercises: [
        JournalExercise(
          id: 'ex1',
          sortOrder: 0,
          name: 'Bench Press',
          targetReps: '5',
          targetWeight: '185',
          targetRestSeconds: 120,
          prescribedReps: '8-12',
          prescribedWeight: '135',
          prescribedSetCount: 3,
          sets: [
            JournalSet(
              id: 's1',
              sortOrder: 0,
              reps: '5',
              weight: '185',
            ),
          ],
        ),
      ],
    );

    final encoded = encodeLiftBigBackup(
      days: [day],
      templatesJson: '[]',
      settingsJson: '{"weightUnit":"lb"}',
      weightUnit: 'lb',
      now: DateTime.utc(2026, 10, 3, 12),
    );
    final raw = jsonDecode(encoded) as Map<String, dynamic>;
    expect(raw['exportedAt'], exportedAt);
    expect(raw['liftbig_day_stamps'], {'2026-10-01': stamp});
    final workouts = raw['liftbig_workouts'] as Map<String, dynamic>;
    final stored = workouts['2026-10-01'] as Map<String, dynamic>;
    expect(stored['chosenRestSeconds'], 90);
    expect(stored['updatedAt'], stamp);
    final exercise = (stored['exercises'] as List).single as Map<String, dynamic>;
    expect(exercise['prescribedReps'], '8-12');
    expect(exercise['prescribedWeight'], '135');
    expect(exercise['prescribedSetCount'], 3);
    expect(exercise['targetRestSeconds'], 120);

    final parsed = parseLiftBigBackup(encoded);
    final back = parsed.days.single;
    expect(back.updatedAt, stamp);
    expect(back.updatedAt, isNot(exportedAt));
    expect(back.chosenRestSeconds, 90);
    expect(back.notes, 'push');
    expect(back.workoutName, 'Push A');
    expect(back.planName, 'Strength');
    final lift = back.exercises.single;
    expect(lift.prescribedReps, '8-12');
    expect(lift.prescribedWeight, '135');
    expect(lift.prescribedSetCount, 3);
    expect(lift.targetRestSeconds, 120);
    expect(lift.targetReps, '5');
    expect(lift.targetWeight, '185');
    expect(lift.sets.single.weight, '185');
  });

  test('reads a day stamp written on the day when the stamp map is absent', () {
    final parsed = parseLiftBigBackup(
      jsonEncode({
        'exportedAt': '2026-10-03T12:00:00.000Z',
        'liftbig_workouts': {
          '2026-09-01': {
            'updatedAt': '2026-09-01T09:00:00.000Z',
            'chosenRestSeconds': 75,
            'exercises': [
              {
                'id': 'ex',
                'name': 'Squat',
                'prescribedReps': '5',
                'prescribedWeight': '225',
                'prescribedSetCount': 4,
                'sets': [
                  {'id': 's', 'reps': '3', 'weight': '245'},
                ],
              },
            ],
          },
        },
      }),
    );

    final day = parsed.days.single;
    expect(day.updatedAt, '2026-09-01T09:00:00.000Z');
    expect(day.chosenRestSeconds, 75);
    expect(day.exercises.single.prescribedReps, '5');
    expect(day.exercises.single.prescribedWeight, '225');
    expect(day.exercises.single.prescribedSetCount, 4);
  });

  test('falls back to exportedAt only when a day has no stamp', () {
    final parsed = parseLiftBigBackup(
      jsonEncode({
        'exportedAt': '2026-10-03T12:00:00.000Z',
        'liftbig_workouts': {
          '2026-09-01': {
            'exercises': [
              {
                'id': 'ex',
                'name': 'Squat',
                'sets': [
                  {'id': 's', 'reps': '3', 'weight': '225'},
                ],
              },
            ],
          },
        },
      }),
    );

    expect(parsed.days.single.updatedAt, '2026-10-03T12:00:00.000Z');
  });

  test('drops backup days that are not newer than the local copy', () {
    final parsed = parseLiftBigBackup(
      jsonEncode({
        'exportedAt': '2026-10-04T12:00:00.000Z',
        'liftbig_day_stamps': {
          '2026-10-01': '2026-10-01T10:00:00.000Z',
          '2026-10-02': '2026-10-02T08:00:00.000Z',
          '2026-10-03': '2026-10-03T18:00:00.000Z',
          '2026-10-04': '2026-10-04T09:00:00.000Z',
        },
        'liftbig_workouts': {
          '2026-10-01': {
            'exercises': [
              {
                'id': 'old',
                'name': 'Bench Press',
                'prescribedWeight': '135',
                'sets': [
                  {'id': 's', 'reps': '5', 'weight': '135'},
                ],
              },
            ],
          },
          '2026-10-02': {
            'exercises': [
              {
                'id': 'same',
                'name': 'Row',
                'sets': [
                  {'id': 's', 'reps': '8', 'weight': '95'},
                ],
              },
            ],
          },
          '2026-10-03': {
            'exercises': [
              {
                'id': 'newer',
                'name': 'Squat',
                'prescribedSetCount': 5,
                'sets': [
                  {'id': 's', 'reps': '3', 'weight': '315'},
                ],
              },
            ],
          },
          '2026-10-04': {
            'exercises': [
              {
                'id': 'new',
                'name': 'Deadlift',
                'sets': [
                  {'id': 's', 'reps': '3', 'weight': '405'},
                ],
              },
            ],
          },
          'not-a-date': {'exercises': []},
        },
        'liftbig_templates': [
          {'id': 't1', 'name': 'Push A'},
        ],
        'liftbig_settings': {'weightUnit': 'lb'},
      }),
    );
    expect(parsed.skippedDays, 1);

    final filtered = dropStaleBackupDays(parsed, {
      '2026-10-01': '2026-10-02T00:00:00.000Z',
      '2026-10-02': '2026-10-02T08:00:00.000Z',
      '2026-10-03': '2026-10-03T12:00:00.000Z',
    });

    expect(
      filtered.days.map((day) => day.dateKey),
      ['2026-10-03', '2026-10-04'],
    );
    expect(filtered.days.first.exercises.single.prescribedSetCount, 5);
    expect(filtered.days.first.exercises.single.sets.single.weight, '315');
    expect(filtered.skippedDays, 1);
    expect(filtered.weightUnit, 'lb');
    expect(filtered.templatesJson, contains('Push A'));
  });

  test('a failed parse throws and does not yield partial days', () {
    const broken = '''
{"exportedAt":"2026-10-03T12:00:00.000Z","liftbig_workouts":{"2026-10-01":
''';
    expect(
      () => parseLiftBigBackup(broken),
      throwsA(isA<BackupParseException>()),
    );
  });
}
