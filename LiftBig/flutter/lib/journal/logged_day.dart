import 'dart:convert';

import '../ids.dart';
import '../model/journal_day.dart';

/// Vue settings default when a backup has no average rest.
const int defaultAverageRestSeconds = 60;

const int minAverageRestSeconds = 5;
const int maxAverageRestSeconds = 600;

/// Clamps the way `sanitizeAverageSeconds` does in the Vue settings.
int clampAverageRestSeconds(int value) {
  if (value < minAverageRestSeconds) return minAverageRestSeconds;
  if (value > maxAverageRestSeconds) return maxAverageRestSeconds;
  return value;
}

/// Reads `averageRestSeconds` from imported `liftbig_settings` JSON.
int averageRestSecondsFromSettings(String? settingsJson) {
  final raw = _settingsValue(settingsJson, 'averageRestSeconds');
  if (raw is num) return clampAverageRestSeconds(raw.round());
  return defaultAverageRestSeconds;
}

/// Vue default is on. Only an explicit false turns it off.
bool autoAdvanceFromSettings(String? settingsJson) {
  final raw = _settingsValue(settingsJson, 'autoAdvanceRepsToWeight');
  if (raw is bool) return raw;
  return true;
}

/// Missing key means on. Only the stored word `false` turns it off.
bool autoFillSetsFromStored(String? raw) => raw != 'false';

/// Missing key means off. Only the stored word `true` turns it on.
bool startTimerOnDoneFromStored(String? raw) => raw == 'true';

/// Missing key means off. Only the stored word `true` turns it on.
bool logSetDifficultyFromStored(String? raw) => raw == 'true';

/// Missing key means off. Only the stored word `true` turns it on.
bool prescribeWarmupFromStored(String? raw) => raw == 'true';

/// "30 seconds", "1 minute", "1 minute 30 seconds", up through "10 minutes".
String formatRestDurationLabel(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final remainder = safe % 60;
  if (minutes == 0) {
    return safe == 1 ? '1 second' : '$safe seconds';
  }
  final minuteLabel = minutes == 1 ? '1 minute' : '$minutes minutes';
  if (remainder == 0) return minuteLabel;
  final secondLabel = remainder == 1 ? '1 second' : '$remainder seconds';
  return '$minuteLabel $secondLabel';
}

/// 30-second steps from 30 seconds through 10 minutes.
List<int> dayRestChoices() {
  return [for (var seconds = 30; seconds <= 600; seconds += 30) seconds];
}

/// Prescribed rest for one exercise, otherwise the settings average.
int restSecondsForExercise(
  JournalExercise exercise, {
  required int averageRestSeconds,
}) {
  final prescribed = exercise.targetRestSeconds;
  if (prescribed != null && prescribed > 0) return prescribed;
  return averageRestSeconds;
}

/// Where focus should move after the lifter finishes a set field.
class FieldAdvance {
  const FieldAdvance.reps(this.setId) : toReps = true;
  const FieldAdvance.weight(this.setId) : toReps = false;

  final String setId;
  final bool toReps;
}

/// Weight, then that set's reps, when auto-advance is on and weight is filled.
FieldAdvance? advanceAfterWeight({
  required bool enabled,
  required String weight,
  required String setId,
}) {
  if (!enabled || weight.trim().isEmpty) return null;
  return FieldAdvance.reps(setId);
}

/// Reps, then the next set's weight. Stops on the last set.
FieldAdvance? advanceAfterReps({
  required bool enabled,
  required String reps,
  required String? nextSetId,
}) {
  if (!enabled || reps.trim().isEmpty) return null;
  if (nextSetId == null || nextSetId.isEmpty) return null;
  return FieldAdvance.weight(nextSetId);
}

/// Consecutive exercises that share a superset id stay in one block.
List<List<JournalExercise>> groupExercisesForDisplay(
  List<JournalExercise> exercises,
) {
  final items = <List<JournalExercise>>[];
  var index = 0;
  while (index < exercises.length) {
    final exercise = exercises[index];
    final groupId = exercise.supersetGroupId?.trim();
    if (groupId == null || groupId.isEmpty) {
      items.add([exercise]);
      index += 1;
      continue;
    }
    final group = <JournalExercise>[exercise];
    var next = index + 1;
    while (next < exercises.length &&
        exercises[next].supersetGroupId?.trim() == groupId) {
      group.add(exercises[next]);
      next += 1;
    }
    items.add(group);
    index = next;
  }
  return items;
}

/// Green card outline when every set is checked; empty lists stay incomplete.
bool exerciseAllSetsChecked(JournalExercise exercise) {
  if (exercise.sets.isEmpty) return false;
  return exercise.sets.every((set) => set.checked);
}

/// Rest starts when a set is completed, and after the last move of a superset.
bool startsRestAfterSet(
  JournalExercise exercise,
  List<JournalExercise> dayExercises,
) {
  final groupId = exercise.supersetGroupId?.trim();
  if (groupId == null || groupId.isEmpty) return true;
  final index = dayExercises.indexWhere((item) => item.id == exercise.id);
  if (index < 0 || index + 1 >= dayExercises.length) return true;
  return dayExercises[index + 1].supersetGroupId?.trim() != groupId;
}

