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
        _workout(Map<String, Object?>.from(item as Map)),
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

CatalogWorkout _workout(Map<String, Object?> json) {
  final folder = json['folderId'];
  return CatalogWorkout(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Workout',
    folderId: folder is String && folder.isNotEmpty ? folder : null,
    notes: json['notes'] as String? ?? '',
    lifts: [
      for (final item in (json['exercises'] as List? ?? const []))
        _catalogLift(Map<String, Object?>.from(item as Map)),
    ],
  );
}

CatalogLift _catalogLift(Map<String, Object?> json) {
  final libraryId = json['libraryId'];
  return CatalogLift(
    name: json['name'] as String? ?? 'Lift',
    libraryId: libraryId is String && libraryId.isNotEmpty ? libraryId : null,
    isCardio: json['isCardio'] == true,
    isCore: json['isCore'] == true,
    isCircuit: json['isCircuit'] == true,
    targetDuration: json['targetDuration'] as String?,
    supersetGroupId: _optionalText(json['supersetGroupId']),
    supersetLabel: _optionalText(json['supersetLabel']),
    supersetOrder: _optionalInt(json['supersetOrder']),
    targetRestSeconds: _optionalInt(json['targetRestSeconds']),
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

/// Search names, tags, equipment, and muscle groups. Empty query keeps [lifts].
List<LibraryLift> searchLifts(List<LibraryLift> lifts, String query) {
  final tokens = query.trim().toLowerCase().split(RegExp(r'\s+')).where((token) {
    return token.isNotEmpty;
  }).toList();
  if (tokens.isEmpty) return lifts;
  return [
    for (final lift in lifts)
      if (tokens.every((token) => _liftHaystack(lift).contains(token))) lift,
  ];
}

String _liftHaystack(LibraryLift lift) {
  return [
    lift.name,
    lift.equipment,
    lift.summary,
    ...lift.tags,
    ...lift.muscleGroups.map((group) => muscleGroupLabels[group] ?? group),
    ...lift.cues,
  ].join(' ').toLowerCase();
}

const _legMuscleGroups = {'quads', 'hamstrings', 'glutes', 'calves', 'legs', 'leg'};
const _pushMuscleGroups = {'chest', 'shoulders', 'triceps'};

/// Add-exercise suggestions: name matches first (prefix before mid-word), then
/// muscle group or tag matches that the name itself does not contain.
List<LibraryLift> rankExerciseSuggestions(List<LibraryLift> lifts, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final prefix = <LibraryLift>[];
  final contains = <LibraryLift>[];
  final related = <LibraryLift>[];
  for (final lift in lifts) {
    final name = lift.name.toLowerCase();
    if (_namePrefixMatch(name, q)) {
      prefix.add(lift);
    } else if (name.contains(q)) {
      contains.add(lift);
    } else if (_muscleOrTagMatches(lift, q)) {
      related.add(lift);
    }
  }
  return [...prefix, ...contains, ...related];
}

bool _namePrefixMatch(String name, String query) {
  if (name.startsWith(query)) return true;
  final words = name.split(RegExp(r'[^a-z0-9]+'));
  return words.any((word) => word.isNotEmpty && word.startsWith(query));
}

bool _muscleOrTagMatches(LibraryLift lift, String query) {
  final groups = lift.muscleGroups.map((group) => group.toLowerCase()).toSet();
  final tags = lift.tags.map((tag) => tag.toLowerCase()).toSet();
  if (query == 'leg' || query == 'legs') {
    if (groups.any(_legMuscleGroups.contains)) return true;
  }
  if (query == 'push') {
    if (tags.contains('push') || groups.any(_pushMuscleGroups.contains)) {
      return true;
    }
  }
  if (tags.any((tag) => tag.contains(query))) return true;
  if (groups.any((group) => group.contains(query))) return true;
  for (final group in groups) {
    final label = (muscleGroupLabels[group] ?? group).toLowerCase();
    if (label.contains(query)) return true;
  }
  return false;
}
