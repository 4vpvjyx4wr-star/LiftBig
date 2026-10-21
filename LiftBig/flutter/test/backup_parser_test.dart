import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/backup/backup_parser.dart';

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
}
