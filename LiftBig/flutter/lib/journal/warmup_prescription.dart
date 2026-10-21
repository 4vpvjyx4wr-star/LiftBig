import 'lift_name_convergence.dart';

/// Loaded barbell compounds get one warmup set. Pull-ups and lat pulldowns never do.
bool qualifiesForWarmupPrescription(String name, {String? libraryId}) {
  final nameKey = normalizeForExerciseMatch(name);
  final idKey = normalizeForExerciseMatch(libraryId ?? '');
  if (_warmupExcluded(nameKey) || _warmupExcluded(idKey)) return false;
  return _warmupIncluded(nameKey) || _warmupIncluded(idKey);
}

bool _warmupExcluded(String key) {
  if (key.isEmpty) return false;
  if (key.contains('pullup') || key.contains('chinup')) return true;
  if (key.contains('pulldown')) return true;
  return false;
}

bool _warmupIncluded(String key) {
  if (key.isEmpty) return false;
  const needles = [
    'squat',
    'bench',
    'deadlift',
    'overheadpress',
    'barbellrow',
    'bentoverrow',
    'pendlayrow',
    'powerclean',
    'cleanandjerk',
    'snatch',
  ];
  for (final needle in needles) {
    if (key.contains(needle)) return true;
  }
  return false;
}

/// About half the working weight, rounded to the nearest 5 lb. Empty when unknown.
String? warmupWeightLbsFromWorking(String workingLbs) {
  final lbs = double.tryParse(workingLbs.trim().replaceAll(',', '.'));
  if (lbs == null || lbs <= 0) return null;
  final rounded = ((lbs / 2) / 5).round() * 5;
  if (rounded <= 0) return null;
  return '$rounded';
}