/// Copy used by the Vue log: structure and goals stay, logged work is cleared.
/// Circuit rows keep their target reps and weight and come back unchecked.
List<JournalExercise> cloneExercisesForCopy(List<JournalExercise> source) {
  return [
    for (final exercise in source)
      JournalExercise(
        id: newId(),
        sortOrder: exercise.sortOrder,
        name: exercise.name,
        libraryId: exercise.libraryId,
        isCircuit: exercise.isCircuit,
        isCardio: exercise.isCardio,
        isCore: exercise.isCore,
        targetDuration: exercise.targetDuration,
        targetTimeSeconds: exercise.targetTimeSeconds,
        targetDistance: exercise.targetDistance,
        targetReps: exercise.targetReps,
        targetWeight: exercise.targetWeight,
        supersetGroupId: exercise.supersetGroupId,
        supersetLabel: exercise.supersetLabel,
        supersetOrder: exercise.supersetOrder,
        preferredSwapLibraryIds: exercise.preferredSwapLibraryIds,
        targetRestSeconds: exercise.targetRestSeconds,
        prescribedReps: exercise.prescribedReps,
        prescribedWeight: exercise.prescribedWeight,
        prescribedSetCount: exercise.prescribedSetCount,
        sets: [
          for (var index = 0; index < exercise.sets.length; index++)
            JournalSet(
              id: newId(),
              sortOrder: index,
              reps: exercise.isCircuit ? exercise.sets[index].reps : '',
              weight: exercise.isCircuit ? exercise.sets[index].weight : '',
            ),
        ],
      ),
  ];
}

String nextSupersetLabel(List<JournalExercise> exercises) {
  final used = <String>{
    for (final exercise in exercises)
      if (exercise.supersetLabel?.trim().isNotEmpty ?? false)
        exercise.supersetLabel!.trim(),
  };
  for (var index = 0; index < 26; index++) {
    final letter = String.fromCharCode(65 + index);
    if (!used.contains(letter)) return letter;
  }
  return 'Z';
}

bool exerciseInSuperset(JournalExercise exercise) {
  return exercise.supersetGroupId?.trim().isNotEmpty ?? false;
}

/// Links two lifts, places them adjacent, and numbers the earlier one first.
List<JournalExercise> linkExercisesAsSuperset(
  List<JournalExercise> exercises,
  String firstId,
  String secondId, {
  String? groupId,
}) {
  final firstIdx = exercises.indexWhere((exercise) => exercise.id == firstId);
  final secondIdx = exercises.indexWhere((exercise) => exercise.id == secondId);
  if (firstIdx < 0 || secondIdx < 0 || firstIdx == secondIdx) return exercises;
  if (exerciseInSuperset(exercises[firstIdx]) ||
      exerciseInSuperset(exercises[secondIdx])) {
    return exercises;
  }
  final id = (groupId ?? '').trim();
  final resolvedId = id.isEmpty ? 'ss-${newId()}' : id;
  final label = nextSupersetLabel(exercises);
  final lo = firstIdx < secondIdx ? firstIdx : secondIdx;
  final hi = firstIdx < secondIdx ? secondIdx : firstIdx;
  final next = [...exercises];
  final atHi = next.removeAt(hi);
  final atLo = next.removeAt(lo);
  final pair = [
    atLo.copyWith(
      setSuperset: true,
      supersetGroupId: resolvedId,
      supersetLabel: label,
      supersetOrder: 1,
    ),
    atHi.copyWith(
      setSuperset: true,
      supersetGroupId: resolvedId,
      supersetLabel: label,
      supersetOrder: 2,
    ),
  ];
  next.insertAll(lo, pair);
  return next;
}

List<JournalExercise> unlinkSupersetGroup(
  List<JournalExercise> exercises,
  String groupId,
) {
  final id = groupId.trim();
  if (id.isEmpty) return exercises;
  return [
    for (final exercise in exercises)
      if (exercise.supersetGroupId?.trim() == id)
        exercise.copyWith(
          setSuperset: true,
          supersetGroupId: null,
          supersetLabel: null,
          supersetOrder: null,
        )
      else
        exercise,
  ];
}

List<JournalExercise> swapSupersetPairOrder(
  List<JournalExercise> exercises,
  String groupId,
) {
  final id = groupId.trim();
  if (id.isEmpty) return exercises;
  final indices = <int>[
    for (var index = 0; index < exercises.length; index++)
      if (exercises[index].supersetGroupId?.trim() == id) index,
  ];
  if (indices.length != 2) return exercises;
  final next = [...exercises];
  final first = next[indices[0]];
  final second = next[indices[1]];
  final label = first.supersetLabel ?? second.supersetLabel;
  next[indices[0]] = second.copyWith(
    setSuperset: true,
    supersetGroupId: id,
    supersetLabel: label,
    supersetOrder: 1,
  );
  next[indices[1]] = first.copyWith(
    setSuperset: true,
    supersetGroupId: id,
    supersetLabel: label,
    supersetOrder: 2,
  );
  return next;
}

String? supersetBadge(JournalExercise exercise) {
  final label = exercise.supersetLabel?.trim();
  if (label == null || label.isEmpty) return null;
  final order = exercise.supersetOrder;
  if (order == 1 || order == 2) return 'Superset $label · $order/2';
  return 'Superset $label';
}

Object? _settingsValue(String? settingsJson, String key) {
  if (settingsJson == null || settingsJson.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(settingsJson);
    if (decoded is Map) return decoded[key];
  } catch (_) {
    return null;
  }
  return null;
}
