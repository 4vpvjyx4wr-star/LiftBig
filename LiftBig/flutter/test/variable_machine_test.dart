import 'package:flutter_test/flutter_test.dart';
import 'package:liftbig/utils/plates.dart';
import 'package:liftbig/utils/variable_machine.dart';

void main() {
  test('smith bar 25 lb and goal 135 adds 110 lb of plates per side', () {
    final result = machinePlatesForGoal(
      goalLb: 135,
      startingLb: 25,
      kind: VariableMachineKind.smith,
    );
    expect(result.mode, VariableMachinePlateMode.perSide);
    expect(result.plates, [45, 10]);
    expect(eachSidePlateSummary(result.plates), '1×45, 1×10');
    expect(result.addedPlateWeightLb, 110);
    expect(totalWeightLb(25, result.plates), 135);
  });

  test('leg press and hack squat load the same plates on each side', () {
    for (final kind in [
      VariableMachineKind.legPress,
      VariableMachineKind.hackSquat,
    ]) {
      final split = machinePlatesForGoal(
        goalLb: 295,
        startingLb: 100,
        kind: kind,
      );
      expect(split.mode, VariableMachinePlateMode.perSide);
      expect(split.status, MachinePlatesStatus.platesComputed);
      expect(split.plates, [45, 45, 5, 2.5]);
      expect(split.plates, isNot([45, 45, 45, 25, 25, 5, 5]));
      expect(eachSidePlateSummary(split.plates), '2×45, 1×5, 1×2.5');
      expect(split.addedPlateWeightLb, 195);
      expect(totalWeightLb(100, split.plates), 295);
    }

    final threeFortyFives = machinePlatesForGoal(
      goalLb: 420,
      startingLb: 100,
      kind: VariableMachineKind.legPress,
    );
    expect(threeFortyFives.plates, [45, 45, 45, 25]);
    expect(eachSidePlateSummary(threeFortyFives.plates), '3×45, 1×25');
    expect(eachSidePlateSummary([25, 45, 45, 45]), '3×45, 1×25');
    expect(threeFortyFives.addedPlateWeightLb, 320);
    expect(totalWeightLb(100, threeFortyFives.plates), 420);
  });

  test('leg press start 100 and goal 100 needs no plates', () {
    final result = machinePlatesForGoal(
      goalLb: 100,
      startingLb: 100,
      kind: VariableMachineKind.legPress,
    );
    expect(result.status, MachinePlatesStatus.noPlatesNeeded);
    expect(result.plates, isEmpty);
    expect(result.addedPlateWeightLb, 0);
  });

  test('goal below machine start does not return plates', () {
    final leg = machinePlatesForGoal(
      goalLb: 80,
      startingLb: 100,
      kind: VariableMachineKind.legPress,
    );
    expect(leg.status, MachinePlatesStatus.goalBelowStarting);
    expect(leg.plates, isEmpty);

    final smith = machinePlatesForGoal(
      goalLb: 20,
      startingLb: 25,
      kind: VariableMachineKind.smith,
    );
    expect(smith.plates, isEmpty);
    expect(smith.addedPlateWeightLb, 0);
  });

  test('variable machine detection matches intended lifts only', () {
    expect(
      variableMachineKindForExercise(libraryId: 'leg-press', name: 'Leg Press'),
      VariableMachineKind.legPress,
    );
    expect(
      variableMachineKindForExercise(
        libraryId: 'hack-squat',
        name: 'Hack Squat',
      ),
      VariableMachineKind.hackSquat,
    );
    expect(
      variableMachineKindForExercise(
        libraryId: 'smith-machine-bench-press',
        name: 'Smith Machine Bench Press',
      ),
      VariableMachineKind.smith,
    );
    expect(
      variableMachineKindForExercise(
        libraryId: 'bench-press',
        name: 'Bench Press',
      ),
      isNull,
    );
    expect(
      variableMachineKindForExercise(
        libraryId: null,
        name: 'Leg Press / Squat',
      ),
      isNull,
    );
  });
}
