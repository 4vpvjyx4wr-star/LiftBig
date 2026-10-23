import '../catalog/liftbig_catalog.dart';
import '../date_key.dart';
import '../ids.dart';
import '../journal/journal_repository.dart';
import '../model/journal_day.dart';

/// Calendar date for workout [planIndex] in a folder-style plan schedule.
String scheduledDateForPlanIndex(
  String startDateKey,
  int planIndex,
  int restEveryWorkoutDays,
) {
  if (restEveryWorkoutDays <= 0) {
    return addDaysToDateKey(startDateKey, planIndex);
  }
  return addDaysToDateKey(
    startDateKey,
    planIndex + (planIndex ~/ restEveryWorkoutDays),
  );
}

class PlanScheduleAssignment {
  const PlanScheduleAssignment({
    required this.dateKey,
    required this.workout,
  });

  final String dateKey;
  final CatalogWorkout workout;
}

/// Builds workout-day assignments for a multi-day plan (Vue folder mode, restEvery 0).
List<PlanScheduleAssignment> buildPlanScheduleAssignments({
  required String startDateKey,
  required List<CatalogWorkout> workouts,
  int restEveryWorkoutDays = 0,
}) {
  return [
    for (var index = 0; index < workouts.length; index++)
      PlanScheduleAssignment(
        dateKey: scheduledDateForPlanIndex(
          startDateKey,
          index,
          restEveryWorkoutDays,
        ),
        workout: workouts[index],
      ),
  ];
}

/// Rest-day keys inserted after every Nth workout when [restEveryWorkoutDays] > 0.
List<String> restDaysAfterWorkouts(
  List<PlanScheduleAssignment> assignments,
  int restEveryWorkoutDays,
) {
  if (restEveryWorkoutDays <= 0 || assignments.length < 2) return const [];
  final restKeys = <String>[];
  for (var i = 0; i < assignments.length - 1; i++) {
    if ((i + 1) % restEveryWorkoutDays == 0) {
      restKeys.add(addDaysToDateKey(assignments[i].dateKey, 1));
    }
  }
  return restKeys;
}

/// Plan name already written onto the calendar.
///
/// Today wins. Otherwise the next upcoming scheduled plan, then the most recent one.
String? calendarPlanName(
  Iterable<({String dateKey, String? planName})> days,
  String today,
) {
  final named = <({String dateKey, String name})>[];
  for (final day in days) {
    final name = day.planName?.trim();
    if (name == null || name.isEmpty || !isValidDateKey(day.dateKey)) continue;
    named.add((dateKey: day.dateKey, name: name));
  }
  if (named.isEmpty) return null;
  named.sort((a, b) => a.dateKey.compareTo(b.dateKey));
  for (final day in named) {
    if (day.dateKey == today) return day.name;
  }
  for (final day in named) {
    if (day.dateKey.compareTo(today) > 0) return day.name;
  }
  return named.last.name;
}

List<JournalExercise> journalExercisesFromCatalogWorkout(CatalogWorkout workout) {
  final exercises = <JournalExercise>[];
  for (var exerciseIndex = 0; exerciseIndex < workout.lifts.length; exerciseIndex++) {
    final lift = workout.lifts[exerciseIndex];
    final sets = lift.sets.isEmpty
        ? [const CatalogSet(reps: '', weight: '')]
        : lift.sets;
    exercises.add(
      JournalExercise(
        id: newId(),
        sortOrder: exerciseIndex,
        name: lift.name,
        libraryId: lift.libraryId,
        isCardio: lift.isCardio,
        isCore: lift.isCore,
        isCircuit: lift.isCircuit,
        targetDuration: lift.targetDuration,
        supersetGroupId: lift.supersetGroupId,
        supersetLabel: lift.supersetLabel,
        supersetOrder: lift.supersetOrder,
        targetRestSeconds: lift.targetRestSeconds,
        sets: [
          for (var setIndex = 0; setIndex < sets.length; setIndex++)
            JournalSet(
              id: newId(),
              sortOrder: setIndex,
              reps: sets[setIndex].reps,
              weight: sets[setIndex].weight,
            ),
        ],
      ),
    );
  }
  return exercises;
}

JournalDay journalDayFromCatalogWorkout({
  required String dateKey,
  required CatalogWorkout workout,
  required String planName,
  required String updatedAt,
  JournalDay? existing,
  bool appendExercises = false,
}) {
  final added = journalExercisesFromCatalogWorkout(workout);
  final exercises = appendExercises && existing != null && existing.exercises.isNotEmpty
      ? [
          ...existing.exercises,
          for (var i = 0; i < added.length; i++)
            added[i].copyWith(sortOrder: existing.exercises.length + i),
        ]
      : added;
  final workoutNotes = workout.notes.trim().isNotEmpty
      ? workout.notes.trim()
      : existing?.workoutNotes;
  return JournalDay(
    dateKey: dateKey,
    updatedAt: updatedAt,
    notes: existing?.notes,
    workoutName: workout.name,
    planName: planName,
    workoutNotes: workoutNotes,
    exercises: exercises,
  );
}

/// Writes each workout on successive calendar days (Vue folder schedule, restEvery 0).
/// Returns how many workout days were written, or null when the user cancels a conflict prompt.
Future<int?> applyPlanScheduleToJournal({
  required JournalRepository journal,
  required String startDateKey,
  required String planName,
  required List<CatalogWorkout> workouts,
  int restEveryWorkoutDays = 0,
  required Future<bool> Function(String message) confirmConflict,
}) async {
  if (workouts.isEmpty || !isValidDateKey(startDateKey)) return 0;

  final assignments = buildPlanScheduleAssignments(
    startDateKey: startDateKey,
    workouts: workouts,
    restEveryWorkoutDays: restEveryWorkoutDays,
  );
  final restKeys = restDaysAfterWorkouts(assignments, restEveryWorkoutDays);
  final touchedKeys = {
    for (final slot in assignments) slot.dateKey,
    ...restKeys,
  };

  var conflict = false;
  for (final key in touchedKeys) {
    final day = await journal.getDay(key);
    if (day != null && day.isRestDay) continue;
    if (day != null && day.exercises.isNotEmpty) {
      conflict = true;
      break;
    }
  }
  if (conflict) {
    final ok = await confirmConflict(
      'Some of these dates already have workouts. Continue and append these plans?',
    );
    if (!ok) return null;
  }

  final stamp = journal.nowStamp();
  final prescribeWarmup = await journal.prescribeWarmupEnabled();
  for (final restKey in restKeys) {
    final day = await journal.getDay(restKey);
    if (day == null || (!day.isRestDay && day.exercises.isEmpty)) {
      await journal.setRestDay(restKey, rest: true);
    }
  }

  for (final slot in assignments) {
    final existing = await journal.getDay(slot.dateKey);
    final append = conflict &&
        existing != null &&
        !existing.isRestDay &&
        existing.exercises.isNotEmpty;
    var built = journalDayFromCatalogWorkout(
      dateKey: slot.dateKey,
      workout: slot.workout,
      planName: planName,
      updatedAt: stamp,
      existing: existing,
      appendExercises: append,
    );
    if (prescribeWarmup) {
      final keptCount = append ? (existing?.exercises.length ?? 0) : 0;
      final kept = built.exercises.take(keptCount).toList();
      final added = built.exercises.skip(keptCount).toList();
      final warmed = await journal.withPrescribedWarmup(
        dateKey: slot.dateKey,
        exercises: added,
        enabled: true,
      );
      built = built.copyWith(exercises: [...kept, ...warmed]);
    }
    await journal.replaceDay(built);
  }

  return assignments.length;
}
