import 'dart:convert';

import '../catalog/liftbig_catalog.dart';
import '../journal/journal_repository.dart';

/// User-owned plans from local `templates_json` settings and journal plan names.
Future<List<PremadePlan>> loadCustomPlans({
  required JournalRepository journal,
  required LiftBigCatalog catalog,
}) async {
  final settings = await journal.localCloudSettings();
  final fromTemplates = parseCustomPlansFromTemplatesJson(
    settings?.templatesJson,
    catalog,
  );
  final catalogPlanNames = {
    for (final plan in catalog.plans) plan.name.toLowerCase(),
  };
  final seen = {for (final plan in fromTemplates) plan.name.toLowerCase()};

  final journalNames = await journal.distinctLoggedPlanNames();
  final merged = [...fromTemplates];
  for (final name in journalNames) {
    final key = name.toLowerCase();
    if (catalogPlanNames.contains(key) || seen.contains(key)) continue;
    seen.add(key);
    merged.add(
      PremadePlan(
        id: 'journal:$key',
        name: name,
        purpose: 'Seen on your calendar',
        workouts: const [],
      ),
    );
  }
  merged.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return merged;
}

/// Favorites keep their relative order and sit above every other plan.
List<PremadePlan> plansWithFavoritesFirst(
  List<PremadePlan> plans,
  Set<String> favoriteIds,
) {
  if (favoriteIds.isEmpty || plans.length < 2) return plans;
  final favorites = <PremadePlan>[];
  final others = <PremadePlan>[];
  for (final plan in plans) {
    if (favoriteIds.contains(plan.id)) {
      favorites.add(plan);
    } else {
      others.add(plan);
    }
  }
  if (favorites.isEmpty) return plans;
  return [...favorites, ...others];
}

