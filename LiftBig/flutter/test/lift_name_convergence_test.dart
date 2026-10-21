import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/catalog/liftbig_catalog.dart';
import 'package:liftbig/journal/lift_name_convergence.dart';

LibraryLift _lift(String id, String name) {
  return LibraryLift(
    id: id,
    name: name,
    muscleGroups: const ['chest'],
    tags: const [],
    equipment: 'Barbell',
    summary: '',
    instructions: const [],
    tips: const [],
    cues: const [],
    tutorialUrl: '',
    isCardio: false,
    repBasedCore: true,
  );
}

void main() {
  group('liftNamesConverge', () {
    test('exact match ignoring case and spacing', () {
      expect(liftNamesConverge('Bench Press', 'bench press'), isTrue);
      expect(liftNamesConverge('  Bench   Press ', 'bench press'), isTrue);
      expect(
        normalizeForExerciseMatch('Bench Press'),
        normalizeForExerciseMatch('bench press'),
      );
    });

    test('near match with punctuation or equipment prefix', () {
      expect(liftNamesConverge('Bench Press', 'bench-press'), isTrue);
      expect(liftNamesConverge('Bench Press', 'Barbell Bench Press'), isTrue);
    });

    test('unrelated names do not converge', () {
      expect(liftNamesConverge('Bench Press', 'Squat'), isFalse);
      expect(liftNamesConverge('Romanian Deadlift', 'Deadlift'), isFalse);
    });
  });

  group('findLiftNameConvergenceClusters', () {
    test('clusters case and spacing variants in the log', () {
      final clusters = findLiftNameConvergenceClusters(
        loggedExerciseNames: ['Bench Press', 'bench press'],
        catalogLifts: const [],
      );
      expect(clusters, hasLength(1));
      expect(clusters.first.loggedNames, ['Bench Press', 'bench press']);
    });

    test('exact library spellings are excluded from near-match clusters', () {
      final clusters = findLiftNameConvergenceClusters(
        loggedExerciseNames: ['bench-press'],
        catalogLifts: [_lift('bench-press', 'Bench Press')],
      );
      expect(clusters, isEmpty);
    });

    test('near library names stay in clusters', () {
      final clusters = findLiftNameConvergenceClusters(
        loggedExerciseNames: ['Barbell Bench Press'],
        catalogLifts: [_lift('bench-press', 'Bench Press')],
      );
      expect(clusters, hasLength(1));
      expect(clusters.first.loggedNames, ['Barbell Bench Press']);
      expect(clusters.first.libraryMatches.single.name, 'Bench Press');
    });

    test('unrelated logged names without near library matches produce no cluster', () {
      final clusters = findLiftNameConvergenceClusters(
        loggedExerciseNames: ['Overhead Press', 'Lat Pulldown'],
        catalogLifts: [
          _lift('squat', 'Squat'),
          _lift('bench-press', 'Bench Press'),
        ],
      );
      expect(clusters, isEmpty);
      expect(liftNamesConverge('Overhead Press', 'Lat Pulldown'), isFalse);
    });
  });

  group('findDuplicateExerciseGroups', () {
    test('groups capitalization and spacing and picks the library spelling', () {
      final groups = findDuplicateExerciseGroups(
        loggedNames: ['bench press', 'Bench  Press', 'Squat'],
        catalogLifts: [_lift('bench-press', 'Bench Press')],
      );
      expect(groups, hasLength(1));
      expect(groups.single.variants, ['Bench  Press', 'bench press']);
      expect(groups.single.canonicalName, 'Bench Press');
      expect(groups.single.libraryId, 'bench-press');
    });

    test('uses the first alphabetical spelling when the library has no match', () {
      final groups = findDuplicateExerciseGroups(
        loggedNames: ['bench press', 'Bench Press'],
        catalogLifts: const [],
      );
      expect(groups.single.canonicalName, 'Bench Press');
      expect(
        renamedExerciseName(
          name: 'bench press',
          key: groups.single.key,
          canonicalName: groups.single.canonicalName,
        ),
        'Bench Press',
      );
      expect(
        renamedExerciseName(
          name: 'Squat',
          key: groups.single.key,
          canonicalName: groups.single.canonicalName,
        ),
        'Squat',
      );
    });
  });
}
