import 'weight_units.dart';

// Bar and plate math. Targets are pounds. Kilogram plates are stored as pounds.

const List<double> plateSizesLb = [45, 35, 25, 10, 5, 2.5];

const List<double> plateSizesKg = [25, 20, 15, 10, 5, 2.5, 1.25];

final Map<double, String> plateColorsLb = {
  45: '#E63946',
  35: '#457B9D',
  25: '#F4A261',
  10: '#2A9D8F',
  5: '#E9C46A',
  2.5: '#A8DADC',
};

final Map<double, String> plateColorsKg = {
  25: '#E63946',
  20: '#457B9D',
  15: '#F4A261',
  10: '#2A9D8F',
  5: '#E9C46A',
  2.5: '#A8DADC',
  1.25: '#9CA3AF',
};

/// Plate denominations for [unit], in pounds, heaviest first.
List<double> plateSizesForUnit(WeightUnit unit) {
  if (unit == WeightUnit.lb) return plateSizesLb;
  return [for (final kg in plateSizesKg) kgToLbs(kg)];
}

String? plateColorHex(double weightLb) {
  final direct = plateColorsLb[weightLb];
  if (direct != null) return direct;
  final kg = lbsToKg(weightLb);
  for (final entry in plateColorsKg.entries) {
    if ((kg - entry.key).abs() < 0.05) return entry.value;
  }
  return null;
}

const double defaultBarLb = 45;

/// Olympic bars plus the lighter bars a Smith machine or gym often has.
const List<double> barChoicesLb = [45, 35, 25, 15];

/// Smith bars are often unmarked. 25 lb is the starting guess until the
/// lifter sets the bar they are using.
const double defaultSmithBarLb = 25;

class PlateQuickRow {
  const PlateQuickRow({required this.label, required this.weightLb});

  final String label;
  final double weightLb;
}

const int quickPlateCount = 5;

/// [count] plates per side on [barLb]. Pounds use a 45; kilograms use a 20.
double quickPlateTargetLb({
  required int count,
  required double barLb,
  required WeightUnit unit,
}) {
  if (unit == WeightUnit.kg) {
    final targetKg = lbsToKg(barLb) + count * 20 * 2;
    return kgToLbs(targetKg);
  }
  return barLb + count * 45 * 2;
}

List<PlateQuickRow> quickPlateRows({
  required double barLb,
  required WeightUnit unit,
}) {
  return [
    for (var count = 1; count <= quickPlateCount; count++)
      PlateQuickRow(
        label: count == 1 ? '1 plate' : '$count plates',
        weightLb: quickPlateTargetLb(count: count, barLb: barLb, unit: unit),
      ),
  ];
}

class PlateCalculationResult {
  const PlateCalculationResult({required this.plates, required this.remainder});

  final List<double> plates;
  final double remainder;
}

/// [targetWeightLb] and [barWeightLb] in pounds; [sizes] are per-side plate weights.
PlateCalculationResult calculatePlates(
  double targetWeightLb,
  double barWeightLb,
  List<double> sizes,
) {
  final weightPerSide = (targetWeightLb - barWeightLb) / 2;
  if (weightPerSide < 0) {
    return PlateCalculationResult(plates: const [], remainder: targetWeightLb);
  }

  final plates = <double>[];
  var remaining = weightPerSide;

  for (final plate in sizes) {
    while (remaining >= plate - 0.001) {
      plates.add(plate);
      remaining -= plate;
    }
  }

  return PlateCalculationResult(
    plates: plates,
    remainder: (remaining * 1000).round() / 1000,
  );
}

double totalWeightLb(double barWeightLb, List<double> platesPerSide) {
  return barWeightLb + platesPerSide.fold<double>(0, (a, b) => a + b) * 2;
}

bool platesAreExact(double remainder) => remainder < 0.001;
