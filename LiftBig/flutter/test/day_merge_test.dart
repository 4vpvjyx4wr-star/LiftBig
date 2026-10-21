import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/model/journal_day.dart';
import 'package:liftbig/sync/day_merge.dart';

JournalDay day(String dateKey, String updatedAt, String weight) {
  return JournalDay(
    dateKey: dateKey,
    updatedAt: updatedAt,
    exercises: [
      JournalExercise(
        id: 'ex',
        sortOrder: 0,
        name: 'Bench Press',
        sets: [
          JournalSet(id: 's', sortOrder: 0, reps: '5', weight: weight),
        ],
      ),
    ],
  );
}

void main() {
  test('remote day wins only when its stamp is newer', () {
    final local = day('2026-10-01', '2026-10-01T10:00:00.000Z', '185');
    final remote = day('2026-10-01', '2026-10-01T12:00:00.000Z', '195');

    final chosen = chooseNewerDay(local, remote)!;
    expect(chosen.side, MergeSide.remote);
    expect(chosen.day.exercises.single.sets.single.weight, '195');
  });

  test('local day wins when it is newer or the stamps match', () {
    final local = day('2026-10-01', '2026-10-01T12:00:00.000Z', '185');
    final older = day('2026-10-01', '2026-10-01T09:00:00.000Z', '135');
    final tie = day('2026-10-01', '2026-10-01T12:00:00.000Z', '95');

    expect(chooseNewerDay(local, older)!.side, MergeSide.local);
    expect(chooseNewerDay(local, older)!.day.exercises.single.sets.single.weight, '185');
    expect(chooseNewerDay(local, tie)!.side, MergeSide.local);
    expect(chooseNewerDay(local, tie)!.day.exercises.single.sets.single.weight, '185');
  });

  test('a missing side keeps the day that exists', () {
    final local = day('2026-10-01', '2026-10-01T12:00:00.000Z', '185');
    expect(chooseNewerDay(local, null)!.side, MergeSide.local);
    expect(chooseNewerDay(null, local)!.side, MergeSide.remote);
    expect(chooseNewerDay(null, null), isNull);
  });

  test('settings use the same newer-wins rule', () {
    const local = CloudSettings(updatedAt: '2026-10-02T00:00:00.000Z', weightUnit: 'lb');
    const remote = CloudSettings(updatedAt: '2026-10-03T00:00:00.000Z', weightUnit: 'kg');
    expect(chooseNewerSettings(local, remote)!.side, MergeSide.remote);
    expect(chooseNewerSettings(remote, local)!.settings.weightUnit, 'kg');
  });
}
