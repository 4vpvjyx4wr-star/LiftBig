import '../model/journal_day.dart';
import 'strength_standards.dart';

/// Next-session weight and reps. Same rules as `src/utils/progressiveOverload.ts`.
///
/// Double progression inside the programmed range, with one equipment-sized
/// load step. A missing difficulty rating still progresses. Warmups do not.

const Map<String, double> _incrementLbs = {
  'leg press': 10,
  'squat': 5,
  'rdl': 5,
  'leg extension': 5,
  'hamstring curl': 5,
  'seated hamstring curl': 5,
  'calf raises': 10,
  'walking lunges': 5,
  'incline db press': 5,
  'flat db press': 5,
  'incline machine press': 5,
  'pull ups': 5,
  'lat pulldown': 5,
  'single arm lat pulldown': 2.5,
  'row variation': 5,
  'seated/bentover row': 5,
  'bentover row': 5,
  'chest supported row': 5,
  'cable curl': 2.5,
  'incline cable curl': 2.5,
  'incline db curl': 2.5,
  'incline dumbbell curl': 2.5,
  'tricep pushdown': 2.5,
  'rope pushdown': 2.5,
  'overhead tricep extension': 2.5,
  'overhead cable tricep': 2.5,
  'face pulls': 2.5,
  'cable lateral raise': 2.5,
  'lateral raises': 2.5,
  'db lateral raise': 2.5,
  'lateral raise dropset': 2.5,
  'rear delt fly': 2.5,
  'machine flyes': 2.5,
  'cable flyes': 2.5,
  'cable woodchops': 2.5,
  'cable woodchop': 2.5,
  'cable crunches': 2.5,
  'ab machine': 5,
  'weighted reverse crunches': 2.5,
  'decline reverse crunch': 2.5,
};

const int repsPickerMax = 50;

/// One logged set used as input to the Vue prediction.
class HistorySet {
  const HistorySet({
    required this.dateKey,
    required this.exerciseName,
    required this.reps,
    required this.weight,
    this.isWarmup = false,
    this.targetReps,
    this.difficulty,
  });

  final String dateKey;
  final String exerciseName;
  final String reps;
  final String weight;
  final bool isWarmup;
  final String? targetReps;

  /// Easy, Moderate, or Difficult. Null when the set was not rated.
  final String? difficulty;
}

/// Warmup sets stay on the day and do not move the prediction.
bool setCountsTowardProgress(HistorySet set) => !set.isWarmup;

class PredictedGoals {
  const PredictedGoals({
    required this.suggestedReps,
    required this.suggestedLogReps,
    required this.suggestedWeightLbs,
    required this.reason,
    required this.hasHistory,
  });

  /// Programmed range, such as `8-12`. Stays put while the set target moves.
  final String suggestedReps;

  /// Reps to write on the next working set. Empty when there is no history.
  final String suggestedLogReps;
  final double suggestedWeightLbs;
  final String reason;
  final bool hasHistory;
}

/// Weight and reps to write onto a new set when auto-fill has a suggestion.
class LoggedSetFill {
  const LoggedSetFill({required this.reps, required this.weight});

  final String reps;
  final String weight;

  @override
  bool operator ==(Object other) {
    return other is LoggedSetFill && other.reps == reps && other.weight == weight;
  }

  @override
  int get hashCode => Object.hash(reps, weight);
}

/// First exercise of a given name on each day, matching `Array.find`.
List<HistorySet> historySetsFromDays(List<JournalDay> days) {
  final out = <HistorySet>[];
  for (final day in days) {
    final seen = <String>{};
    for (final exercise in day.exercises) {
      final key = exercise.name.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      if (exercise.sets.isEmpty) {
        out.add(
          HistorySet(
            dateKey: day.dateKey,
            exerciseName: exercise.name,
            reps: '',
            weight: '',
            targetReps: exercise.targetReps,
          ),
        );
        continue;
      }
      for (final set in exercise.sets) {
        out.add(
          HistorySet(
            dateKey: day.dateKey,
            exerciseName: exercise.name,
            reps: set.reps,
            weight: set.weight,
            isWarmup: set.isWarmup,
            targetReps: exercise.targetReps,
            difficulty: set.difficulty,
          ),
        );
      }
    }
  }
  return out;
}

