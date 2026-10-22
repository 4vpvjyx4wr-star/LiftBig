import 'logged_day.dart';
import 'progressive_overload.dart';

/// Digits only, so the catalog value can be stored as logged reps.
bool isSingleRepCount(String raw) => RegExp(r'^\d+$').hasMatch(raw.trim());

/// A plain weight such as 135 or 62.5. Ranges and words stay on the goal.
bool isSingleWeight(String raw) =>
    RegExp(r'^\d+(?:[.,]\d+)?$').hasMatch(raw.trim());

/// True when logged reps still hold a range such as 8-12 from an older assign.
bool storedRepsAreGoal(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || isSingleRepCount(trimmed)) return false;
  return RegExp(r'\d+\s*[-–]\s*\d+').hasMatch(trimmed);
}

class AssignedSet {
  const AssignedSet({required this.reps, required this.weight});

  final String reps;
  final String weight;
}

class AssignedPrescription {
  const AssignedPrescription({
    required this.targetReps,
    required this.targetWeight,
    required this.sets,
  });

  final String? targetReps;
  final String? targetWeight;
  final List<AssignedSet> sets;
}

/// Catalog reps and weight land on the lift goal. A single number is also logged.
AssignedPrescription prescriptionFromCatalogSets(
  List<({String reps, String weight})> sets,
) {
  final logged = <AssignedSet>[];
  String? targetReps;
  String? targetWeight;
  for (final set in sets) {
    final reps = set.reps.trim();
    final weight = set.weight.trim();
    if (targetReps == null && reps.isNotEmpty) targetReps = reps;
    if (targetWeight == null && weight.isNotEmpty) targetWeight = weight;
    logged.add(
      AssignedSet(
        reps: isSingleRepCount(reps) ? reps : '',
        weight: isSingleWeight(weight) ? weight.replaceAll(',', '.') : '',
      ),
    );
  }
  return AssignedPrescription(
    targetReps: targetReps,
    targetWeight: targetWeight,
    sets: logged,
  );
}

/// Goal for the lift. A range left on any set counts when the goal column is empty.
String? exerciseGoalReps({
  required String? targetReps,
  required Iterable<String> storedReps,
}) {
  final goal = (targetReps ?? '').trim();
  if (goal.isNotEmpty) return goal;
  for (final stored in storedReps) {
    if (storedRepsAreGoal(stored)) return stored.trim();
  }
  return null;
}

/// Goal shown for one set. A range left in the reps box counts as the goal.
String? goalRepsForSet({required String? targetReps, required String storedReps}) {
  final goal = (targetReps ?? '').trim();
  if (goal.isNotEmpty) return goal;
  if (storedRepsAreGoal(storedReps)) return storedReps.trim();
  return null;
}

/// Reps box text. A stored range is not a logged count.
String loggedRepsField(String storedReps) {
  if (storedRepsAreGoal(storedReps)) return '';
  return storedReps;
}

/// Slider and wheel value. Logged number wins, then a single goal, then the range middle.
int? repSheetOpeningCount({
  required String loggedReps,
  required String? goalReps,
}) {
  final logged = loggedRepsField(loggedReps).trim();
  if (isSingleRepCount(logged)) return int.parse(logged);
  final goal = (goalReps ?? '').trim();
  if (goal.isEmpty || isAmrap(goal)) return null;
  if (isSingleRepCount(goal)) return int.parse(goal);
  if (!RegExp(r'\d').hasMatch(goal)) return null;
  final range = parseRepRange(goal);
  if (range.min <= 0 || range.max >= 9999) return null;
  final mid = ((range.min + range.max) / 2).round();
  if (mid <= 0) return null;
  return mid;
}

/// Edited rests are capped at 5:00. An untouched longer rest is returned as stored.
int restEditorValueOnSave({
  required int initialSeconds,
  required bool edited,
  required int pendingSeconds,
}) {
  if (!edited) return initialSeconds < 0 ? 0 : initialSeconds;
  return snapRestEditorSeconds(pendingSeconds);
}

const int restEditorMinSeconds = 5;
const int restEditorMaxSeconds = 300;

int snapRestEditorSeconds(int seconds) {
  final clamped = seconds.clamp(restEditorMinSeconds, restEditorMaxSeconds);
  final snapped =
      ((((clamped - restEditorMinSeconds) / 5).round()) * 5) +
      restEditorMinSeconds;
  return snapped.clamp(restEditorMinSeconds, restEditorMaxSeconds);
}

/// 30 seconds, then every 30 seconds through 5 minutes.
List<int> restEditorQuickPicks() {
  return [for (var seconds = 30; seconds <= restEditorMaxSeconds; seconds += 30) seconds];
}

/// Spoken label from one minute up. Shorter values stay a second count.
String restEditorDurationLabel(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  if (safe >= 60) return formatRestDurationLabel(safe);
  return safe == 1 ? '1 second' : '$safe seconds';
}
