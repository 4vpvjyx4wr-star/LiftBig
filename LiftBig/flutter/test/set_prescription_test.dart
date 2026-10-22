import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/journal/set_prescription.dart';

void main() {
  test('rest editor speaks minutes and keeps an untouched longer rest', () {
    expect(restEditorDurationLabel(45), '45 seconds');
    expect(restEditorDurationLabel(70), '1 minute 10 seconds');
    expect(restEditorQuickPicks().first, 30);
    expect(restEditorQuickPicks().last, 300);
    expect(restEditorQuickPicks(), hasLength(10));
    expect(
      restEditorValueOnSave(
        initialSeconds: 420,
        edited: false,
        pendingSeconds: 300,
      ),
      420,
    );
    expect(
      restEditorValueOnSave(
        initialSeconds: 420,
        edited: true,
        pendingSeconds: 400,
      ),
      300,
    );
    expect(
      restEditorValueOnSave(
        initialSeconds: 70,
        edited: true,
        pendingSeconds: 90,
      ),
      90,
    );
  });

  test('rep sheet opens on a logged number or the middle of the goal', () {
    expect(repSheetOpeningCount(loggedReps: '', goalReps: '8-12'), 10);
    expect(repSheetOpeningCount(loggedReps: '', goalReps: '12'), 12);
    expect(repSheetOpeningCount(loggedReps: '7', goalReps: '8-12'), 7);
    expect(
      repSheetOpeningCount(
        loggedReps: '8-12',
        goalReps: goalRepsForSet(targetReps: null, storedReps: '8-12'),
      ),
      10,
    );
    expect(loggedRepsField('8-12'), isEmpty);
    expect(loggedRepsField('12'), '12');
    expect(
      goalRepsForSet(targetReps: null, storedReps: '8-12'),
      '8-12',
    );
  });

  test('catalog assignment stores the range on the goal', () {
    final range = prescriptionFromCatalogSets([
      (reps: '8-12', weight: '135'),
      (reps: '8-12', weight: '135'),
    ]);
    expect(range.targetReps, '8-12');
    expect(range.targetWeight, '135');
    expect(range.sets.every((set) => set.reps.isEmpty), isTrue);
    expect(range.sets.every((set) => set.weight == '135'), isTrue);

    final single = prescriptionFromCatalogSets([(reps: '12', weight: '')]);
    expect(single.targetReps, '12');
    expect(single.sets.single.reps, '12');
    expect(single.sets.single.weight, isEmpty);
  });
}
