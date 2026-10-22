import 'dart:convert';

/// Stored difficulty values. Unset means the lifter did not rate the set.
const String setDifficultyEasy = 'Easy';
const String setDifficultyModerate = 'Moderate';
const String setDifficultyDifficult = 'Difficult';

/// Easy, Moderate, or Difficult. Anything else, including empty, is unset.
String? canonicalSetDifficulty(Object? raw) {
  final text = raw is String ? raw.trim().toLowerCase() : '';
  if (text == 'easy') return setDifficultyEasy;
  if (text == 'moderate' || text == 'mod') return setDifficultyModerate;
  if (text == 'difficult' || text == 'hard') return setDifficultyDifficult;
  return null;
}

/// One logged set. [weight] is pounds, stored as a string the way the Vue app does.
class JournalSet {
  const JournalSet({
    required this.id,
    required this.sortOrder,
    required this.reps,
    required this.weight,
    this.durationSeconds,
    this.checked = false,
    this.isWarmup = false,
    this.difficulty,
  });

  final String id;
  final int sortOrder;
  final String reps;
  final String weight;
  final String? durationSeconds;
  final bool checked;
  final bool isWarmup;

  /// Null until the lifter taps Easy, Moderate, or Difficult.
  final String? difficulty;

  Map<String, Object?> toMap() {
    final rating = canonicalSetDifficulty(difficulty);
    return {
      'id': id,
      'sortOrder': sortOrder,
      'reps': reps,
      'weight': weight,
      'durationSeconds': durationSeconds,
      'checked': checked,
      'isWarmup': isWarmup,
      'difficulty': ? rating,
    };
  }

  static JournalSet fromMap(Map<String, Object?> json, int fallbackOrder) {
    return JournalSet(
      id: _string(json['id']) ?? '',
      sortOrder: _int(json['sortOrder']) ?? fallbackOrder,
      reps: _string(json['reps']) ?? _numAsString(json['reps']),
      weight: _string(json['weight']) ?? _numAsString(json['weight']),
      durationSeconds: _string(json['durationSeconds']),
      checked: json['checked'] == true,
      isWarmup: json['isWarmup'] == true,
      difficulty: canonicalSetDifficulty(json['difficulty']),
    );
  }
}

/// One exercise on a day, including the set rows that belong to it.
class JournalExercise {
  const JournalExercise({
    required this.id,
    required this.sortOrder,
    required this.name,
    required this.sets,
    this.libraryId,
    this.notes,
    this.isCircuit = false,
    this.isCardio = false,
    this.isCore = false,
    this.targetDuration,
    this.targetTimeSeconds,
    this.targetDistance,
    this.loggedCalories,
    this.targetReps,
    this.targetWeight,
    this.supersetGroupId,
    this.supersetLabel,
    this.supersetOrder,
    this.preferredSwapLibraryIds = const [],
    this.targetRestSeconds,
    this.prescribedReps,
    this.prescribedWeight,
    this.prescribedSetCount,
  });

  final String id;
  final int sortOrder;
  final String name;
  final String? libraryId;
  final String? notes;
  final bool isCircuit;
  final bool isCardio;
  final bool isCore;
  final String? targetDuration;
  final String? targetTimeSeconds;
  final String? targetDistance;
  final String? loggedCalories;
  final String? targetReps;
  final String? targetWeight;
  final String? supersetGroupId;
  final String? supersetLabel;
  final int? supersetOrder;
  final List<String> preferredSwapLibraryIds;
  final int? targetRestSeconds;

  /// Plan or progressive-overload goal captured the first time it is edited.
  final String? prescribedReps;
  final String? prescribedWeight;
  final int? prescribedSetCount;
  final List<JournalSet> sets;