double getWeightIncrementLbs(String exerciseName) {
  final lower = exerciseName.toLowerCase();
  for (final entry in _incrementLbs.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return 2.5;
}

bool isAmrap(String repGoal) => repGoal.toLowerCase().contains('amrap');

({int min, int max}) parseRepRange(String repGoal) {
  if (isAmrap(repGoal)) return (min: 1, max: 9999);
  final match = RegExp(r'(\d+)\s*[-–]\s*(\d+)').firstMatch(repGoal);
  if (match != null) {
    return (
      min: int.parse(match.group(1)!),
      max: int.parse(match.group(2)!),
    );
  }
  final single = _leadingInt(repGoal);
  if (single != null) return (min: single, max: single);
  return (min: 0, max: 9999);
}

/// Top of a programmed range. Empty for AMRAP or when the goal is not finite.
String defaultLogRepsForTarget(String targetReps) {
  final trimmed = targetReps.trim();
  if (trimmed.isEmpty || isAmrap(trimmed)) return '';
  final max = parseRepRange(trimmed).max;
  if (max <= 0 || max >= 9999) return '';
  return '$max';
}

double estimateE1rmLbs(double weightLbs, int reps) {
  if (weightLbs <= 0) return 0;
  if (reps <= 1) return weightLbs;
  return weightLbs * (1 + reps / 30);
}

double weightForTargetRepsLbs(double e1rmLbs, int targetReps) {
  if (e1rmLbs <= 0) return 0;
  if (targetReps <= 1) return e1rmLbs;
  return e1rmLbs / (1 + targetReps / 30);
}

int repCountForWeightGoal(String repGoal) {
  final range = parseRepRange(repGoal);
  if (range.max >= 9999) return range.min > 0 ? range.min : 10;
  return range.max;
}

String inferRepGoalFromHistory(List<int> maxRepsPerSession) {
  final vals = maxRepsPerSession.where((reps) => reps > 0).toList();
  if (vals.isEmpty) return '8-12';
  vals.sort();
  final median = vals[vals.length ~/ 2];
  if (median <= 5) return '3-5';
  if (median <= 8) return '6-8';
  if (median <= 12) return '8-12';
  if (median <= 15) return '10-15';
  return '12-15';
}

/// Same options the Vue log uses when it fills a goal from history.
LoggedSetFill? loggedSetFill({
  required String exerciseName,
  required List<HistorySet> history,
  String? currentTargetReps,
  String? excludeDateKey,
  String? libraryId,
  double? bodyWeightLbs,
  String displayUnit = 'lb',
}) {
  final goal = (currentTargetReps ?? '').trim();
  final predicted = predictWorkoutGoals(
    exerciseName,
    history,
    currentTargetReps: goal,
    excludeDateKey: excludeDateKey,
    lockRepGoal: goal.isNotEmpty,
    ignoreStoredGoalWeight: true,
    displayUnit: displayUnit,
  );
  if (predicted.hasHistory) {
    final weight = formatPredictedWeight(predicted.suggestedWeightLbs);
    if (weight.isEmpty) return null;
    final logReps = predicted.suggestedLogReps.trim();
    return LoggedSetFill(
      reps: logReps.isNotEmpty
          ? logReps
          : defaultLogRepsForTarget(predicted.suggestedReps),
      weight: weight,
    );
  }
  final repGoal = goal.isEmpty ? '8-12' : goal;
  final targetReps = repCountForWeightGoal(repGoal);
  final assumedBodyWeight = (bodyWeightLbs != null && bodyWeightLbs > 0)
      ? bodyWeightLbs
      : defaultAssumedBodyWeightLbs;
  final suggested = suggestWorkingWeightLbs(
    exerciseName: exerciseName,
    bodyWeightLbs: assumedBodyWeight,
    libraryId: libraryId,
    targetReps: targetReps,
  );
  if (suggested == null || suggested <= 0) return null;
  final weight = formatPredictedWeight(suggested);
  if (weight.isEmpty) return null;
  return LoggedSetFill(
    reps: defaultLogRepsForTarget(repGoal),
    weight: weight,
  );
}

PredictedGoals predictWorkoutGoals(
  String exerciseName,
  List<HistorySet> history, {
  String? currentTargetReps,
  double? currentTargetWeightLbs,
  String? excludeDateKey,
  bool lockRepGoal = false,
  bool ignoreStoredGoalWeight = false,
  String displayUnit = 'lb',
}) {
  final matching = [
    for (final set in history)
      if (_namesMatch(set.exerciseName, exerciseName)) set,
  ];
  final currentReps = (currentTargetReps ?? '').trim();
  final currentWeight = ignoreStoredGoalWeight
      ? 0.0
      : (currentTargetWeightLbs ?? 0);
  final unit = displayUnit == 'kg' ? 'kg' : 'lb';
  final sessions = _workingSessions(matching, excludeDateKey);

  // No history: do not invent a starting weight.
  if (sessions.isEmpty) {
    final reps = currentReps.isEmpty ? '8-12' : currentReps;
    return PredictedGoals(
      suggestedReps: reps,
      suggestedLogReps: '',
      suggestedWeightLbs: currentWeight,
      reason: 'No history yet',
      hasHistory: false,
    );
  }

  final historicalGoals = _historicalRepGoals(matching);
  final repGoal = lockRepGoal && currentReps.isNotEmpty
      ? currentReps
      : (currentReps.isNotEmpty
            ? currentReps
            : (_mostCommon(historicalGoals) ??
                  inferRepGoalFromHistory([
                    for (final session in sessions) session.peakReps,
                  ])));
  final range = parseRepRange(repGoal);
  final step = _progressionStepLbs(exerciseName, unit);
  final plan = _nextSessionTarget(
    last: sessions.last,
    streak: _difficultStreak(sessions),
    range: range,
    stepLbs: step,
    unit: unit,
  );

  return PredictedGoals(
    suggestedReps: repGoal,
    suggestedLogReps: '${plan.reps}',
    suggestedWeightLbs: plan.weightLbs,
    reason: plan.reason,
    hasHistory: true,
  );
}

String formatPredictedWeight(double lbs) {
  if (lbs.isNaN || lbs.isInfinite) return '';
  final scaled = (lbs * 1000).round() / 1000;
  if (scaled == scaled.roundToDouble()) return '${scaled.round()}';
  final text = scaled.toString();
  if (!text.contains('.')) return text;
  return text
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

double parseStoredLbs(String raw) {
  final text = raw.trim().replaceAll(',', '.');
  if (text.isEmpty) return double.nan;
  return double.tryParse(text) ?? double.nan;
}

const double _lbsPerKg = 2.2046226218;

class _WorkSession {
  const _WorkSession({
    required this.dateKey,
    required this.achievedReps,
    required this.peakReps,
    required this.weightLbs,
    required this.difficulty,
  });

  final String dateKey;
  final int achievedReps;
  final int peakReps;
  final double weightLbs;
  final String? difficulty;
}

class _NextTarget {
  const _NextTarget({
    required this.weightLbs,
    required this.reps,
    required this.reason,
  });

  final double weightLbs;
  final int reps;
  final String reason;
}

/// Warmups never move the next target, even when they carry a rating.
List<_WorkSession> _workingSessions(
  List<HistorySet> sets,
  String? excludeDateKey,
) {
  final byDate = <String, List<HistorySet>>{};
  for (final set in sets) {
    if (excludeDateKey != null && set.dateKey == excludeDateKey) continue;
    byDate.putIfAbsent(set.dateKey, () => []).add(set);
  }
  final dates = byDate.keys.toList()..sort();
  final out = <_WorkSession>[];
  for (final date in dates) {
    final weights = <double>[];
    final reps = <int>[];
    final rated = <HistorySet>[];
    for (final set in byDate[date]!) {
      if (!setCountsTowardProgress(set)) continue;
      final weight = parseStoredLbs(set.weight);
      final count = _leadingInt(set.reps);
      if (weight.isNaN || weight <= 0 || count == null || count <= 0) continue;
      weights.add(weight);
      reps.add(count);
      rated.add(set);
    }
    if (reps.isEmpty) continue;
    var achieved = reps.first;
    var peak = reps.first;
    for (final count in reps) {
      if (count < achieved) achieved = count;
      if (count > peak) peak = count;
    }
    out.add(
      _WorkSession(
        dateKey: date,
        achievedReps: achieved,
        peakReps: peak,
        weightLbs: _modeWeight(weights),
        difficulty: _sessionDifficulty(rated),
      ),
    );
  }
  return out;
}

List<String> _historicalRepGoals(List<HistorySet> sets) {
  final goals = <String>[];
  final seen = <String>{};
  for (final set in sets) {
    if (!seen.add(set.dateKey)) continue;
    final goal = (set.targetReps ?? '').trim();
    if (goal.isNotEmpty) goals.add(goal);
  }
  return goals;
}

String? _mostCommon(List<String> goals) {
  if (goals.isEmpty) return null;
  final counts = <String, int>{};
  for (final goal in goals) {
    counts[goal] = (counts[goal] ?? 0) + 1;
  }
  var best = goals.first;
  var bestCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      bestCount = entry.value;
      best = entry.key;
    }
  }
  return best;
}

