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
    expect(result.addedPlateWeightLb, 110);
    expect(
      totalWeightLb(25, result.plates),
      135,
    );
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
      variableMachineKindForExercise(
        libraryId: 'leg-press',
        name: 'Leg Press',
      ),
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
