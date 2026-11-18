import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/catalog/liftbig_catalog.dart';
import 'package:liftbig/plans/pasted_plan.dart';

LibraryLift _lift(String id, String name) {
  return LibraryLift(
    id: id,
    name: name,
    muscleGroups: const [],
    tags: const [],
    equipment: '',
    summary: '',
    instructions: const [],
    tips: const [],
    cues: const [],
    tutorialUrl: '',
    isCardio: false,
    repBasedCore: false,
  );
}

void main() {
  test('a two-day note keeps sets, weight, a weekday, and an unmatched name', () {
    final parsed = parsePastedPlan(
      '''
Push
Bench Press 3x5 @ 185
Rest 90s

Monday
Pull-Ups 4x6
Mystery Move 3 sets of 8
''',
      [
        _lift('bench-press', 'Bench Press'),
        _lift('pull-up', 'Pull-Up'),
      ],
    );

    expect(parsed, isNotNull);
    expect(parsed!.name, 'My Plan');
    expect(parsed.workouts, hasLength(2));
    expect(parsed.workouts.first.name, 'Push');
    final bench = parsed.workouts.first.exercises.single;
    expect(bench.lift?.id, 'bench-press');
    expect(bench.setCount, 3);
    expect(bench.targetReps, '5');
    expect(bench.targetWeight, '185');
    expect(parsed.workouts[1].name, 'Monday');
    expect(parsed.workouts[1].exercises.first.lift?.id, 'pull-up');
    expect(parsed.workouts[1].exercises.first.setCount, 4);
    expect(parsed.workouts[1].exercises.last.lift, isNull);
    expect(parsed.workouts[1].exercises.last.customName, 'Mystery Move');
    expect(parsed.workouts[1].exercises.last.targetReps, '8');
  });
}