/// One Difficult set does not define the session when another rating is logged.
String? _sessionDifficulty(List<HistorySet> sets) {
  var easy = 0;
  var moderate = 0;
  var difficult = 0;
  for (final set in sets) {
    final rating = canonicalSetDifficulty(set.difficulty);
    if (rating == setDifficultyEasy) easy += 1;
    if (rating == setDifficultyModerate) moderate += 1;
    if (rating == setDifficultyDifficult) difficult += 1;
  }
  final rated = easy + moderate + difficult;
  if (rated == 0) return null;
  if (difficult == 1 && rated > 1) difficult = 0;
  if (difficult > easy && difficult > moderate) return setDifficultyDifficult;
  if (easy > difficult && easy > moderate) return setDifficultyEasy;
  if (moderate > easy && moderate > difficult) return setDifficultyModerate;
  if (easy == 0 && moderate == 0 && difficult == 0) return null;
  return setDifficultyModerate;
}

bool _difficultStreak(List<_WorkSession> sessions) {
  if (sessions.length < 2) return false;
  if (sessions.last.difficulty != setDifficultyDifficult) return false;
  var count = 0;
  final start = sessions.length < 3 ? 0 : sessions.length - 3;
  for (var i = sessions.length - 1; i >= start; i--) {
    if (sessions[i].difficulty == setDifficultyDifficult) count += 1;
  }
  return count >= 2;
}

