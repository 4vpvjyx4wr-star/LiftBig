import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/catalog/liftbig_catalog.dart';
import 'package:liftbig/data/app_database.dart';
import 'package:liftbig/journal/journal_repository.dart';

LibraryLift _bench() {
  return LibraryLift(
    id: 'bench-press',
    name: 'Bench Press',
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
  test('mergeExactLibraryMatches sets libraryId and canonical name', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(() => journal.db.close());

    await journal.addExercise(
      dateKey: '2026-10-01',
      name: 'bench-press',
      sets: const [],
    );

    final updated = await journal.mergeExactLibraryMatches([_bench()]);
    expect(updated, 1);

    final day = await journal.getDay('2026-10-01');
    expect(day!.exercises.single.name, 'Bench Press');
    expect(day.exercises.single.libraryId, 'bench-press');
  });

  test('near names are not merged automatically', () async {
    final journal = JournalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(() => journal.db.close());

    await journal.addExercise(
      dateKey: '2026-10-01',
      name: 'Barbell Bench Press',
      sets: const [],
    );

    final updated = await journal.mergeExactLibraryMatches([_bench()]);
    expect(updated, 0);

    final day = await journal.getDay('2026-10-01');
    expect(day!.exercises.single.name, 'Barbell Bench Press');
    expect(day.exercises.single.libraryId, isNull);
  });
}
