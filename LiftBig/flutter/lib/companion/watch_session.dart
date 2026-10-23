import 'dart:convert';

import '../model/journal_day.dart';
import '../utils/weight_units.dart';

/// Session the Apple Watch and Garmin companions already decode.
class WatchSession {
  const WatchSession.locked(this.reason)
    : locked = true,
      dateKey = null,
      exerciseId = null,
      exerciseName = null,
      targetWeightDisplay = null,
      targetReps = null,
      setCount = null,
      currentSetIndex = null,
      restSeconds = null,
      weightUnit = null,
      lineup = const [];

  const WatchSession.open({
    required this.dateKey,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetWeightDisplay,
    required this.targetReps,
    required this.setCount,
    required this.currentSetIndex,
    required this.restSeconds,
    required this.weightUnit,
    required this.lineup,
  }) : locked = false,
       reason = null;

  final bool locked;
  final String? reason;
  final String? dateKey;
  final String? exerciseId;
  final String? exerciseName;
  final String? targetWeightDisplay;
  final String? targetReps;
  final int? setCount;
  final int? currentSetIndex;
  final int? restSeconds;
  final WeightUnit? weightUnit;
  final List<Map<String, Object?>> lineup;

  Map<String, Object?> toJson() {
    if (locked) {
      return {'version': 1, 'locked': true, 'reason': reason};
    }
    return {
      'version': 1,
      'locked': false,
      'dateKey': dateKey,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'targetWeightDisplay': targetWeightDisplay,
      'targetReps': targetReps,
      'setCount': setCount,
      'currentSetIndex': currentSetIndex,
      'restSeconds': restSeconds,
      'weightUnit': weightUnit == WeightUnit.kg ? 'kg' : 'lb',
      'lineup': lineup,
    };
  }
}

class CompanionMessage {
  const CompanionMessage({
    required this.kind,
    required this.dateKey,
    required this.exerciseId,
    required this.setIndex,
    this.reps,
    this.weightLbs,
    this.activeKcal,
    this.restSeconds,
  });

  final String kind;
  final String dateKey;
  final String exerciseId;
  final int setIndex;
  final String? reps;

  /// Weight already converted to stored pounds.
  final String? weightLbs;

  /// Active calories reported by the watch, when it measured the session.
  final double? activeKcal;

  /// Rest duration the watch chose, in seconds.
  final int? restSeconds;

  bool get isCompleteSet => kind == 'completeSet';
  bool get isAdjustSet => kind == 'adjustSet';
  bool get isSkipRest => kind == 'skipRest';
  bool get isFinish => kind == 'finishWorkout';
  bool get isSetRest => kind == 'setRest';
}

int firstOpenSetIndex(JournalExercise exercise) {
  final open = exercise.sets.indexWhere(
    (set) => !set.checked && (set.reps.trim().isEmpty || set.weight.trim().isEmpty),
  );
  if (open >= 0) return open;
  final unchecked = exercise.sets.indexWhere((set) => !set.checked);
  return unchecked >= 0 ? unchecked : 0;
}

List<Map<String, Object?>> lineupForWatch(
  List<JournalExercise> exercises,
  WeightUnit weightUnit,
) {
  final slots = <Map<String, Object?>>[];
  for (final exercise in exercises) {
    final count = exercise.sets.isEmpty ? 1 : exercise.sets.length;
    for (var index = 0; index < count; index++) {
      final set = index < exercise.sets.length ? exercise.sets[index] : null;
      final weightRaw = set != null && set.weight.trim().isNotEmpty
          ? set.weight
          : (exercise.targetWeight ?? '');
      final repsRaw = set != null && set.reps.trim().isNotEmpty
          ? set.reps
          : (exercise.targetReps ?? '');
      slots.add({
        'exerciseId': exercise.id,
        'exerciseName': exercise.name,
        'setIndex': index,
        'setCount': count,
        'reps': repsRaw.trim(),
        'weightDisplay': storedLbsToDisplay(weightRaw, weightUnit),
        'checked': set?.checked ?? false,
      });
    }
  }
  return slots;
}

JournalExercise? watchExercise(List<JournalExercise> exercises) {
  for (final exercise in exercises) {
    if (!exercise.isCardio && !exercise.isCircuit) return exercise;
  }
  if (exercises.isEmpty) return null;
  return exercises.first;
}

