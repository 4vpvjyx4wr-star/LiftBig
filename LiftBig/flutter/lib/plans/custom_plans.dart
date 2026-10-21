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
    sets: [
      for (final item in setsRaw)
        _templateSet(Map<String, Object?>.from(item as Map)),
    ],
  );
}

CatalogSet _templateSet(Map<String, Object?> json) {
  final reps = json['targetReps'] ?? json['reps'];
  final weight = json['targetWeight'] ?? json['weight'];
  return CatalogSet(
    reps: reps is String ? reps : '${reps ?? ''}',
    weight: weight is String ? weight : '${weight ?? ''}',
  );
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
