// Bar and plate math matches the Vue `utils/plates.ts` (always pound denominations).

const List<double> plateSizesLb = [45, 35, 25, 10, 5, 2.5];

final Map<double, String> plateColorsLb = {
  45: '#E63946',
  35: '#457B9D',
  25: '#F4A261',
  10: '#2A9D8F',
  5: '#E9C46A',
  2.5: '#A8DADC',
};

const double defaultBarLb = 45;

const List<double> barChoicesLb = [45, 35];

class PlateQuickRow {
  const PlateQuickRow({required this.label, required this.weightLb});

  final String label;
  final double weightLb;
}

const List<PlateQuickRow> plateQuickPresetsLb = [
  PlateQuickRow(label: '1 plate', weightLb: 135),
  PlateQuickRow(label: '2 plates', weightLb: 185),
  PlateQuickRow(label: '3 plates', weightLb: 225),
  PlateQuickRow(label: '4 plates', weightLb: 315),
  PlateQuickRow(label: '5 plates', weightLb: 405),
];

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
