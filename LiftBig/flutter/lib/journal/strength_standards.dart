import 'progressive_overload.dart';

/// Default body weight for suggestions when Settings has no value.
/// It is labeled in the UI and is not written to `body_weight_lbs` until the
/// user saves body weight in Settings.
const double defaultAssumedBodyWeightLbs = 180;

const String defaultAssumedBodyWeightLabel =
    '180 lb default (set body weight in Settings for your numbers)';

/// 50th-percentile working weights use Strength Level "Intermediate" one-rep
/// max standards (https://strengthlevel.com/strength-standards) as a ratio of
/// body weight, then convert to a typical 8-rep working weight.
const Map<String, double> _intermediateOneRmRatioByLibraryId = {
  'bench-press': 1.25,
  'incline-bench-press': 1.05,
  'dumbbell-bench-press': 0.95,
  'squat': 1.75,
  'front-squat': 1.45,
  'deadlift': 2.0,
  'romanian-deadlift': 1.55,
  'sumo-deadlift': 1.9,
  'overhead-press': 0.85,
  'barbell-row': 1.05,
  'pendlay-row': 1.05,
  'pull-up': 0.0,
  'chin-up': 0.0,
  'lat-pulldown': 0.95,
  'leg-press': 2.75,
  'hip-thrust': 1.65,
};

const List<(String pattern, double ratio)> _nameOneRmRatios = [
  ('squat', 1.75),
  ('bench', 1.25),
  ('deadlift', 2.0),
  ('rdl', 1.55),
  ('romanian', 1.55),
  ('overhead press', 0.85),
  ('ohp', 0.85),
  ('row', 1.0),
  ('pulldown', 0.95),
  ('curl', 0.45),
  ('tricep', 0.55),
  ('lateral raise', 0.25),
  ('leg press', 2.75),
  ('calf', 1.1),
  ('pull-up', 0.0),
  ('pull up', 0.0),
  ('chin-up', 0.0),
  ('chin up', 0.0),
];

const double _defaultOneRmRatio = 0.75;
const double _maxSuggestedWorkingLbs = 500;

double intermediateOneRmRatio({String? libraryId, required String exerciseName}) {
  final id = libraryId?.trim();
  if (id != null && id.isNotEmpty) {
    final byId = _intermediateOneRmRatioByLibraryId[id];
    if (byId != null) return byId;
  }
  final lower = exerciseName.toLowerCase();
  for (final entry in _nameOneRmRatios) {
    if (lower.contains(entry.$1)) return entry.$2;
  }
  return _defaultOneRmRatio;
}

/// Suggested working weight at ~50th percentile for [bodyWeightLbs] and 8 reps.
double? suggestWorkingWeightLbs({
  required String exerciseName,
  required double bodyWeightLbs,
  String? libraryId,
  int targetReps = 8,
}) {
  if (bodyWeightLbs <= 0) return null;
  final ratio = intermediateOneRmRatio(
    libraryId: libraryId,
    exerciseName: exerciseName,
  );
  if (ratio <= 0) return null;
  final e1rm = bodyWeightLbs * ratio;
  var working = weightForTargetRepsLbs(e1rm, targetReps);
  if (working <= 0) return null;
  final increment = getWeightIncrementLbs(exerciseName);
  working = _roundToIncrement(working, increment);
  if (working > _maxSuggestedWorkingLbs) {
    working = _roundToIncrement(_maxSuggestedWorkingLbs, increment);
  }
  return working;
}

double _roundToIncrement(double lbs, double increment) {
  final step = increment >= 5 ? increment : 2.5;
  return (lbs / step).round() * step;
}