List<PremadePlan> parseCustomPlansFromTemplatesJson(
  String? raw,
  LiftBigCatalog catalog,
) {
  if (raw == null || raw.trim().isEmpty) return const [];

  final catalogFolderIds = catalog.plans.map((plan) => plan.id).toSet();
  final catalogWorkoutIds = {
    for (final workout in catalog.starterWorkouts) workout.id,
    for (final plan in catalog.plans)
      for (final workout in plan.workouts) workout.id,
  };

  try {
    final decoded = jsonDecode(raw);
    final templates = <Map<String, Object?>>[];
    final folders = <Map<String, Object?>>[];

    if (decoded is List) {
      for (final item in decoded) {
        if (item is Map) {
          templates.add(Map<String, Object?>.from(item));
        }
      }
    } else if (decoded is Map) {
      final map = Map<String, Object?>.from(decoded);
      for (final item in (map['templates'] as List? ?? const [])) {
        if (item is Map) templates.add(Map<String, Object?>.from(item));
      }
      for (final item in (map['folders'] as List? ?? const [])) {
        if (item is Map) folders.add(Map<String, Object?>.from(item));
      }
    } else {
      return const [];
    }

    final workoutsByFolder = <String, List<CatalogWorkout>>{};
    final standalone = <CatalogWorkout>[];

    for (final map in templates) {
      final id = map['id'] as String? ?? '';
      if (id.isEmpty || catalogWorkoutIds.contains(id)) continue;
      final workout = _templateWorkout(map);
      final folderId = workout.folderId;
      if (folderId != null && folderId.isNotEmpty) {
        workoutsByFolder.putIfAbsent(folderId, () => []).add(workout);
      } else {
        standalone.add(workout);
      }
    }

    final plans = <PremadePlan>[];
    for (final map in folders) {
      final id = map['id'] as String? ?? '';
      if (id.isEmpty || catalogFolderIds.contains(id)) continue;
      final sessions = workoutsByFolder.remove(id);
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

    for (final entry in workoutsByFolder.entries) {
      if (catalogFolderIds.contains(entry.key)) continue;
      plans.add(
        PremadePlan(
          id: entry.key,
          name: entry.key,
          purpose: '',
          workouts: entry.value,
        ),
      );
    }

    for (final workout in standalone) {
      plans.add(
        PremadePlan(
          id: workout.id,
          name: workout.name,
          purpose: workout.notes,
          workouts: [workout],
        ),
      );
    }

    plans.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return plans;
  } catch (_) {
    return const [];
  }
}

CatalogWorkout _templateWorkout(Map<String, Object?> json) {
  final folder = json['folderId'];
  return CatalogWorkout(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Workout',
    folderId: folder is String && folder.isNotEmpty ? folder : null,
    notes: json['notes'] as String? ?? '',
    lifts: [
      for (final item in (json['exercises'] as List? ?? const []))
        _templateLift(Map<String, Object?>.from(item as Map)),
    ],
  );
}

CatalogLift _templateLift(Map<String, Object?> json) {
  final libraryId = json['libraryId'];
  final setsRaw = json['sets'] as List? ?? const [];
  return CatalogLift(
    name: json['name'] as String? ?? 'Lift',
    libraryId: libraryId is String && libraryId.isNotEmpty ? libraryId : null,
    isCardio: json['isCardio'] == true,
    isCore: json['isCore'] == true,
    isCircuit: json['isCircuit'] == true,
    targetDuration: json['targetDuration'] as String?,
    supersetGroupId: _optionalPlanText(json['supersetGroupId']),
    supersetLabel: _optionalPlanText(json['supersetLabel']),
    supersetOrder: _optionalPlanInt(json['supersetOrder']),
    sets: [
      for (final item in setsRaw)
        _templateSet(Map<String, Object?>.from(item as Map)),
    ],
  );
}

String? _optionalPlanText(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _optionalPlanInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.round();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}

CatalogSet _templateSet(Map<String, Object?> json) {
  final reps = json['targetReps'] ?? json['reps'];
  final weight = json['targetWeight'] ?? json['weight'];
  return CatalogSet(
    reps: reps is String ? reps : '${reps ?? ''}',
    weight: weight is String ? weight : '${weight ?? ''}',
  );
}

const defaultBuiltSetCount = 3;
const defaultBuiltReps = '8-12';

/// One exercise in a user-built plan, with the sets and target reps to write.
class BuiltPlanExercise {
  const BuiltPlanExercise({
    required this.lift,
    this.setCount = defaultBuiltSetCount,
    this.targetReps = defaultBuiltReps,
  });

  final LibraryLift lift;
  final int setCount;
  final String targetReps;
}

class BuiltPlanWorkout {
  const BuiltPlanWorkout({
    required this.name,
    this.lifts = const [],
    this.exercises = const [],
  });

  final String name;

  /// Lifts that use the default set count and target reps.
  /// Ignored when [exercises] is not empty.
  final List<LibraryLift> lifts;

  /// Exercises with their own set count and target reps.
  final List<BuiltPlanExercise> exercises;
}

List<BuiltPlanExercise> _prescribedExercises(BuiltPlanWorkout workout) {
  if (workout.exercises.isNotEmpty) return workout.exercises;
  return [
    for (final lift in workout.lifts) BuiltPlanExercise(lift: lift),
  ];
}

int _builtSetCount(int count) {
  if (count < 1) return defaultBuiltSetCount;
  if (count > 30) return 30;
  return count;
}

String _builtTargetReps(String reps) {
  final trimmed = reps.trim();
  return trimmed.isEmpty ? defaultBuiltReps : trimmed;
}

/// Appends a user-built plan to the `templates_json` payload Custom Plans reads.
/// Returns null when [existing] is not empty and is not a JSON list or object.
String? appendBuiltPlanToTemplatesJson({
  required String? existing,
  required String planName,
  required List<BuiltPlanWorkout> workouts,
  required String Function() createId,
}) {
  final name = planName.trim();
  if (name.isEmpty) return null;
  final sessions = <({String name, List<BuiltPlanExercise> exercises})>[];
  for (final workout in workouts) {
    final exercises = _prescribedExercises(workout);
    if (exercises.isEmpty) continue;
    final workoutName = workout.name.trim();
    sessions.add((
      name: workoutName.isEmpty ? 'Workout' : workoutName,
      exercises: exercises,
    ));
  }
  if (sessions.isEmpty) return null;

  final decoded = _decodeTemplatesPayload(existing);
  if (decoded == null) return null;
  final templates = decoded.templates;
  final folders = decoded.folders;
  final planId = createId();
  folders.add({
    'id': planId,
    'name': name,
    'purpose': 'Built by you',
  });
  for (var i = 0; i < sessions.length; i++) {
    final session = sessions[i];
    templates.add({
      'id': createId(),
      'name': session.name,
      'folderId': planId,
      'notes': '',
      'exercises': [
        for (final exercise in session.exercises)
          {
            'name': exercise.lift.name,
            'libraryId': exercise.lift.id,
            'isCardio': exercise.lift.isCardio,
            'isCore': exercise.lift.isCore,
            'isCircuit': false,
            'sets': [
              for (var set = 0; set < _builtSetCount(exercise.setCount); set++)
                {
                  'targetReps': _builtTargetReps(exercise.targetReps),
                  'targetWeight': '',
                },
            ],
          },
      ],
    });
  }
  return jsonEncode({'templates': templates, 'folders': folders});
}

({List<Object?> templates, List<Object?> folders})? _decodeTemplatesPayload(String? existing) {
  if (existing == null || existing.trim().isEmpty) {
    return (templates: <Object?>[], folders: <Object?>[]);
  }
  try {
    final decoded = jsonDecode(existing);
    if (decoded is List) {
      return (templates: List<Object?>.from(decoded), folders: <Object?>[]);
    }
    if (decoded is Map) {
      final map = Map<String, Object?>.from(decoded);
      final templates = map['templates'];
      final folders = map['folders'];
      return (
        templates: templates is List ? List<Object?>.from(templates) : <Object?>[],
        folders: folders is List ? List<Object?>.from(folders) : <Object?>[],
      );
    }
  } catch (_) {
    return null;
  }
  return null;
}

bool planMatchesSearch(PremadePlan plan, LiftBigCatalog catalog, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (plan.name.toLowerCase().contains(q)) return true;
  if (plan.purpose.toLowerCase().contains(q)) return true;
  for (final workout in plan.workouts) {
    if (workout.name.toLowerCase().contains(q)) return true;
    if (workout.notes.toLowerCase().contains(q)) return true;
    for (final lift in workout.lifts) {
      if (lift.name.toLowerCase().contains(q)) return true;
      final libraryId = lift.libraryId;
      if (libraryId == null) continue;
      final library = catalog.liftById(libraryId);
      if (library == null) continue;
      for (final group in library.muscleGroups) {
        if (group.toLowerCase().contains(q)) return true;
        final label = muscleGroupLabels[group];
        if (label != null && label.toLowerCase().contains(q)) return true;
      }
      for (final tag in library.tags) {
        if (tag.toLowerCase().contains(q)) return true;
      }
    }
  }
  return false;
}
