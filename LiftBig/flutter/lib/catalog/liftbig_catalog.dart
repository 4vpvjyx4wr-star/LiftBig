import 'dart:convert';

import 'package:flutter/services.dart';

/// One lift from the Vue exercise catalog. Lift and exercise are the same activity.
class LibraryLift {
  const LibraryLift({
    required this.id,
    required this.name,
    required this.muscleGroups,
    required this.tags,
    required this.equipment,
    required this.summary,
    required this.instructions,
    required this.tips,
    required this.cues,
    required this.tutorialUrl,
    required this.isCardio,
    required this.repBasedCore,
  });

  final String id;
  final String name;
  final List<String> muscleGroups;
  final List<String> tags;
  final String equipment;
  final String summary;
  final List<String> instructions;
  final List<String> tips;
  final List<String> cues;
  final String tutorialUrl;
  final bool isCardio;
  final bool repBasedCore;

  bool get isCore => muscleGroups.contains('core') || repBasedCore;
}

class CatalogWorkout {
  const CatalogWorkout({
    required this.id,
    required this.name,
    required this.folderId,
    required this.notes,
    required this.lifts,
  });

  final String id;
  final String name;
  final String? folderId;
  final String notes;
  final List<CatalogLift> lifts;
}

class CatalogLift {
  const CatalogLift({
    required this.name,
    required this.libraryId,
    required this.isCardio,
    required this.isCore,
    required this.isCircuit,
    required this.targetDuration,
    required this.sets,
    this.supersetGroupId,
    this.supersetLabel,
    this.supersetOrder,
    this.targetRestSeconds,
    this.preferredSwapLibraryIds = const [],
  });

  final String name;
  final String? libraryId;
  final bool isCardio;
  final bool isCore;
  final bool isCircuit;
  final String? targetDuration;
  final List<CatalogSet> sets;
  final String? supersetGroupId;
  final String? supersetLabel;
  final int? supersetOrder;
  final int? targetRestSeconds;
  final List<String> preferredSwapLibraryIds;
}

class CatalogSet {
  const CatalogSet({required this.reps, required this.weight});

  final String reps;
  final String weight;
}

class PremadePlan {
  const PremadePlan({
    required this.id,
    required this.name,
    required this.purpose,
    required this.workouts,
  });

  final String id;
  final String name;
  final String purpose;
  final List<CatalogWorkout> workouts;
}

class QuizEntry {
  const QuizEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.experienceLevels,
    required this.goals,
    required this.days,
    required this.duration,
    required this.equipment,
    required this.styles,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.primaryMuscles,
    required this.progressionStyle,
    required this.goalTag,
    required this.category,
    required this.workoutIds,
  });

  final String id;
  final String title;
  final String description;
  final List<String> experienceLevels;
  final List<String> goals;
  final List<int> days;
  final List<String> duration;
  final List<String> equipment;
  final List<String> styles;
  final String difficulty;
  final int estimatedMinutes;
  final List<String> primaryMuscles;
  final String progressionStyle;
  final String goalTag;
  final String category;
  final List<String> workoutIds;
}

class LiftBigCatalog {
  const LiftBigCatalog({
    required this.lifts,
    required this.plans,
    required this.starterWorkouts,
    required this.quiz,
  });

  final List<LibraryLift> lifts;
  final List<PremadePlan> plans;
  final List<CatalogWorkout> starterWorkouts;
  final List<QuizEntry> quiz;

  LibraryLift? liftById(String id) {
    for (final lift in lifts) {
      if (lift.id == id) return lift;
    }
    return null;
  }

  CatalogWorkout? workoutById(String id) {
    for (final plan in plans) {
      for (final workout in plan.workouts) {
        if (workout.id == id) return workout;
      }
    }
    for (final workout in starterWorkouts) {
      if (workout.id == id) return workout;
    }
    return null;
  }

