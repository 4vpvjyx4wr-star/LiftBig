import 'dart:convert';

import '../model/journal_day.dart';
import '../utils/weight_units.dart';

/// Working count for a companion. A range such as 8-12 uses the top, 12.
String companionReps(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final numbers = RegExp(r'\d+')
      .allMatches(trimmed)
      .map((match) => int.parse(match.group(0)!))
      .toList();
  if (numbers.isEmpty) return trimmed;
  if (numbers.length == 1 && RegExp(r'^\d+$').hasMatch(trimmed)) {
    return trimmed;
  }
  var top = numbers.first;
  for (final number in numbers.skip(1)) {
    if (number > top) top = number;
  }
  return '$top';
}

/// Phone rest stamped onto a session the watches already understand.
class WatchRestPublish {
  const WatchRestPublish({
    required this.soundEnabled,
    this.restEndsAtEpochSeconds,
    this.restPaused = false,
    this.restRemaining,
    this.restCancelled = false,
    this.alarmRinging = false,
    this.restRevision,
  });

  final bool soundEnabled;

  /// Absolute end, unix seconds. Null when rest is not running.
  final int? restEndsAtEpochSeconds;
  final bool restPaused;
  final int? restRemaining;
  final bool restCancelled;

  /// True while the phone tone is looping. The Apple Watch shows Stop.
  /// Garmin has no Stop control.
  final bool alarmRinging;

  /// Watch rest change this publish belongs to. Older echoes are ignored.
  final int? restRevision;
}

/// Adds the phone rest clock and the alarm-sound preference.
/// A lineup republish without an active phone rest leaves the watch clock alone.
Map<String, Object?> withWatchRest(
  Map<String, Object?> payload,
  WatchRestPublish rest,
) {
  final next = Map<String, Object?>.from(payload);
  next['soundEnabled'] = rest.soundEnabled;
  next['restCancelled'] = rest.restCancelled;
  next['alarmRinging'] = rest.alarmRinging;
  next.remove('restEndsAt');
  next.remove('restPaused');
  next.remove('restRemaining');
  next.remove('restRev');
  if (rest.restRevision != null) {
    next['restRev'] = rest.restRevision;
  }
  if (rest.restCancelled) return next;
  if (rest.restPaused) {
    next['restPaused'] = true;
    next['restRemaining'] = rest.restRemaining ?? 0;
    return next;
  }
  final ends = rest.restEndsAtEpochSeconds;
  if (ends != null && ends > 0) {
    next['restEndsAt'] = ends;
    next['restPaused'] = false;
  }
  return next;
}

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
      restCancelled = false,
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
    this.restCancelled = false,
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

  /// True only when the phone cancelled rest. A lineup republish leaves this
  /// false so a watch countdown keeps running.
  final bool restCancelled;
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
      'restCancelled': restCancelled,
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
    this.restRemaining,
    this.restRevision,
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

  /// Seconds left when the watch pauses rest.
  final int? restRemaining;

  /// Monotonic rest change from the watch. The phone echoes it back.
  final int? restRevision;

  bool get isCompleteSet => kind == 'completeSet';
  bool get isAdjustSet => kind == 'adjustSet';
  bool get isSkipRest => kind == 'skipRest';
  bool get isFinish => kind == 'finishWorkout';
  bool get isSetRest => kind == 'setRest';
  bool get isStopAlarm => kind == 'stopAlarm';
  bool get isPauseRest => kind == 'pauseRest';
  bool get isResumeRest => kind == 'resumeRest';
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
        'reps': companionReps(repsRaw),
        'weightDisplay': storedLbsToDisplay(weightRaw, weightUnit),
        'checked': set?.checked ?? false,
        'supersetGroupId': exercise.supersetGroupId,
        'supersetLabel': exercise.supersetLabel,
        'supersetOrder': exercise.supersetOrder,
      });
    }
  }
  return slots;
}

JournalExercise? watchExercise(List<JournalExercise> exercises) {
  JournalExercise? firstStrength;
  for (final exercise in exercises) {
    if (exercise.isCardio || exercise.isCircuit) continue;
    firstStrength ??= exercise;
    if (_exerciseInProgress(exercise)) return exercise;
  }
  if (firstStrength != null) return firstStrength;
  if (exercises.isEmpty) return null;
  return exercises.first;
}

bool _exerciseInProgress(JournalExercise exercise) {
  if (exercise.sets.isEmpty) return true;
  return exercise.sets.any((set) => !set.checked);
}

/// A phone republish clears a running watch rest only when the workout is
/// locked or the phone cancelled rest. Sending the lineup does not.
bool phonePayloadClearsWatchRest(Map<String, Object?> payload) {
  if (payload['locked'] == true) return true;
  return payload['restCancelled'] == true;
}

/// Slot to keep on screen when a lineup replaces the previous one.
/// The set already showing stays when it is still in the lineup.
int keptWatchSlotIndex({
  required List<Map<String, Object?>> lineup,
  String? currentExerciseId,
  int? currentSetIndex,
}) {
  if (currentExerciseId != null && currentSetIndex != null) {
    for (var i = 0; i < lineup.length; i++) {
      final slot = lineup[i];
      if (slot['exerciseId'] == currentExerciseId && slot['setIndex'] == currentSetIndex) {
        return i;
      }
    }
  }
  final open = lineup.indexWhere(
    (slot) => slot['checked'] != true && slot['done'] != true,
  );
  if (open >= 0) return open;
  if (lineup.isEmpty) return 0;
  return lineup.length - 1;
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
    targetReps: companionReps(repsRaw),
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
  if (message.isStopAlarm) return day;
  if (message.kind == 'skipRest' ||
      message.kind == 'pauseRest' ||
      message.kind == 'resumeRest' ||
      message.kind == 'finishWorkout' ||
      message.kind == 'setRest') {
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
    restRemaining: json['restRemaining'] is num
        ? (json['restRemaining'] as num).round()
        : null,
    restRevision: json['restRev'] is num ? (json['restRev'] as num).round() : null,
  );
}
