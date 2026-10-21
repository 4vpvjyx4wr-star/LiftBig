// One-rep max estimates — same formulas as Vue `utils/oneRepMax.ts`.

enum OneRmFormulaId { epley, brzycki, lander }

class OneRmFormulaMeta {
  const OneRmFormulaMeta({required this.id, required this.label});

  final OneRmFormulaId id;
  final String label;
}

const List<OneRmFormulaMeta> oneRmFormulas = [
  OneRmFormulaMeta(id: OneRmFormulaId.epley, label: 'Epley'),
  OneRmFormulaMeta(id: OneRmFormulaId.brzycki, label: 'Brzycki'),
  OneRmFormulaMeta(id: OneRmFormulaId.lander, label: 'Lander'),
];

double? _epley(double weight, int reps) {
  if (reps <= 0 || weight <= 0) return null;
  if (reps == 1) return weight;
  return weight * (1 + reps / 30);
}

double? _brzycki(double weight, int reps) {
  if (reps <= 0 || weight <= 0) return null;
  if (reps == 1) return weight;
  if (reps >= 37) return null;
  return weight * (36 / (37 - reps));
}

double? _lander(double weight, int reps) {
  if (reps <= 0 || weight <= 0) return null;
  if (reps == 1) return weight;
  final d = 101.3 - 2.67123 * reps;
  if (d <= 0) return null;
  return (100 * weight) / d;
}

double? estimateOneRepMax(double weight, int reps, OneRmFormulaId formula) {
  switch (formula) {
    case OneRmFormulaId.epley:
      return _epley(weight, reps);
    case OneRmFormulaId.brzycki:
      return _brzycki(weight, reps);
    case OneRmFormulaId.lander:
      return _lander(weight, reps);
  }
}