double _modeWeight(List<double> weights) {
  final counts = <int, int>{};
  var bestKey = 0;
  var bestCount = 0;
  var bestWeight = 0.0;
  for (final weight in weights) {
    final key = (weight * 1000).round();
    final count = (counts[key] ?? 0) + 1;
    counts[key] = count;
    if (count > bestCount || (count == bestCount && weight > bestWeight)) {
      bestCount = count;
      bestKey = key;
      bestWeight = weight;
    }
  }
  return bestKey / 1000;
}

/// Upper body ~2.5 lb / 1 kg, lower body ~5 lb / 2.5 kg, from the increment map.
double _progressionStepLbs(String exerciseName, String unit) {
  final pounds = getWeightIncrementLbs(exerciseName);
  if (unit != 'kg') return pounds;
  if (pounds >= 10) return 5 * _lbsPerKg;
  if (pounds >= 5) return 2.5 * _lbsPerKg;
  return _lbsPerKg;
}

double _quantize(double value, double step) {
  if (step <= 0) return value;
  return ((value / step).round() * step * 1000).round() / 1000;
}

double _stepUp(double weightLbs, double stepLbs, String unit) {
  if (unit != 'kg') {
    var next = _quantize(weightLbs + stepLbs, stepLbs);
    if (next <= weightLbs + 0.05) next = _quantize(weightLbs + stepLbs * 2, stepLbs);
    return next;
  }
  final stepKg = stepLbs / _lbsPerKg;
  final kg = weightLbs / _lbsPerKg;
  final aligned = (kg / stepKg).round() * stepKg;
  var nextKg = aligned + stepKg;
  if (nextKg * _lbsPerKg <= weightLbs + 0.05) nextKg += stepKg;
  return _quantize(nextKg * _lbsPerKg, 0.001);
}

double _stepDown(double weightLbs, double stepLbs, String unit) {
  if (unit != 'kg') {
    var next = _quantize(weightLbs - stepLbs, stepLbs);
    if (next >= weightLbs - 0.05) next = weightLbs - stepLbs;
    if (next <= 0) return weightLbs;
    return (next * 1000).round() / 1000;
  }
  final stepKg = stepLbs / _lbsPerKg;
  final kg = weightLbs / _lbsPerKg;
  final aligned = (kg / stepKg).round() * stepKg;
  var nextKg = aligned - stepKg;
  if (nextKg * _lbsPerKg >= weightLbs - 0.05) nextKg = kg - stepKg;
  if (nextKg <= 0) return weightLbs;
  return (nextKg * _lbsPerKg * 1000).round() / 1000;
}

String _stepLabel(double stepLbs, String unit) {
  if (unit == 'kg') {
    final kg = stepLbs / _lbsPerKg;
    final shown = (kg * 10).round() / 10;
    final text = shown == shown.roundToDouble()
        ? '${shown.round()}'
        : shown.toStringAsFixed(1);
    return '$text kg';
  }
  return '${formatPredictedWeight(stepLbs)} lb';
}