  JournalExercise copyWith({
    int? sortOrder,
    List<JournalSet>? sets,
    String? notes,
    bool setNotes = false,
    String? name,
    String? targetReps,
    String? targetWeight,
    bool setTargetReps = false,
    bool setTargetWeight = false,
    String? prescribedReps,
    String? prescribedWeight,
    int? prescribedSetCount,
    bool setPrescription = false,
    String? supersetGroupId,
    String? supersetLabel,
    int? supersetOrder,
    bool setSuperset = false,
  }) {
    return JournalExercise(
      id: id,
      sortOrder: sortOrder ?? this.sortOrder,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      libraryId: libraryId,
      notes: setNotes ? notes : this.notes,
      isCircuit: isCircuit,
      isCardio: isCardio,
      isCore: isCore,
      targetDuration: targetDuration,
      targetTimeSeconds: targetTimeSeconds,
      targetDistance: targetDistance,
      loggedCalories: loggedCalories,
      targetReps: setTargetReps ? targetReps : this.targetReps,
      targetWeight: setTargetWeight ? targetWeight : this.targetWeight,
      supersetGroupId: setSuperset ? supersetGroupId : this.supersetGroupId,
      supersetLabel: setSuperset ? supersetLabel : this.supersetLabel,
      supersetOrder: setSuperset ? supersetOrder : this.supersetOrder,
      preferredSwapLibraryIds: preferredSwapLibraryIds,
      targetRestSeconds: targetRestSeconds,
      prescribedReps: setPrescription ? prescribedReps : this.prescribedReps,
      prescribedWeight: setPrescription ? prescribedWeight : this.prescribedWeight,
      prescribedSetCount: setPrescription
          ? prescribedSetCount
          : this.prescribedSetCount,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'sortOrder': sortOrder,
      'name': name,
      'libraryId': libraryId,
      'notes': notes,
      'isCircuit': isCircuit,
      'isCardio': isCardio,
      'isCore': isCore,
      'targetDuration': targetDuration,
      'targetTimeSeconds': targetTimeSeconds,
      'targetDistance': targetDistance,
      'loggedCalories': loggedCalories,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'supersetGroupId': supersetGroupId,
      'supersetLabel': supersetLabel,
      'supersetOrder': supersetOrder,
      'preferredSwapLibraryIds': preferredSwapLibraryIds,
      'targetRestSeconds': targetRestSeconds,
      'prescribedReps': prescribedReps,
      'prescribedWeight': prescribedWeight,
      'prescribedSetCount': prescribedSetCount,
      'sets': sets.map((set) => set.toMap()).toList(),
    };
  }

  static JournalExercise fromMap(Map<String, Object?> json, int fallbackOrder) {
    final rawSets = json['sets'];
    final sets = <JournalSet>[];
    if (rawSets is List) {
      for (var i = 0; i < rawSets.length; i++) {
        final item = rawSets[i];
        if (item is Map) {
          sets.add(JournalSet.fromMap(Map<String, Object?>.from(item), i));
        }
      }
    }
    return JournalExercise(
      id: _string(json['id']) ?? '',
      sortOrder: _int(json['sortOrder']) ?? fallbackOrder,
      name: _string(json['name']) ?? '',
      libraryId: _string(json['libraryId']),
      notes: _string(json['notes']),
      isCircuit: json['isCircuit'] == true,
      isCardio: json['isCardio'] == true,
      isCore: json['isCore'] == true,
      targetDuration: _string(json['targetDuration']),
      targetTimeSeconds: _string(json['targetTimeSeconds']),
      targetDistance: _string(json['targetDistance']),
      loggedCalories: _string(json['loggedCalories']),
      targetReps: _string(json['targetReps']),
      targetWeight: _string(json['targetWeight']),
      supersetGroupId: _string(json['supersetGroupId']),
      supersetLabel: _string(json['supersetLabel']),
      supersetOrder: _int(json['supersetOrder']),
      preferredSwapLibraryIds: _stringList(json['preferredSwapLibraryIds']),
      targetRestSeconds: _int(json['targetRestSeconds']),
      prescribedReps: _string(json['prescribedReps']),
      prescribedWeight: _string(json['prescribedWeight']),
      prescribedSetCount: _int(json['prescribedSetCount']),
      sets: sets,
    );
  }
}

/// One calendar day. The date key is the primary key.
class JournalDay {
  const JournalDay({
    required this.dateKey,
    required this.updatedAt,
    required this.exercises,
    this.notes,
    this.isRestDay = false,
    this.workoutName,
    this.planName,
    this.workoutNotes,
    this.chosenRestSeconds,
    this.healthEnergyKcal,
  });

  final String dateKey;
  final String? notes;
  final bool isRestDay;

  /// Session used for this day. Not the Plan.
  final String? workoutName;

  /// Plan that [workoutName] belonged to.
  final String? planName;

  /// Coaching notes copied from that workout.
  final String? workoutNotes;

  /// Rest length chosen on this day. Null uses the settings average.
  final int? chosenRestSeconds;

  /// Active energy from Apple Health or Health Connect. Null when none was recorded.
  final double? healthEnergyKcal;
  final String updatedAt;
  final List<JournalExercise> exercises;