WatchSession buildWatchSession({
  required String dateKey,
  required List<JournalExercise> exercises,
  required int restSeconds,
  required WeightUnit weightUnit,
  required bool pro,
}) {
  if (!pro) return const WatchSession.locked('pro');
  final exercise = watchExercise(exercises);
  if (exercise == null) return const WatchSession.locked('idle');
  final openIndex = firstOpenSetIndex(exercise);
  final current = exercise.sets.isEmpty
      ? null
      : exercise.sets[openIndex.clamp(0, exercise.sets.length - 1)];
  final weightRaw = (current != null && current.weight.trim().isNotEmpty)
      ? current.weight
      : (exercise.targetWeight ?? '');
  final repsRaw = (current != null && current.reps.trim().isNotEmpty)
      ? current.reps
      : (exercise.targetReps ?? '');
  return WatchSession.open(
    dateKey: dateKey,
    exerciseId: exercise.id,
    exerciseName: exercise.name,
    targetWeightDisplay: storedLbsToDisplay(weightRaw, weightUnit),
    targetReps: repsRaw.trim(),
    setCount: exercise.sets.isEmpty ? 1 : exercise.sets.length,
    currentSetIndex: openIndex,
    restSeconds: restSeconds,
    weightUnit: weightUnit,
    lineup: lineupForWatch(exercises, weightUnit),
  );
}

/// Applies a companion message onto [day]. [skipRest] and unknown exercises
/// leave the day unchanged. Missing set rows are appended empty, then filled.
JournalDay applyCompanionMessage(JournalDay day, CompanionMessage message) {
  if (message.kind == 'skipRest' || message.kind == 'finishWorkout' || message.kind == 'setRest') {
    return day;
  }
  if (message.dateKey != day.dateKey) return day;
  final index = day.exercises.indexWhere((exercise) => exercise.id == message.exerciseId);
  if (index < 0) return day;
  final exercise = day.exercises[index];
  final sets = [...exercise.sets];
  while (sets.length <= message.setIndex) {
    sets.add(
      JournalSet(
        id: 'watch-${exercise.id}-${sets.length}',
        sortOrder: sets.length,
        reps: '',
        weight: '',
      ),
    );
  }
  final current = sets[message.setIndex];
  sets[message.setIndex] = JournalSet(
    id: current.id,
    sortOrder: current.sortOrder,
    reps: message.reps ?? current.reps,
    weight: message.weightLbs ?? current.weight,
    durationSeconds: current.durationSeconds,
    checked: message.kind == 'completeSet'
        ? true
        : message.kind == 'undoSet'
        ? false
        : current.checked,
    isWarmup: current.isWarmup,
    difficulty: current.difficulty,
  );
  final exercises = [...day.exercises];
  exercises[index] = exercise.copyWith(sets: sets);
  return day.copyWith(exercises: exercises);
}

CompanionMessage? parseCompanionMessage(
  String raw, {
  required WeightUnit fallbackUnit,
}) {
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;
  final json = Map<String, Object?>.from(decoded);
  if (json['version'] != 1) return null;
  final kind = json['kind'];
  final dateKey = json['dateKey'];
  final exerciseId = json['exerciseId'];
  if (kind is! String || dateKey is! String || exerciseId is! String) return null;
  if (dateKey.isEmpty || exerciseId.isEmpty) return null;
  final setIndexRaw = json['setIndex'];
  final setIndex = setIndexRaw is int
      ? setIndexRaw
      : setIndexRaw is num
      ? setIndexRaw.round()
      : int.tryParse('$setIndexRaw');
  if (setIndex == null || setIndex < 0) return null;

  String? reps;
  if (json.containsKey('reps') && json['reps'] != null) {
    reps = '${json['reps']}';
  }

  String? weightLbs;
  final stored = json['weightLbs'];
  if (stored is String && stored.trim().isNotEmpty) {
    weightLbs = stored.trim();
  } else {
    final display = json['weightDisplay'];
    if (display is String && display.trim().isNotEmpty) {
      final unit = json['weightUnit'] == 'kg' ? WeightUnit.kg : fallbackUnit;
      final converted = displayToStoredLbsString(display, unit);
      if (converted != null && converted.isNotEmpty) weightLbs = converted;
    }
  }

  double? activeKcal;
  final kcal = json['activeKcal'];
  if (kcal is num && kcal.isFinite && kcal >= 0) activeKcal = kcal.toDouble();

  return CompanionMessage(
    kind: kind,
    dateKey: dateKey,
    exerciseId: exerciseId,
    setIndex: setIndex,
    reps: reps,
    weightLbs: weightLbs,
    activeKcal: activeKcal,
    restSeconds: json['restSeconds'] is num ? (json['restSeconds'] as num).round() : null,
  );
}