String _weightLabel(double lbs, String unit) {
  if (unit == 'kg') {
    final kg = lbs / _lbsPerKg;
    final shown = (kg * 10).round() / 10;
    final text = shown == shown.roundToDouble()
        ? '${shown.round()}'
        : shown.toStringAsFixed(1);
    return '$text kg';
  }
  return '${formatPredictedWeight(lbs)} lb';
}

/// Double progression. Easy climbs reps faster. Difficult holds or steps back once.
_NextTarget _nextSessionTarget({
  required _WorkSession last,
  required bool streak,
  required ({int min, int max}) range,
  required double stepLbs,
  required String unit,
}) {
  final achieved = last.achievedReps;
  final weight = last.weightLbs;
  final rating = last.difficulty;
  final finite = range.max > 0 && range.max < 9999;
  final minReps = range.min > 0 ? range.min : 1;
  final atTop = finite && achieved >= range.max;
  final short = finite && achieved < minReps;
  final stepLabel = _stepLabel(stepLbs, unit);

  int cap(int value) {
    if (value < 1) return 1;
    if (finite && value > range.max) return range.max;
    return value;
  }

  if (rating == setDifficultyDifficult && streak) {
    final nextWeight = _stepDown(weight, stepLbs, unit);
    final dropped = nextWeight < weight - 0.05;
    final nextReps = cap(short ? achieved : minReps);
    return _NextTarget(
      weightLbs: dropped ? nextWeight : weight,
      reps: nextReps,
      reason: dropped
          ? 'Several Difficult sessions. Drop $stepLabel and rebuild at $nextReps reps.'
          : 'Several Difficult sessions. Hold ${_weightLabel(weight, unit)} and aim for $nextReps reps.',
    );
  }

  if (rating == setDifficultyDifficult) {
    if (short) {
      final nextWeight = _stepDown(weight, stepLbs, unit);
      final dropped = nextWeight < weight - 0.05;
      final nextReps = cap(achieved);
      return _NextTarget(
        weightLbs: dropped ? nextWeight : weight,
        reps: nextReps,
        reason: dropped
            ? 'Rated Difficult and short of the range. Drop $stepLabel and rebuild at $nextReps reps.'
            : 'Rated Difficult and short of the range. Hold ${_weightLabel(weight, unit)} and aim for $nextReps reps.',
      );
    }
    final nextReps = cap(achieved);
    return _NextTarget(
      weightLbs: weight,
      reps: nextReps,
      reason:
          'Rated Difficult. Hold ${_weightLabel(weight, unit)} and aim for $nextReps reps.',
    );
  }

  if (rating == setDifficultyEasy) {
    if (atTop) {
      final nextReps = cap(minReps);
      return _NextTarget(
        weightLbs: _stepUp(weight, stepLbs, unit),
        reps: nextReps,
        reason:
            'Rated Easy at the top of the range. Add $stepLabel and start back at $nextReps reps.',
      );
    }
    // Easy adds two reps. Load waits until the top of the range.
    final nextReps = cap(achieved + 2);
    return _NextTarget(
      weightLbs: weight,
      reps: nextReps,
      reason: 'Rated Easy. Same weight, move up to $nextReps reps.',
    );
  }

  final moderate = rating == setDifficultyModerate;
  if (atTop) {
    final nextReps = cap(minReps);
    final reason = moderate
        ? 'Rated Moderate and at the top of the range. Add $stepLabel and start back at $nextReps reps.'
        : 'Working sets hit the top of the range. Add $stepLabel and start back at $nextReps reps.';
    return _NextTarget(
      weightLbs: _stepUp(weight, stepLbs, unit),
      reps: nextReps,
      reason: reason,
    );
  }
  if (short) {
    final nextReps = cap(achieved);
    final reason = moderate
        ? 'Rated Moderate and short of the range. Hold ${_weightLabel(weight, unit)} and aim for $nextReps reps.'
        : 'Short of the rep range. Hold ${_weightLabel(weight, unit)} and aim for $nextReps reps.';
    return _NextTarget(weightLbs: weight, reps: nextReps, reason: reason);
  }
  // Inside the range, or an open goal: add a rep before adding weight.
  final nextReps = cap(achieved + 1);
  final reason = moderate
      ? 'Rated Moderate. Same weight, aim for $nextReps reps.'
      : 'Same weight, aim for $nextReps reps. Add reps before adding weight.';
  return _NextTarget(weightLbs: weight, reps: nextReps, reason: reason);
}

bool _namesMatch(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

int? _leadingInt(String raw) {
  final match = RegExp(r'^[+-]?\d+').firstMatch(raw.trim());
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}