  JournalDay copyWith({
    String? notes,
    bool? isRestDay,
    String? workoutName,
    String? planName,
    String? workoutNotes,
    String? updatedAt,
    List<JournalExercise>? exercises,
    bool clearNotes = false,
    bool clearWorkoutName = false,
    int? chosenRestSeconds,
    double? healthEnergyKcal,
    bool setChosenRest = false,
    bool setHealthEnergy = false,
  }) {
    return JournalDay(
      dateKey: dateKey,
      notes: clearNotes ? null : (notes ?? this.notes),
      isRestDay: isRestDay ?? this.isRestDay,
      workoutName: clearWorkoutName ? null : (workoutName ?? this.workoutName),
      planName: planName ?? this.planName,
      workoutNotes: workoutNotes ?? this.workoutNotes,
      chosenRestSeconds: setChosenRest
          ? chosenRestSeconds
          : this.chosenRestSeconds,
      healthEnergyKcal: setHealthEnergy ? healthEnergyKcal : this.healthEnergyKcal,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'dateKey': dateKey,
      'notes': notes,
      'isRestDay': isRestDay,
      'workoutName': workoutName,
      'planName': planName,
      'workoutNotes': workoutNotes,
      'chosenRestSeconds': chosenRestSeconds,
      'healthEnergyKcal': healthEnergyKcal,
      'updatedAt': updatedAt,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
    };
  }

  static JournalDay? fromMap(Map<String, Object?> json) {
    final dateKey = _string(json['dateKey']);
    if (dateKey == null || dateKey.isEmpty) return null;
    final rawExercises = json['exercises'];
    final exercises = <JournalExercise>[];
    if (rawExercises is List) {
      for (var i = 0; i < rawExercises.length; i++) {
        final item = rawExercises[i];
        if (item is Map) {
          exercises.add(
            JournalExercise.fromMap(Map<String, Object?>.from(item), i),
          );
        }
      }
    }
    return JournalDay(
      dateKey: dateKey,
      notes: _string(json['notes']),
      isRestDay: json['isRestDay'] == true,
      workoutName: _string(json['workoutName']),
      planName: _string(json['planName']),
      workoutNotes: _string(json['workoutNotes']),
      chosenRestSeconds: _int(json['chosenRestSeconds']),
      healthEnergyKcal: _double(json['healthEnergyKcal']),
      updatedAt: _string(json['updatedAt']) ?? '',
      exercises: exercises,
    );
  }
}

/// Calendar cell data loaded from SQL.
class DaySummary {
  const DaySummary({
    required this.dateKey,
    required this.isRestDay,
    required this.exerciseCount,
    this.workoutName,
  });

  final String dateKey;
  final bool isRestDay;
  final String? workoutName;
  final int exerciseCount;

  bool get hasWorkout => exerciseCount > 0;
}

/// Optional cloud copy of non-day settings. The sync switch itself stays local.
class CloudSettings {
  const CloudSettings({
    required this.updatedAt,
    this.weightUnit,
    this.bodyWeightLbs,
    this.templatesJson,
    this.settingsJson,
  });

  final String updatedAt;
  final String? weightUnit;
  final double? bodyWeightLbs;
  final String? templatesJson;
  final String? settingsJson;

  Map<String, Object?> toMap() {
    return {
      'updatedAt': updatedAt,
      'weightUnit': weightUnit,
      'bodyWeightLbs': bodyWeightLbs,
      'templatesJson': templatesJson,
      'settingsJson': settingsJson,
    };
  }

  static CloudSettings? fromMap(Map<String, Object?> json) {
    final updatedAt = _string(json['updatedAt']);
    if (updatedAt == null || updatedAt.isEmpty) return null;
    return CloudSettings(
      updatedAt: updatedAt,
      weightUnit: _string(json['weightUnit']),
      bodyWeightLbs: _double(json['bodyWeightLbs']),
      templatesJson: _string(json['templatesJson']),
      settingsJson: _string(json['settingsJson']),
    );
  }
}

String? encodeStringList(List<String> values) {
  if (values.isEmpty) return null;
  return jsonEncode(values);
}

List<String> decodeStringList(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.whereType<String>().toList();
    }
  } catch (_) {
    return const [];
  }
  return const [];
}

String? _string(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : value;
  }
  return null;
}

String _numAsString(Object? value) {
  if (value is num) return value.toString();
  return '';
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}
