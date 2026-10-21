import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:liftbig/catalog/liftbig_catalog.dart';
import 'package:liftbig/companion/watch_session.dart';
import 'package:liftbig/date_key.dart';
import 'package:liftbig/health/body_weight_health.dart';
import 'package:liftbig/health/health_workout.dart';
import 'package:liftbig/journal/warmup_prescription.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/utils/weight_units.dart';

LibraryLift _lift({
  required String name,
  List<String> muscleGroups = const [],
  List<String> tags = const [],
}) {
  return LibraryLift(
    id: name.toLowerCase().replaceAll(' ', '-'),
    name: name,
    muscleGroups: muscleGroups,
    tags: tags,
    equipment: 'Barbell',
    summary: '',
    instructions: const [],
    tips: const [],
    cues: const [],
    tutorialUrl: '',
    isCardio: false,
    repBasedCore: false,
  );
}

JournalExercise _exercise({
  String id = 'ex',
  String name = 'Bench Press',
  bool isCardio = false,
  String? libraryId,
  List<JournalSet> sets = const [],
}) {
  return JournalExercise(
    id: id,
    sortOrder: 0,
    name: name,
    isCardio: isCardio,
    libraryId: libraryId,
    sets: sets,
  );
}

void main() {
  test('weight format drops a trailing .0', () {
    expect(formatWeightFromLbs(35, WeightUnit.lb), '35');
    expect(formatRoundedNumber(35, 1), '35');
    expect(formatRoundedNumber(35.5, 1), '35.5');
    expect(formatWeightFromLbs(35.04, WeightUnit.lb), '35');
  });

  test('numeric calendar date is zero-padded MM-DD-YYYY', () {
    expect(formatNumericDate('2026-10-06'), '10-06-2026');
    expect(formatNumericDate('2026-1-6'), '01-06-2026');
  });

  test('warmup classification skips pull-ups and lat pulldowns', () {
    expect(qualifiesForWarmupPrescription('Back Squat'), isTrue);
    expect(qualifiesForWarmupPrescription('Bench Press'), isTrue);
    expect(qualifiesForWarmupPrescription('Deadlift'), isTrue);
    expect(qualifiesForWarmupPrescription('Pull-up'), isFalse);
    expect(qualifiesForWarmupPrescription('Chin-up'), isFalse);
    expect(qualifiesForWarmupPrescription('Lat Pulldown'), isFalse);
    expect(warmupWeightLbsFromWorking('100'), '50');
  });

  test('exercise search ranks name matches before muscle matches', () {
    final lifts = [
      _lift(name: 'Barbell Back Squat', muscleGroups: ['quads', 'glutes']),
      _lift(name: 'Leg Extension', muscleGroups: ['quads']),
      _lift(name: 'Lat Pulldown', muscleGroups: ['back']),
      _lift(name: 'Push Press', tags: ['push'], muscleGroups: ['shoulders']),
      _lift(name: 'Incline Bench', muscleGroups: ['chest']),
      _lift(name: 'Triceps Pushdown', muscleGroups: ['triceps']),
    ];

    final leg = rankExerciseSuggestions(lifts, 'leg').map((lift) => lift.name);
    expect(leg.first, 'Leg Extension');
    expect(leg, contains('Barbell Back Squat'));
    expect(leg.toList().indexOf('Leg Extension'), lessThan(leg.toList().indexOf('Barbell Back Squat')));

    final push = rankExerciseSuggestions(lifts, 'push').map((lift) => lift.name).toList();
    expect(push.first, 'Push Press');
    expect(push, contains('Incline Bench'));
    expect(push, contains('Triceps Pushdown'));
    expect(push.indexOf('Push Press'), lessThan(push.indexOf('Incline Bench')));
  });

  test('watch session is locked when the member is not Pro', () {
    final session = buildWatchSession(
      dateKey: '2026-10-06',
      exercises: [_exercise()],
      restSeconds: 90,
      weightUnit: WeightUnit.lb,
      pro: false,
    );
    expect(session.locked, isTrue);
    expect(session.reason, 'pro');
    expect(session.toJson(), {'version': 1, 'locked': true, 'reason': 'pro'});

    final open = buildWatchSession(
      dateKey: '2026-10-06',
      exercises: [
        _exercise(
          sets: [const JournalSet(id: 's', sortOrder: 0, reps: '5', weight: '135')],
        ),
      ],
      restSeconds: 120,
      weightUnit: WeightUnit.lb,
      pro: true,
    );
    expect(open.locked, isFalse);
    expect(open.reason, isNull);
    expect(open.exerciseName, 'Bench Press');
    expect(open.restSeconds, 120);
    expect(open.toJson()['locked'], isFalse);
    expect(open.toJson()['reason'], isNull);

    final idle = buildWatchSession(
      dateKey: '2026-10-06',
      exercises: const [],
      restSeconds: 90,
      weightUnit: WeightUnit.lb,
      pro: true,
    );
    expect(idle.reason, 'idle');
  });

  test('health activity mapping follows the workout writer', () {
    expect(healthActivityForLibrary('treadmill-walking'), HealthActivity.walking);
    expect(healthActivityForLibrary('indoor-cycling'), HealthActivity.cycling);
    expect(healthActivityForLibrary('stairmaster'), HealthActivity.stairs);
    expect(healthActivityForLibrary(null), HealthActivity.mixedCardio);
    expect(
      healthPluginActivity(HealthActivity.strength),
      HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
    );
    expect(
      healthPluginActivity(HealthActivity.walking),
      HealthWorkoutActivityType.WALKING,
    );
    expect(
      healthActivityFromPlugin(HealthWorkoutActivityType.WALKING_TREADMILL),
      HealthActivity.walking,
    );

    final day = JournalDay(
      dateKey: '2026-10-06',
      updatedAt: '2026-10-06T12:00:00.000Z',
      exercises: [
        _exercise(
          sets: [const JournalSet(id: 's', sortOrder: 0, reps: '5', weight: '135')],
        ),
        _exercise(
          id: 'run',
          name: 'Run',
          isCardio: true,
          libraryId: 'running',
          sets: [const JournalSet(id: 'c', sortOrder: 0, reps: '20', weight: '2')],
        ),
      ],
    );
    final writes = healthWritesForDay(
      day: day,
      averageLiftSeconds: 40,
      averageRestSeconds: 90,
      now: DateTime(2026, 10, 6, 18),
    );
    expect(writes.map((write) => write.activity), [
      HealthActivity.strength,
      HealthActivity.running,
    ]);
    expect(writes.every((write) => write.energyKcal == null), isTrue);
    expect(sumActiveEnergyKcal(const []), isNull);
    expect(sumActiveEnergyKcal(const [120, 30]), 150);
  });
}
