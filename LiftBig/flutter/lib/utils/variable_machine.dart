import 'plates.dart';

/// Machines whose built-in weight varies by gym.
enum VariableMachineKind {
  smith,
  legPress,
  hackSquat,
}

enum VariableMachinePlateMode {
  /// Bar-style: same plate stack on each side (Smith machine).
  perSide,

  /// Single stack on the sled/carriage (leg press, hack squat).
  totalLoad,
}

enum MachinePlatesStatus {
  noPlatesNeeded,
  goalBelowStarting,
  platesComputed,
  inexact,
}

class MachinePlatesResult {
  const MachinePlatesResult({
    required this.status,
    required this.plates,
    required this.remainderLb,
    required this.mode,
    required this.addedPlateWeightLb,
  });

  final MachinePlatesStatus status;
  final List<double> plates;
  final double remainderLb;
  final VariableMachinePlateMode mode;

  /// Total plate weight to add (both sides for [VariableMachinePlateMode.perSide]).
  final double addedPlateWeightLb;
}

VariableMachinePlateMode plateModeFor(VariableMachineKind kind) {
  switch (kind) {
    case VariableMachineKind.smith:
      return VariableMachinePlateMode.perSide;
    case VariableMachineKind.legPress:
    case VariableMachineKind.hackSquat:
      return VariableMachinePlateMode.totalLoad;
  }
}

String startingWeightLabel(VariableMachineKind kind) {
  switch (kind) {
    case VariableMachineKind.smith:
      return 'Smith bar';
    case VariableMachineKind.legPress:
      return 'Sled start';
    case VariableMachineKind.hackSquat:
      return 'Start weight';
  }
}

/// Matches library id or exercise name without tagging unrelated lifts.
VariableMachineKind? variableMachineKindForExercise({
  String? libraryId,
  required String name,
}) {
  final id = libraryId?.trim().toLowerCase() ?? '';
  final normalizedName = name.trim().toLowerCase();

  if (id == 'leg-press' || normalizedName == 'leg press') {
    return VariableMachineKind.legPress;
  }
  if (id == 'hack-squat' || normalizedName == 'hack squat') {
    return VariableMachineKind.hackSquat;
  }
  if (id.startsWith('smith-machine-')) {
    return VariableMachineKind.smith;
  }
  if (RegExp(r'\bsmith\s+machine\b').hasMatch(normalizedName)) {
    return VariableMachineKind.smith;
  }
  return null;
}

/// [goalLb] and [startingLb] in pounds. Reuses [calculatePlates] for per-side mode.
MachinePlatesResult machinePlatesForGoal({
  required double goalLb,
  required double startingLb,
  required VariableMachineKind kind,
  List<double> sizes = plateSizesLb,
}) {
  final mode = plateModeFor(kind);
  if (goalLb <= startingLb + 0.001) {
    final status = goalLb < startingLb - 0.001
        ? MachinePlatesStatus.goalBelowStarting
        : MachinePlatesStatus.noPlatesNeeded;
    return MachinePlatesResult(
      status: status,
      plates: const [],
      remainderLb: 0,
      mode: mode,
      addedPlateWeightLb: 0,
    );
  }

  if (mode == VariableMachinePlateMode.perSide) {
    final result = calculatePlates(goalLb, startingLb, sizes);
    if (result.plates.isEmpty && result.remainder > 0.001) {
      return MachinePlatesResult(
        status: MachinePlatesStatus.goalBelowStarting,
        plates: const [],
        remainderLb: result.remainder,
        mode: mode,
        addedPlateWeightLb: 0,
      );
    }
    final added = result.plates.fold<double>(0, (a, b) => a + b) * 2;
    final exact = platesAreExact(result.remainder);
    return MachinePlatesResult(
      status: exact
          ? MachinePlatesStatus.platesComputed
          : MachinePlatesStatus.inexact,
      plates: result.plates,
      remainderLb: result.remainder * 2,
      mode: mode,
      addedPlateWeightLb: added,
    );
  }

  final toLoad = goalLb - startingLb;
  final plates = <double>[];
  var remaining = toLoad;
  for (final plate in sizes) {
    while (remaining >= plate - 0.001) {
      plates.add(plate);
      remaining -= plate;
    }
  }
  final remainder = (remaining * 1000).round() / 1000;
  final exact = platesAreExact(remainder);
  return MachinePlatesResult(
    status: exact
        ? MachinePlatesStatus.platesComputed
        : MachinePlatesStatus.inexact,
    plates: plates,
    remainderLb: remainder,
    mode: mode,
    addedPlateWeightLb: plates.fold<double>(0, (a, b) => a + b),
  );
}
