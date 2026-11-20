import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/catalog/lift_search.dart';
import 'package:liftbig/catalog/liftbig_catalog.dart';

LibraryLift _lift({
  required String id,
  required String name,
  List<String> groups = const [],
  String equipment = 'Barbell',
}) {
  return LibraryLift(
    id: id,
    name: name,
    muscleGroups: groups,
    tags: const [],
    equipment: equipment,
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
  final lifts = [
    _lift(
      id: 'romanian-deadlift',
      name: 'Barbell Romanian Deadlift (RDL)',
      groups: ['hamstrings', 'glutes', 'back'],
    ),
    _lift(
      id: 'dumbbell-romanian-deadlift',
      name: 'Dumbbell Romanian Deadlift',
      groups: ['hamstrings', 'glutes', 'back'],
      equipment: 'Dumbbell',
    ),
    _lift(
      id: 'good-morning',
      name: 'Barbell Good Morning',
      groups: ['hamstrings', 'glutes', 'back'],
    ),
    _lift(
      id: 'barbell-row',
      name: 'Barbell Row',
      groups: ['back', 'biceps'],
    ),
    _lift(
      id: 'bench-press',
      name: 'Barbell Bench Press',
      groups: ['chest', 'triceps', 'shoulders'],
    ),
    _lift(
      id: 'flat-dumbbell-press',
      name: 'Dumbbell Bench Press',
      groups: ['chest', 'triceps', 'shoulders'],
      equipment: 'Dumbbell',
    ),
    _lift(
      id: 'ab-wheel',
      name: 'Ab Wheel Rollout',
      groups: ['core'],
      equipment: 'Other',
    ),
  ];

  test('rdl finds every romanian deadlift and leaves bench out', () {
    final names = searchLifts(lifts, 'rdl').map((lift) => lift.id).toList();
    expect(names, containsAll(['romanian-deadlift', 'dumbbell-romanian-deadlift']));
    expect(names, isNot(contains('bench-press')));
  });

  test('hamstring nicknames include rdl and good mornings', () {
    for (final query in ['hamstrings', 'Hammies', 'Ham strings']) {
      final names = searchLifts(lifts, query).map((lift) => lift.id).toSet();
      expect(names, contains('romanian-deadlift'), reason: query);
      expect(names, contains('good-morning'), reason: query);
      expect(names, isNot(contains('bench-press')), reason: query);
    }
  });

  test('short muscle words stay out of unrelated names', () {
    final abs = searchLifts(lifts, 'ab').map((lift) => lift.id).toSet();
    expect(abs, contains('ab-wheel'));
    expect(abs, isNot(contains('bench-press')));
    expect(abs, isNot(contains('barbell-row')));

    final lats = searchLifts(lifts, 'lat').map((lift) => lift.id).toSet();
    expect(lats, contains('barbell-row'));
    expect(lats, isNot(contains('flat-dumbbell-press')));
    expect(lats, isNot(contains('bench-press')));
  });

  test('lower back keeps hinges and leaves a row for upper back', () {
    final lower = searchLifts(lifts, 'lower back').map((lift) => lift.id).toSet();
    expect(lower, containsAll(['romanian-deadlift', 'good-morning']));
    expect(lower, isNot(contains('barbell-row')));

    final upper = searchLifts(lifts, 'back').map((lift) => lift.id).toSet();
    expect(upper, containsAll(['barbell-row', 'romanian-deadlift']));
  });
}
