import 'plates.dart';

/// Machines whose built-in weight varies by gym.
enum VariableMachineKind { smith, legPress, hackSquat }

enum VariableMachinePlateMode {
  /// Same plate stack on each side of the bar or sled.
  perSide,
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

  /// Total plate weight added on both sides.
  final double addedPlateWeightLb;
}

/// Leg press, hack squat, and Smith all split `(goal - start) / 2` per side.
VariableMachinePlateMode plateModeFor(VariableMachineKind kind) {
  switch (kind) {
    case VariableMachineKind.smith:
    case VariableMachineKind.legPress:
    case VariableMachineKind.hackSquat:
      return VariableMachinePlateMode.perSide;
  }
}

class PlateCount {
  const PlateCount({required this.weightLb, required this.count});

  final double weightLb;
  final int count;
}

/// Per-side counts, largest standard plate first.
List<PlateCount> eachSidePlateCounts(List<double> plates) {
  final counts = <double, int>{};
  for (final plate in plates) {
    counts[plate] = (counts[plate] ?? 0) + 1;
  }
  final sizes = counts.keys.toList()
    ..sort((a, b) {
      final aKnown = plateSizesLb.indexOf(a);
      final bKnown = plateSizesLb.indexOf(b);
      if (aKnown >= 0 && bKnown >= 0) return aKnown.compareTo(bKnown);
      if (aKnown >= 0) return -1;
      if (bKnown >= 0) return 1;
      return b.compareTo(a);
    });
  return [
    for (final size in sizes) PlateCount(weightLb: size, count: counts[size]!),
  ];
}

/// Compact per-side load, such as `3×45, 1×25`.
String eachSidePlateSummary(
  List<double> plates, {
  String Function(double weightLb)? label,
}) {
  String plain(double weightLb) {
    if ((weightLb - weightLb.roundToDouble()).abs() < 0.001) {
      return weightLb.round().toString();
    }
    var text = weightLb.toString();
    if (text.contains('.')) {
      text = text
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }

  final format = label ?? plain;
  return eachSidePlateCounts(plates)
      .map((count) => '${count.count}×${format(count.weightLb)}')
      .join(', ');
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

/// [goalLb] and [startingLb] in pounds.
///
/// Every variable machine uses the same split as a barbell:
/// `(goal - start) / 2` on each side, via [calculatePlates].
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