  List<String> get equipmentTypes {
    final types = <String>{
      for (final lift in lifts)
        if (lift.equipment.trim().isNotEmpty) lift.equipment.trim(),
    };
    final sorted = types.toList()..sort();
    return sorted;
  }

  static Future<LiftBigCatalog>? _loading;

  /// Clears a failed load so the next call reads the asset again.
  static void resetLoadCache() {
    _loading = null;
  }

  static Future<LiftBigCatalog> load() {
    final pending = _loading;
    if (pending != null) return pending;
    final future = _read();
    _loading = future;
    return future.catchError((Object error, StackTrace stack) {
      resetLoadCache();
      Error.throwWithStackTrace(error, stack);
    });
  }

  static Future<LiftBigCatalog> _read() async {
    const assetPath = 'assets/liftbig_catalog.json';
    final raw = await rootBundle.loadString(assetPath);
    if (raw.trim().isEmpty) {
      throw FormatException('$assetPath is empty.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('liftbig_catalog.json must be a JSON object.');
    }
    final json = Map<String, Object?>.from(decoded);
    final lifts = [
      for (final item in json['lifts'] as List)
        _lift(Map<String, Object?>.from(item as Map)),
    ];
    final workouts = [
      for (final item in json['workouts'] as List)
        _workout(Map<String, Object?>.from(item as Map), lifts),
    ];
    final byFolder = <String, List<CatalogWorkout>>{};
    final starters = <CatalogWorkout>[];
    for (final workout in workouts) {
      final folderId = workout.folderId;
      if (folderId == null || folderId.isEmpty) {
        starters.add(workout);
      } else {
        byFolder.putIfAbsent(folderId, () => []).add(workout);
      }
    }
    final plans = <PremadePlan>[];
    for (final item in json['folders'] as List) {
      final map = Map<String, Object?>.from(item as Map);
      final id = map['id'] as String;
      final sessions = byFolder[id];
      if (sessions == null || sessions.isEmpty) continue;
      plans.add(
        PremadePlan(
          id: id,
          name: map['name'] as String? ?? id,
          purpose: map['purpose'] as String? ?? '',
          workouts: sessions,
        ),
      );
    }
    plans.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final quiz = [
      for (final item in json['quiz'] as List)
        _quiz(Map<String, Object?>.from(item as Map)),
    ];
    return LiftBigCatalog(
      lifts: lifts,
      plans: plans,
      starterWorkouts: starters,
      quiz: quiz,
    );
  }
}

LibraryLift _lift(Map<String, Object?> json) {
  return LibraryLift(
    id: json['id'] as String,
    name: json['name'] as String,
    muscleGroups: _strings(json['muscleGroups']),
    tags: _strings(json['tags']),
    equipment: json['equipment'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    instructions: _strings(json['instructions']),
    tips: _strings(json['tips']),
    cues: _strings(json['cues']),
    tutorialUrl: json['tutorialUrl'] as String? ?? '',
    isCardio: json['isCardio'] == true,
    repBasedCore: json['repBasedCore'] == true,
  );
}

CatalogWorkout _workout(Map<String, Object?> json, List<LibraryLift> lifts) {
  final folder = json['folderId'];
  return CatalogWorkout(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Workout',
    folderId: folder is String && folder.isNotEmpty ? folder : null,
    notes: json['notes'] as String? ?? '',
    lifts: [
      for (final item in (json['exercises'] as List? ?? const []))
        _catalogLift(Map<String, Object?>.from(item as Map), lifts),
    ],
  );
}

String _catalogFoldKey(String name) {
  final key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  if (key.length > 3 && key.endsWith('s')) return key.substring(0, key.length - 1);
  return key;
}

LibraryLift? _singleFoldMatch(String name, List<LibraryLift> lifts) {
  final exactKey = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  if (exactKey.isEmpty) return null;
  final exact = [
    for (final lift in lifts)
      if (lift.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '') == exactKey)
        lift,
  ];
  if (exact.length == 1) return exact.single;
  if (exact.length > 1) return null;
  final foldedKey = _catalogFoldKey(name);
  final folded = [
    for (final lift in lifts)
      if (_catalogFoldKey(lift.name) == foldedKey) lift,
  ];
  if (folded.length == 1) return folded.single;
  return null;
}

CatalogLift _catalogLift(Map<String, Object?> json, List<LibraryLift> lifts) {
  final rawId = json['libraryId'] == 'deadbug' ? 'dead-bug' : json['libraryId'];
  final written = json['name'] as String? ?? 'Lift';
  LibraryLift? linked;
  if (rawId is String && rawId.isNotEmpty) {
    for (final lift in lifts) {
      if (lift.id == rawId) {
        linked = lift;
        break;
      }
    }
  }
  final folded = _singleFoldMatch(written, lifts);
  final String name;
  final String? libraryId;
  if (linked != null && _catalogFoldKey(written) == _catalogFoldKey(linked.name)) {
    name = linked.name;
    libraryId = linked.id;
  } else if (linked == null && folded != null && (rawId is! String || rawId.isEmpty)) {
    name = folded.name;
    libraryId = folded.id;
  } else {
    name = written;
    libraryId = linked?.id ?? (rawId is String && rawId.isNotEmpty ? rawId : null);
  }
  return CatalogLift(
    name: name,
    libraryId: libraryId,
    isCardio: json['isCardio'] == true,
    isCore: json['isCore'] == true,
    isCircuit: json['isCircuit'] == true,
    targetDuration: json['targetDuration'] as String?,
    supersetGroupId: _optionalText(json['supersetGroupId']),
    supersetLabel: _optionalText(json['supersetLabel']),
    supersetOrder: _optionalInt(json['supersetOrder']),
    targetRestSeconds: _optionalInt(json['targetRestSeconds']),
    preferredSwapLibraryIds: _strings(json['preferredSwapLibraryIds']),
    sets: [
      for (final item in (json['sets'] as List? ?? const []))
        _catalogSet(Map<String, Object?>.from(item as Map)),
    ],
  );
}

CatalogSet _catalogSet(Map<String, Object?> json) {
  return CatalogSet(
    reps: json['reps'] as String? ?? '',
    weight: json['weight'] as String? ?? '',
  );
}

List<int> _quizDays(Object? raw) {
  if (raw is int) return [raw];
  if (raw is num) return [raw.round()];
  if (raw is! List) return const [];
  return [
    for (final day in raw)
      day is int ? day : int.tryParse('$day') ?? 0,
  ];
}

QuizEntry _quiz(Map<String, Object?> json) {
  final id = json['id'];
  if (id is! String || id.isEmpty) {
    throw FormatException('Quiz entry is missing a string id.');
  }
  return QuizEntry(
    id: id,
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    experienceLevels: _strings(json['experienceLevels']),
    goals: _strings(json['goals']),
    days: _quizDays(json['days']),
    duration: _strings(json['duration']),
    equipment: _strings(json['equipment']),
    styles: _strings(json['styles']),
    difficulty: json['difficulty'] as String? ?? '',
    estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
    primaryMuscles: _strings(json['primaryMuscles']),
    progressionStyle: json['progressionStyle'] as String? ?? '',
    goalTag: json['goalTag'] as String? ?? '',
    category: json['category'] as String? ?? '',
    workoutIds: _strings(json['workoutIds']),
  );
}

String? _optionalText(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _optionalInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}

List<String> _strings(Object? raw) {
  if (raw is! List) return const [];
  return [for (final item in raw) item.toString()];
}

const muscleGroupLabels = <String, String>{
  'chest': 'Chest',
  'back': 'Back',
  'shoulders': 'Shoulders',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'quads': 'Quads',
  'hamstrings': 'Hamstrings',
  'glutes': 'Glutes',
  'calves': 'Calves',
  'core': 'Core',
  'forearms': 'Forearms',
};

