import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/catalog/comparable_lifts.dart';
import 'package:liftbig/catalog/liftbig_catalog.dart';

LibraryLift _lift({
  required String id,
  required String name,
  List<String> groups = const [],
  bool cardio = false,
}) {
  return LibraryLift(
    id: id,
    name: name,
    muscleGroups: groups,
    tags: const [],
    equipment: '',
    summary: '',
    instructions: const [],
    tips: const [],
    cues: const [],
    tutorialUrl: '',
    isCardio: cardio,
    repBasedCore: false,
  );
}

void main() {
  test('comparable lifts pin preferred alternates, then shared muscles', () {
    final library = [
      _lift(id: 'db-bench', name: 'Dumbbell Bench Press', groups: ['chest', 'triceps']),
      _lift(id: 'smith-bench', name: 'Smith Machine Bench Press', groups: ['chest']),
      _lift(
        id: 'barbell-bench',
        name: 'Barbell Bench Press',
        groups: ['chest', 'triceps', 'shoulders'],
      ),
      _lift(id: 'incline-bench', name: 'Incline Bench Press', groups: ['chest']),
      _lift(id: 'squat', name: 'Squat', groups: ['quads']),
      _lift(id: 'pull-up', name: 'Pull-Up', groups: ['lats', 'biceps']),
      _lift(id: 'lat-pulldown', name: 'Lat Pulldown', groups: ['lats']),
      _lift(id: 'curl', name: 'Biceps Curl', groups: ['biceps']),
    ];

    final bench = comparableLibraryLifts(
      library: library,
      libraryId: 'db-bench',
      name: 'Dumbbell Bench Press',
      preferredSwapLibraryIds: const ['smith-bench'],
    ).map((lift) => lift.id).toList();
    expect(bench.first, 'smith-bench');
    expect(bench.indexOf('barbell-bench'), lessThan(bench.indexOf('incline-bench')));
    expect(bench.indexOf('incline-bench'), lessThan(bench.indexOf('squat')));
    expect(bench, isNot(contains('db-bench')));

    final pulldown = comparableLibraryLifts(
      library: library,
      libraryId: 'lat-pulldown',
      name: 'Lat Pulldown',
    ).map((lift) => lift.id).toList();
    expect(pulldown.first, 'pull-up');
    expect(pulldown.indexOf('pull-up'), lessThan(pulldown.indexOf('curl')));
    expect(pulldown.last, 'squat');
  });
}
