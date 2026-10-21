import 'package:drift/drift.dart';

import '../backup/backup_parser.dart';
import '../catalog/liftbig_catalog.dart';
import '../data/app_database.dart';
import '../date_key.dart';
import '../ids.dart';
import '../model/journal_day.dart';
import '../reminder/daily_lift_reminder.dart';
import '../rest/rest_timer_state.dart';
import '../utils/distance_units.dart';
import '../utils/variable_machine.dart';
import '../utils/weight_units.dart';
import 'app_settings.dart';
import 'lift_name_convergence.dart';
import 'logged_day.dart';
import 'progressive_overload.dart';
import 'warmup_prescription.dart';
import '../companion/watch_session.dart';
/// A note saved on an earlier day for the same lift.
class PriorExerciseNote {
  const PriorExerciseNote({required this.dateKey, required this.text});

  final String dateKey;
  final String text;
}

/// Local keys. The sync switch is never uploaded.
abstract final class SettingKeys {
  static const syncEnabled = 'sync_enabled';
  static const settingsUpdatedAt = 'settings_updated_at';
  static const weightUnit = 'weight_unit';
  static const distanceUnit = 'distance_unit';
  static const bodyWeightLbs = 'body_weight_lbs';
  static const heightInches = 'height_inches';
  static const prescribeWarmup = 'prescribe_warmup_sets';
  static const averageRestSeconds = 'average_rest_seconds';
  static const averageLiftSeconds = 'average_lift_seconds';
  static const restTimerSound = 'rest_timer_sound';
  static const restTimerVibration = 'rest_timer_vibration';
  static const restTimerNotification = 'rest_timer_notification';
  static const appleHealthEnabled = 'apple_health_enabled';
  static const templatesJson = 'templates_json';
  static const settingsJson = 'settings_json';
  static const autoFillSets = 'auto_fill_sets';
  static const startTimerOnDone = 'start_timer_on_done';
  static const logSetDifficulty = 'log_set_difficulty';
  static const proTesterUnlock = 'pro_tester_unlock';
  static const restTimerState = 'rest_timer_state';
  static const dailyLiftReminderEnabled = 'daily_lift_reminder_enabled';
  static const dailyLiftReminderTime = 'daily_lift_reminder_time';
  static const dailyLiftReminderDays = 'daily_lift_reminder_days';
  static const dailyLiftReminderMessage = 'daily_lift_reminder_message';
  static const machineStartSmithLb = 'machine_start_lb_smith';
  static const machineStartLegPressLb = 'machine_start_lb_leg_press';
  static const machineStartHackSquatLb = 'machine_start_lb_hack_squat';
}

String _machineStartingWeightKey(VariableMachineKind kind) {
  switch (kind) {
    case VariableMachineKind.smith:
      return SettingKeys.machineStartSmithLb;
    case VariableMachineKind.legPress:
      return SettingKeys.machineStartLegPressLb;
    case VariableMachineKind.hackSquat:
      return SettingKeys.machineStartHackSquatLb;
  }
}

/// Reads and writes the journal in SQLite. Callers do not touch Firestore.
class JournalRepository {
  JournalRepository(this.db);

  final AppDatabase db;

  String nowStamp([DateTime? now]) =>
      (now ?? DateTime.now()).toUtc().toIso8601String();

  Future<List<DaySummary>> summariesForMonth(DateTime month) async {
    final start = toDateKey(DateTime(month.year, month.month, 1));
    final end = toDateKey(DateTime(month.year, month.month + 1, 0));
    final rows =
        await (db.select(db.days)
              ..where((day) => day.dateKey.isBetweenValues(start, end))
              ..orderBy([(day) => OrderingTerm.asc(day.dateKey)]))
            .get();
    if (rows.isEmpty) return const [];
    final keys = rows.map((row) => row.dateKey).toList();
    final exercises = await (db.select(
      db.exercises,
    )..where((exercise) => exercise.dateKey.isIn(keys))).get();
    final counts = <String, int>{};
    for (final exercise in exercises) {
      counts[exercise.dateKey] = (counts[exercise.dateKey] ?? 0) + 1;
    }
    return [
      for (final row in rows)
        DaySummary(
          dateKey: row.dateKey,
          isRestDay: row.isRestDay,
          workoutName: row.workoutName,
          exerciseCount: counts[row.dateKey] ?? 0,
        ),
    ];
  }

  Future<JournalDay?> getDay(String dateKey) async {
    final row = await (db.select(
      db.days,
    )..where((day) => day.dateKey.equals(dateKey))).getSingleOrNull();
    if (row == null) return null;
    return _hydrate(row);
  }

  Future<List<JournalDay>> allDays() async {
    final rows = await (db.select(
      db.days,
    )..orderBy([(day) => OrderingTerm.asc(day.dateKey)])).get();
    final days = <JournalDay>[];
    for (final row in rows) {
      days.add(await _hydrate(row));
    }
    return days;
  }

  /// Distinct plan (folder) names stored on logged days.
  Future<List<String>> distinctLoggedPlanNames() async {
    final rows = await db.select(db.days).get();
    final names = <String>{};
    for (final row in rows) {
      final trimmed = row.planName?.trim();
      if (trimmed != null && trimmed.isNotEmpty) names.add(trimmed);
    }
    final list = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Distinct exercise names as stored in the journal (any day, including without libraryId).
  Future<List<String>> distinctLoggedExerciseNames() async {
    final rows = await db.select(db.exercises).get();
    final names = <String>{};
    for (final row in rows) {
      final trimmed = row.name.trim();
      if (trimmed.isNotEmpty) names.add(trimmed);
    }
    final list = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<void> replaceDay(JournalDay day) {
    return db.transaction(() async {
      await _deleteDayRows(day.dateKey);
      await _insertDay(day);
    });
  }

  /// Append one exercise and its sets. Clears a rest-day flag on that date.
  /// A warmup set is inserted only when [prescribeWarmup] is true and the lift
  /// qualifies. Existing days are never rewritten by this path.
  Future<void> addExercise({
    required String dateKey,
    required String name,
    required List<JournalSet> sets,
    String? notes,
    String? libraryId,
    bool isCardio = false,
    bool isCore = false,
    bool isCircuit = false,
    bool prescribeWarmup = false,
  }) async {
    final trimmed = name.trim();
    if (!isValidDateKey(dateKey)) {
      throw ArgumentError('Date must look like YYYY-MM-DD.');
    }
    if (trimmed.isEmpty) {
      throw ArgumentError('Exercise name is required.');
    }
    final stamp = nowStamp();
    await db.transaction(() async {
      final existing = await (db.select(
        db.days,
      )..where((day) => day.dateKey.equals(dateKey))).getSingleOrNull();
      if (existing == null) {
        await db
            .into(db.days)
            .insert(
              DaysCompanion.insert(
                dateKey: dateKey,
                isRestDay: const Value(false),
                updatedAt: stamp,
              ),
            );
      } else {
        await (db.update(
          db.days,
        )..where((day) => day.dateKey.equals(dateKey))).write(
          DaysCompanion(isRestDay: const Value(false), updatedAt: Value(stamp)),
        );
      }
      final current = await (db.select(
        db.exercises,
      )..where((exercise) => exercise.dateKey.equals(dateKey))).get();
      final sortOrder = current.isEmpty
          ? 0
          : current
                    .map((exercise) => exercise.sortOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;
      final exerciseId = newId();
      await db
          .into(db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: exerciseId,
              dateKey: dateKey,
              sortOrder: sortOrder,
              name: trimmed,
              notes: Value(_blankToNull(notes)),
              libraryId: Value(_blankToNull(libraryId)),
              isCardio: Value(isCardio),
              isCore: Value(isCore),
              isCircuit: Value(isCircuit),
            ),
          );
      final usedSetIds = <String>{};
      final logged = await _setsForNewExercise(
        name: trimmed,
        libraryId: libraryId,
        dateKey: dateKey,
        sets: sets,
        isCircuit: isCircuit,
        isCardio: isCardio,
        prescribeWarmup: prescribeWarmup,
      );
      for (var index = 0; index < logged.length; index++) {
        final set = logged[index];
        final setId = await _freshSetId(
          set.id.isEmpty ? newId() : set.id,
          usedSetIds,
        );
        await db
            .into(db.workoutSets)
            .insert(
              WorkoutSetsCompanion.insert(
                id: setId,
                exerciseId: exerciseId,
                sortOrder: index,
                reps: Value(set.reps),
                weight: Value(set.weight),
                durationSeconds: Value(set.durationSeconds),
                checked: Value(set.checked),
                isWarmup: Value(set.isWarmup),
                difficulty: Value(canonicalSetDifficulty(set.difficulty)),
              ),
            );
      }
    });
    await mergeExactLibraryMatchesFromCatalog();
  }

  /// Prepends one warmup set on new barbell compounds. Existing warmups stay put.
  /// [enabled] false returns [exercises] unchanged, so older days are not rewritten.
  Future<List<JournalExercise>> withPrescribedWarmup({
    required String dateKey,
    required List<JournalExercise> exercises,
    required bool enabled,
  }) async {
    if (!enabled) return exercises;
    final next = <JournalExercise>[];
    for (final exercise in exercises) {
      final sets = await _setsForNewExercise(
        name: exercise.name,
        libraryId: exercise.libraryId,
        dateKey: dateKey,
        sets: exercise.sets,
        isCircuit: exercise.isCircuit,
        isCardio: exercise.isCardio,
        prescribeWarmup: true,
      );
      next.add(
        exercise.copyWith(
          sets: [
            for (var index = 0; index < sets.length; index++)
              JournalSet(
                id: sets[index].id,
                sortOrder: index,
                reps: sets[index].reps,
                weight: sets[index].weight,
                durationSeconds: sets[index].durationSeconds,
                checked: sets[index].checked,
                isWarmup: sets[index].isWarmup,
                difficulty: sets[index].difficulty,
              ),
          ],
        ),
      );
    }
    return next;
  }

  /// Links logged exercises to the library when names match exactly after normalization.
  Future<int> mergeExactLibraryMatches(Iterable<LibraryLift> catalogLifts) async {
    final byNormalized = <String, LibraryLift>{};
    for (final lift in catalogLifts) {
      final key = normalizeForExerciseMatch(lift.name);
      if (key.isEmpty) continue;
      byNormalized.putIfAbsent(key, () => lift);
    }
    if (byNormalized.isEmpty) return 0;

    var updated = 0;
    await db.transaction(() async {
      final exercises = await db.select(db.exercises).get();
      for (final row in exercises) {
        final match = byNormalized[normalizeForExerciseMatch(row.name)];
        if (match == null) continue;
        if (row.name == match.name && row.libraryId == match.id) continue;
        await (db.update(db.exercises)..where((e) => e.id.equals(row.id))).write(
          ExercisesCompanion(
            name: Value(match.name),
            libraryId: Value(match.id),
          ),
        );
        updated += 1;
        await _touchDay(row.dateKey);
      }
    });
    return updated;
  }

  Future<void> mergeExactLibraryMatchesFromCatalog() async {
    try {
      final catalog = await LiftBigCatalog.load();
      await mergeExactLibraryMatches(catalog.lifts);
    } catch (_) {
      // Catalog unavailable — skip silent merge.
    }
  }

  /// Append a set. When auto-fill is on, weight and reps come from prior
  /// working sets for that lift. Warmups are not part of that prediction.
  Future<JournalSet> addSet(String exerciseId) async {
    if (exerciseId.isEmpty) {
      throw ArgumentError('Exercise is required.');
    }
    final exercise = await (db.select(
      db.exercises,
    )..where((row) => row.id.equals(exerciseId))).getSingleOrNull();
    if (exercise == null) {
      throw ArgumentError('Exercise not found.');
    }
    final fill = await _fillForNewSet(
      name: exercise.name,
      libraryId: exercise.libraryId,
      targetReps: exercise.targetReps,
      dateKey: exercise.dateKey,
      isCircuit: exercise.isCircuit,
      isCardio: exercise.isCardio,
    );
    return db.transaction(() async {
      final stillThere = await (db.select(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).getSingleOrNull();
      if (stillThere == null) {
        throw ArgumentError('Exercise not found.');
      }
      final existing = await (db.select(
        db.workoutSets,
      )..where((row) => row.exerciseId.equals(exerciseId))).get();
      final sortOrder = existing.isEmpty
          ? 0
          : existing
                    .map((set) => set.sortOrder)
                    .reduce((a, b) => a > b ? a : b) +
                1;
      final id = newId();
      final ordered = [...existing]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final previous = ordered.isEmpty ? null : ordered.last;
      final reps = previous != null ? previous.reps : (fill?.reps ?? '');
      final weight = previous != null ? previous.weight : (fill?.weight ?? '');
      await db.into(db.workoutSets).insert(
        WorkoutSetsCompanion.insert(
          id: id,
          exerciseId: exerciseId,
          sortOrder: sortOrder,
          reps: Value(reps),
          weight: Value(weight),
        ),
      );
      await _touchDay(stillThere.dateKey);
      return JournalSet(id: id, sortOrder: sortOrder, reps: reps, weight: weight);
    });
  }

  /// Writes the prediction onto empty, unchecked working sets for [dateKey].
  /// Returns how many sets changed. Does nothing when auto-fill is off.
  Future<int> prefillEmptySets(String dateKey) async {
    if (!await autoFillSetsEnabled()) return 0;
    final day = await getDay(dateKey);
    if (day == null) return 0;
    final history = historySetsFromDays(await allDays());
    final bodyWeightLbs = await storedBodyWeightLbs();
    final displayUnit = (await storedWeightUnit()) == WeightUnit.kg ? 'kg' : 'lb';
    var wrote = 0;
    for (final exercise in day.exercises) {
      if (exercise.isCircuit || exercise.isCardio) continue;
      final fill = loggedSetFill(
        exerciseName: exercise.name,
        libraryId: exercise.libraryId,
        bodyWeightLbs: bodyWeightLbs,
        history: history,
        currentTargetReps: exercise.targetReps,
        excludeDateKey: dateKey,
        displayUnit: displayUnit,
      );
      if (fill == null) continue;
      for (final set in exercise.sets) {
        if (set.isWarmup || set.checked) continue;
        if (set.reps.trim().isNotEmpty || set.weight.trim().isNotEmpty) {
          continue;
        }
        await updateSet(set.id, reps: fill.reps, weight: fill.weight);
        wrote += 1;
      }
    }
    return wrote;
  }

  Future<void> updateTargetRestSeconds(String exerciseId, int seconds) async {
    if (exerciseId.isEmpty) {
      throw ArgumentError('Exercise is required.');
    }
    final clamped = clampAverageRestSeconds(seconds);
    await db.transaction(() async {
      final exercise = await (db.select(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).getSingleOrNull();
      if (exercise == null) {
        throw ArgumentError('Exercise not found.');
      }
      await (db.update(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).write(
        ExercisesCompanion(targetRestSeconds: Value(clamped)),
      );
      await _touchDay(exercise.dateKey);
    });
  }

  /// Updates only the fields that are passed. Other columns stay as stored.
  /// An empty [durationSeconds] clears the stored time.
  Future<void> updateSet(
    String setId, {
    String? reps,
    String? weight,
    String? durationSeconds,
    bool? checked,
    bool? isWarmup,
    String? difficulty,
    bool setDifficulty = false,
  }) async {
    if (setId.isEmpty) {
      throw ArgumentError('Set is required.');
    }
    await db.transaction(() async {
      final set = await (db.select(
        db.workoutSets,
      )..where((row) => row.id.equals(setId))).getSingleOrNull();
      if (set == null) {
        throw ArgumentError('Set not found.');
      }
      final exercise = await (db.select(
        db.exercises,
      )..where((row) => row.id.equals(set.exerciseId))).getSingleOrNull();
      await (db.update(
        db.workoutSets,
      )..where((row) => row.id.equals(setId))).write(
        WorkoutSetsCompanion(
          reps: reps == null ? const Value.absent() : Value(reps),
          weight: weight == null ? const Value.absent() : Value(weight),
          durationSeconds: durationSeconds == null
              ? const Value.absent()
              : Value(_blankToNull(durationSeconds)),
          checked: checked == null ? const Value.absent() : Value(checked),
          isWarmup: isWarmup == null ? const Value.absent() : Value(isWarmup),
          difficulty: setDifficulty
              ? Value(canonicalSetDifficulty(difficulty))
              : const Value.absent(),
        ),
      );
      if (exercise != null) await _touchDay(exercise.dateKey);
    });
  }

  /// Removes one set. The exercise stays, even if it has no sets left.
  Future<void> deleteSet(String setId) async {
    if (setId.isEmpty) return;
    await db.transaction(() async {
      final set = await (db.select(
        db.workoutSets,
      )..where((row) => row.id.equals(setId))).getSingleOrNull();
      if (set == null) return;
      final exercise = await (db.select(
        db.exercises,
      )..where((row) => row.id.equals(set.exerciseId))).getSingleOrNull();
      await (db.delete(
        db.workoutSets,
      )..where((row) => row.id.equals(setId))).go();
      if (exercise != null) await _touchDay(exercise.dateKey);
    });
  }

  /// Removes an exercise and its sets. The day row stays.
  Future<void> deleteExercise(String exerciseId) async {
    if (exerciseId.isEmpty) return;
    await db.transaction(() async {
      final exercise = await (db.select(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).getSingleOrNull();
      if (exercise == null) return;
      await (db.delete(
        db.workoutSets,
      )..where((row) => row.exerciseId.equals(exerciseId))).go();
      await (db.delete(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).go();
      await _touchDay(exercise.dateKey);
    });
  }

  /// Writes the workout name and the day's own notes. Blank text clears them.
  Future<void> updateDayHeader(
    String dateKey, {
    String? notes,
    String? workoutName,
    String? planName,
    bool setNotes = false,
    bool setWorkoutName = false,
    bool setPlanName = false,
  }) async {
    if (!isValidDateKey(dateKey)) {
      throw ArgumentError('Date must look like YYYY-MM-DD.');
    }
    final stamp = nowStamp();
    await db.transaction(() async {
      final existing = await (db.select(
        db.days,
      )..where((day) => day.dateKey.equals(dateKey))).getSingleOrNull();
      if (existing == null) {
        await db.into(db.days).insert(
          DaysCompanion.insert(
            dateKey: dateKey,
            notes: Value(setNotes ? _blankToNull(notes) : null),
            workoutName: Value(setWorkoutName ? _blankToNull(workoutName) : null),
            planName: Value(setPlanName ? _blankToNull(planName) : null),
            updatedAt: stamp,
          ),
        );
        return;
      }
      await (db.update(db.days)..where((day) => day.dateKey.equals(dateKey)))
          .write(
        DaysCompanion(
          notes: setNotes ? Value(_blankToNull(notes)) : const Value.absent(),
          workoutName: setWorkoutName
              ? Value(_blankToNull(workoutName))
              : const Value.absent(),
          planName: setPlanName
              ? Value(_blankToNull(planName))
              : const Value.absent(),
          updatedAt: Value(stamp),
        ),
      );
    });
  }

  Future<void> updateLoggedCalories(String exerciseId, String calories) async {
    if (exerciseId.isEmpty) return;
    await db.transaction(() async {
      final exercise = await (db.select(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).getSingleOrNull();
      if (exercise == null) return;
      await (db.update(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).write(
        ExercisesCompanion(loggedCalories: Value(_blankToNull(calories))),
      );
      await _touchDay(exercise.dateKey);
    });
  }

  Future<void> reorderExercises(String dateKey, List<String> idsInOrder) async {
    if (!isValidDateKey(dateKey) || idsInOrder.isEmpty) return;
    await db.transaction(() async {
      for (var index = 0; index < idsInOrder.length; index++) {
        await (db.update(db.exercises)..where(
              (exercise) =>
                  exercise.id.equals(idsInOrder[index]) &
                  exercise.dateKey.equals(dateKey),
            ))
            .write(ExercisesCompanion(sortOrder: Value(index)));
      }
      await _touchDay(dateKey);
    });
  }

  Future<void> reorderSets(String exerciseId, List<String> idsInOrder) async {
    if (exerciseId.isEmpty || idsInOrder.isEmpty) return;
    await db.transaction(() async {
      final exercise = await (db.select(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).getSingleOrNull();
      if (exercise == null) return;
      for (var index = 0; index < idsInOrder.length; index++) {
        await (db.update(db.workoutSets)..where(
              (set) =>
                  set.id.equals(idsInOrder[index]) &
                  set.exerciseId.equals(exerciseId),
            ))
            .write(WorkoutSetsCompanion(sortOrder: Value(index)));
      }
      await _touchDay(exercise.dateKey);
    });
  }

  /// Appends a structural copy onto [toKey]. The source day stays as it is.
  /// Returns false when there is nothing to copy.
  Future<bool> copyDay(String fromKey, String toKey) async {
    if (!isValidDateKey(fromKey) ||
        !isValidDateKey(toKey) ||
        fromKey == toKey) {
      return false;
    }
    final source = await getDay(fromKey);
    if (source == null || source.exercises.isEmpty) return false;
    final target = await getDay(toKey);
    final existing = target?.exercises ?? const <JournalExercise>[];
    final cloned = cloneExercisesForCopy(source.exercises);
    var order = 0;
    final merged = <JournalExercise>[
      for (final exercise in existing)
        exercise.copyWith(sortOrder: order++),
      for (final exercise in cloned) exercise.copyWith(sortOrder: order++),
    ];
    await replaceDay(
      JournalDay(
        dateKey: toKey,
        updatedAt: nowStamp(),
        notes: target?.notes,
        workoutName: target?.workoutName,
        planName: target?.planName,
        workoutNotes: target?.workoutNotes,
        exercises: merged,
      ),
    );
    return true;
  }

  /// Moves [fromKey] onto [toKey]. Swaps the two days when the target already
  /// has exercises. Returns `moved`, `swapped`, or null when there is nothing
  /// to move.
  Future<String?> moveDay(String fromKey, String toKey) async {
    if (!isValidDateKey(fromKey) ||
        !isValidDateKey(toKey) ||
        fromKey == toKey) {
      return null;
    }
    return db.transaction(() async {
      final source = await getDay(fromKey);
      if (source == null || source.exercises.isEmpty) return null;
      final target = await getDay(toKey);
      final swap = target != null && target.exercises.isNotEmpty;
      await _deleteDayRows(fromKey);
      await _deleteDayRows(toKey);
      final stamp = nowStamp();
      await _insertDay(
        JournalDay(
          dateKey: toKey,
          updatedAt: stamp,
          notes: source.notes,
          workoutName: source.workoutName,
          planName: source.planName,
          workoutNotes: source.workoutNotes,
          exercises: source.exercises,
        ),
      );
      if (!swap) return 'moved';
      await _insertDay(
        JournalDay(
          dateKey: fromKey,
          updatedAt: stamp,
          notes: target.notes,
          workoutName: target.workoutName,
          planName: target.planName,
          workoutNotes: target.workoutNotes,
          exercises: target.exercises,
        ),
      );
      return 'swapped';
    });
  }

  Future<void> _deleteDayRows(String dateKey) async {
    final existingExercises = await (db.select(
      db.exercises,
    )..where((exercise) => exercise.dateKey.equals(dateKey))).get();
    for (final exercise in existingExercises) {
      await (db.delete(
        db.workoutSets,
      )..where((set) => set.exerciseId.equals(exercise.id))).go();
    }
    await (db.delete(
      db.exercises,
    )..where((exercise) => exercise.dateKey.equals(dateKey))).go();
    await (db.delete(
      db.days,
    )..where((row) => row.dateKey.equals(dateKey))).go();
  }

  Future<void> _insertDay(JournalDay day) async {
    await db.into(db.days).insert(
      DaysCompanion.insert(
        dateKey: day.dateKey,
        notes: Value(day.notes),
        isRestDay: Value(day.isRestDay),
        workoutName: Value(day.workoutName),
        planName: Value(day.planName),
        workoutNotes: Value(day.workoutNotes),
        chosenRestSeconds: Value(day.chosenRestSeconds),
        healthEnergyKcal: Value(day.healthEnergyKcal),
        updatedAt: day.updatedAt,
      ),
    );
    final usedExerciseIds = <String>{};
    for (final exercise in day.exercises) {
      final exerciseId = await _freshExerciseId(exercise.id, usedExerciseIds);
      await db.into(db.exercises).insert(
        ExercisesCompanion.insert(
          id: exerciseId,
          dateKey: day.dateKey,
          sortOrder: exercise.sortOrder,
          name: exercise.name,
          libraryId: Value(exercise.libraryId),
          notes: Value(exercise.notes),
          isCircuit: Value(exercise.isCircuit),
          isCardio: Value(exercise.isCardio),
          isCore: Value(exercise.isCore),
          targetDuration: Value(exercise.targetDuration),
          targetTimeSeconds: Value(exercise.targetTimeSeconds),
          targetDistance: Value(exercise.targetDistance),
          loggedCalories: Value(exercise.loggedCalories),
          targetReps: Value(exercise.targetReps),
          targetWeight: Value(exercise.targetWeight),
          supersetGroupId: Value(exercise.supersetGroupId),
          supersetLabel: Value(exercise.supersetLabel),
          supersetOrder: Value(exercise.supersetOrder),
          preferredSwapLibraryIds: Value(
            encodeStringList(exercise.preferredSwapLibraryIds),
          ),
          targetRestSeconds: Value(exercise.targetRestSeconds),
          prescribedReps: Value(exercise.prescribedReps),
          prescribedWeight: Value(exercise.prescribedWeight),
          prescribedSetCount: Value(exercise.prescribedSetCount),
        ),
      );
      final usedSetIds = <String>{};
      for (final set in exercise.sets) {
        final setId = await _freshSetId(set.id, usedSetIds);
        await db.into(db.workoutSets).insert(
          WorkoutSetsCompanion.insert(
            id: setId,
            exerciseId: exerciseId,
            sortOrder: set.sortOrder,
            reps: Value(set.reps),
            weight: Value(set.weight),
            durationSeconds: Value(set.durationSeconds),
            checked: Value(set.checked),
            isWarmup: Value(set.isWarmup),
            difficulty: Value(canonicalSetDifficulty(set.difficulty)),
          ),
        );
      }
    }
  }

  Future<void> _touchDay(String dateKey) {
    return (db.update(db.days)..where((day) => day.dateKey.equals(dateKey)))
        .write(DaysCompanion(updatedAt: Value(nowStamp())));
  }

  /// Returns false when the day already has exercises, so they are not wiped.
  Future<bool> setRestDay(String dateKey, {required bool rest}) async {
    if (!isValidDateKey(dateKey)) return false;
    final existingExercises = await (db.select(
      db.exercises,
    )..where((exercise) => exercise.dateKey.equals(dateKey))).get();
    if (rest && existingExercises.isNotEmpty) return false;
    final stamp = nowStamp();
    final existing = await (db.select(
      db.days,
    )..where((day) => day.dateKey.equals(dateKey))).getSingleOrNull();
    if (existing == null) {
      if (!rest) return true;
      await db
          .into(db.days)
          .insert(
            DaysCompanion.insert(
              dateKey: dateKey,
              isRestDay: const Value(true),
              updatedAt: stamp,
            ),
          );
      return true;
    }
    await (db.update(db.days)..where((day) => day.dateKey.equals(dateKey)))
        .write(DaysCompanion(isRestDay: Value(rest), updatedAt: Value(stamp)));
    return true;
  }

  /// Replaces each date present in the backup. Other local days stay put.
  ///
  /// One transaction so a multi-year journal commits together instead of
  /// once per day.
  Future<int> importBackup(ParsedBackup backup) {
    return db.transaction(() async {
      for (final day in backup.days) {
        await replaceDay(day);
      }
      if (backup.templatesJson != null) {
        await _put(SettingKeys.templatesJson, backup.templatesJson!);
      }
      if (backup.settingsJson != null) {
        await _put(SettingKeys.settingsJson, backup.settingsJson!);
      }
      if (backup.weightUnit != null) {
        await _put(SettingKeys.weightUnit, backup.weightUnit!);
      }
      if (backup.bodyWeightLbs != null) {
        await _put(SettingKeys.bodyWeightLbs, backup.bodyWeightLbs.toString());
      }
      if (backup.settingsUpdatedAt != null) {
        await _put(SettingKeys.settingsUpdatedAt, backup.settingsUpdatedAt!);
      }
      return backup.days.length;
    });
  }

  Future<bool> isSyncEnabled() async {
    return (await _get(SettingKeys.syncEnabled)) == 'true';
  }

  Future<void> setSyncEnabled(bool enabled) {
    return _put(SettingKeys.syncEnabled, enabled ? 'true' : 'false');
  }

  /// On unless the stored value is the word `false`.
  Future<bool> autoFillSetsEnabled() async {
    return autoFillSetsFromStored(await _get(SettingKeys.autoFillSets));
  }

  Future<void> setAutoFillSetsEnabled(bool enabled) {
    return _put(SettingKeys.autoFillSets, enabled ? 'true' : 'false');
  }

  /// Off unless the stored value is the word `true`.
  Future<bool> startTimerOnDone() async {
    return startTimerOnDoneFromStored(await _get(SettingKeys.startTimerOnDone));
  }

  Future<void> setStartTimerOnDone(bool enabled) {
    return _put(SettingKeys.startTimerOnDone, enabled ? 'true' : 'false');
  }

  /// Off until the lifter turns on per-set difficulty in Settings.
  Future<bool> logSetDifficultyEnabled() async {
    return logSetDifficultyFromStored(await _get(SettingKeys.logSetDifficulty));
  }

  Future<void> setLogSetDifficultyEnabled(bool enabled) {
    return _put(SettingKeys.logSetDifficulty, enabled ? 'true' : 'false');
  }

  /// Off until the lifter turns on warmup sets for new barbell compounds.
  Future<bool> prescribeWarmupEnabled() async {
    return prescribeWarmupFromStored(await _get(SettingKeys.prescribeWarmup));
  }

  Future<void> setPrescribeWarmupEnabled(bool enabled) {
    return _put(SettingKeys.prescribeWarmup, enabled ? 'true' : 'false');
  }

  /// Temporary tester unlock. Only the exact stored word `true` counts.
  Future<bool> proTesterUnlockEnabled() async {
    return (await _get(SettingKeys.proTesterUnlock)) == 'true';
  }

  Future<void> setProTesterUnlock() {
    return _put(SettingKeys.proTesterUnlock, 'true');
  }

  Future<double?> storedHeightInches() async {
    final raw = await _get(SettingKeys.heightInches);
    return sanitizeHeightInches(double.tryParse(raw?.trim() ?? ''));
  }

  Future<void> setHeightInches(double inches) {
    final sanitized = sanitizeHeightInches(inches);
    if (sanitized == null) return clearHeightInches();
    return _put(SettingKeys.heightInches, sanitized.toString());
  }

  Future<void> clearHeightInches() {
    return _put(SettingKeys.heightInches, '');
  }

  Future<void> setChosenRestSeconds(String dateKey, int seconds) async {
    if (!isValidDateKey(dateKey)) {
      throw ArgumentError('Date must look like YYYY-MM-DD.');
    }
    final clamped = seconds.clamp(30, 600);
    final stamp = nowStamp();
    await db.transaction(() async {
      final existing = await (db.select(
        db.days,
      )..where((day) => day.dateKey.equals(dateKey))).getSingleOrNull();
      if (existing == null) {
        await db.into(db.days).insert(
          DaysCompanion.insert(
            dateKey: dateKey,
            chosenRestSeconds: Value(clamped),
            updatedAt: stamp,
          ),
        );
        return;
      }
      await (db.update(db.days)..where((day) => day.dateKey.equals(dateKey)))
          .write(
        DaysCompanion(
          chosenRestSeconds: Value(clamped),
          updatedAt: Value(stamp),
        ),
      );
    });
  }

  Future<void> setHealthEnergyKcal(String dateKey, double? kcal) async {
    if (!isValidDateKey(dateKey)) return;
    final existing = await (db.select(
      db.days,
    )..where((day) => day.dateKey.equals(dateKey))).getSingleOrNull();
    if (existing == null) return;
    await (db.update(db.days)..where((day) => day.dateKey.equals(dateKey)))
        .write(DaysCompanion(healthEnergyKcal: Value(kcal)));
  }

  /// Renames every logged spelling in [key] to [canonicalName].
  Future<int> mergeExerciseNameVariants({
    required String key,
    required String canonicalName,
    String? libraryId,
  }) async {
    final target = canonicalName.trim();
    if (target.isEmpty || key.isEmpty) return 0;
    var updated = 0;
    await db.transaction(() async {
      final rows = await db.select(db.exercises).get();
      for (final row in rows) {
        if (duplicateExerciseKey(row.name) != key) continue;
        final sameName = row.name == target;
        final sameLibrary = libraryId == null || row.libraryId == libraryId;
        if (sameName && sameLibrary) continue;
        await (db.update(db.exercises)..where((e) => e.id.equals(row.id))).write(
          ExercisesCompanion(
            name: Value(target),
            libraryId: libraryId == null
                ? const Value.absent()
                : Value(libraryId),
          ),
        );
        updated += 1;
        await _touchDay(row.dateKey);
      }
    });
    return updated;
  }

  /// Edits this day's set count, reps, and weight. The first edit stores the
  /// plan snapshot used by [revertExerciseGoal].
  Future<void> updateExerciseGoal({
    required String exerciseId,
    required String? targetReps,
    required String? targetWeight,
    required int setCount,
  }) async {
    if (exerciseId.isEmpty) throw ArgumentError('Exercise is required.');
    final count = setCount.clamp(0, 30);
    await db.transaction(() async {
      final exercise = await (db.select(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).getSingleOrNull();
      if (exercise == null) throw ArgumentError('Exercise not found.');
      final sets = await (db.select(
        db.workoutSets,
      )..where((row) => row.exerciseId.equals(exerciseId))).get();
      final snapshotMissing =
          exercise.prescribedReps == null &&
          exercise.prescribedWeight == null &&
          exercise.prescribedSetCount == null;
      await (db.update(db.exercises)..where((row) => row.id.equals(exerciseId)))
          .write(
        ExercisesCompanion(
          targetReps: Value(_blankToNull(targetReps)),
          targetWeight: Value(_blankToNull(targetWeight)),
          prescribedReps: snapshotMissing
              ? Value(exercise.targetReps)
              : const Value.absent(),
          prescribedWeight: snapshotMissing
              ? Value(exercise.targetWeight)
              : const Value.absent(),
          prescribedSetCount: snapshotMissing
              ? Value(sets.length)
              : const Value.absent(),
        ),
      );
      await _matchSetCount(
        exerciseId: exerciseId,
        sets: sets,
        count: count,
        repsForNew: targetReps ?? '',
        weightForNew: targetWeight ?? '',
      );
      await _touchDay(exercise.dateKey);
    });
  }

  /// Restores the snapshot from the first goal edit. Logged sets stay.
  Future<void> revertExerciseGoal(String exerciseId) async {
    if (exerciseId.isEmpty) return;
    await db.transaction(() async {
      final exercise = await (db.select(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).getSingleOrNull();
      if (exercise == null || exercise.prescribedSetCount == null) return;
      final sets = await (db.select(
        db.workoutSets,
      )..where((row) => row.exerciseId.equals(exerciseId))).get();
      await (db.update(db.exercises)..where((row) => row.id.equals(exerciseId)))
          .write(
        ExercisesCompanion(
          targetReps: Value(exercise.prescribedReps),
          targetWeight: Value(exercise.prescribedWeight),
        ),
      );
      await _matchSetCount(
        exerciseId: exerciseId,
        sets: sets,
        count: exercise.prescribedSetCount!,
        repsForNew: exercise.prescribedReps ?? '',
        weightForNew: exercise.prescribedWeight ?? '',
      );
      await _touchDay(exercise.dateKey);
    });
  }

  /// Writes a watch message onto the stored day. True when a set was completed.
  Future<bool> persistCompanionMessage(CompanionMessage message) async {
    final day = await getDay(message.dateKey);
    if (day == null) return false;
    final next = applyCompanionMessage(day, message);
    if (identical(next, day)) return false;
    final exercise = next.exercises
        .where((item) => item.id == message.exerciseId)
        .firstOrNull;
    if (exercise == null) return false;
    await db.transaction(() async {
      final existing = await (db.select(
        db.workoutSets,
      )..where((row) => row.exerciseId.equals(exercise.id))).get();
      final existingIds = existing.map((set) => set.id).toSet();
      for (final set in exercise.sets) {
        if (existingIds.contains(set.id)) {
          await (db.update(db.workoutSets)..where((row) => row.id.equals(set.id)))
              .write(
            WorkoutSetsCompanion(
              reps: Value(set.reps),
              weight: Value(set.weight),
              checked: Value(set.checked),
            ),
          );
        } else {
          await db.into(db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: set.id,
              exerciseId: exercise.id,
              sortOrder: set.sortOrder,
              reps: Value(set.reps),
              weight: Value(set.weight),
              checked: Value(set.checked),
              isWarmup: Value(set.isWarmup),
            ),
          );
        }
      }
      await _touchDay(day.dateKey);
    });
    return message.isCompleteSet;
  }

  Future<RestTimerSnapshot?> loadRestTimerState() async {
    return RestTimerSnapshot.fromJsonString(
      await _get(SettingKeys.restTimerState),
    );
  }

  Future<void> saveRestTimerState(RestTimerSnapshot snapshot) {
    return _put(SettingKeys.restTimerState, snapshot.encode());
  }

  Future<void> clearRestTimerState() {
    return _put(SettingKeys.restTimerState, '');
  }

  Future<WeightUnit> storedWeightUnit() async {
    return weightUnitFromStored(await _get(SettingKeys.weightUnit));
  }

  Future<void> setWeightUnit(WeightUnit unit) {
    return _put(SettingKeys.weightUnit, unit == WeightUnit.kg ? 'kg' : 'lb');
  }

  Future<DistanceUnit> storedDistanceUnit() async {
    return distanceUnitFromStored(await _get(SettingKeys.distanceUnit));
  }

  Future<void> setDistanceUnit(DistanceUnit unit) {
    return _put(SettingKeys.distanceUnit, unit == DistanceUnit.km ? 'km' : 'mi');
  }

  Future<int> storedAverageRestSeconds() async {
    final settings = await localCloudSettings();
    return resolveAverageRestSeconds(
      storedKeyValue: await _get(SettingKeys.averageRestSeconds),
      settingsJson: settings?.settingsJson,
    );
  }

  Future<void> setAverageRestSeconds(int seconds) {
    return _put(
      SettingKeys.averageRestSeconds,
      '${clampAverageRestSeconds(seconds)}',
    );
  }

  Future<int> storedAverageLiftSeconds() async {
    final settings = await localCloudSettings();
    return resolveAverageLiftSeconds(
      storedKeyValue: await _get(SettingKeys.averageLiftSeconds),
      settingsJson: settings?.settingsJson,
    );
  }

  Future<void> setAverageLiftSeconds(int seconds) {
    return _put(
      SettingKeys.averageLiftSeconds,
      '${clampAverageRestSeconds(seconds)}',
    );
  }

  Future<RestTimerAlertSettings> loadRestTimerAlertSettings() async {
    final sound = await _get(SettingKeys.restTimerSound);
    final vibration = await _get(SettingKeys.restTimerVibration);
    final notification = await _get(SettingKeys.restTimerNotification);
    return RestTimerAlertSettings(
      soundEnabled: boolSettingFromStored(sound, defaultValue: true),
      vibrationEnabled: boolSettingFromStored(vibration, defaultValue: true),
      notificationEnabled: boolSettingFromStored(notification, defaultValue: true),
    );
  }

  Future<void> saveRestTimerAlertSettings(RestTimerAlertSettings settings) async {
    await _put(
      SettingKeys.restTimerSound,
      settings.soundEnabled ? 'true' : 'false',
    );
    await _put(
      SettingKeys.restTimerVibration,
      settings.vibrationEnabled ? 'true' : 'false',
    );
    await _put(
      SettingKeys.restTimerNotification,
      settings.notificationEnabled ? 'true' : 'false',
    );
  }

  Future<bool> appleHealthSyncEnabled() async {
    return (await _get(SettingKeys.appleHealthEnabled)) == 'true';
  }

  Future<void> setAppleHealthSyncEnabled(bool enabled) {
    return _put(SettingKeys.appleHealthEnabled, enabled ? 'true' : 'false');
  }

  Future<void> setBodyWeightLbs(double lbs) {
    final sanitized = sanitizeBodyWeightLbs(lbs);
    if (sanitized == null) return clearBodyWeightLbs();
    return _put(SettingKeys.bodyWeightLbs, sanitized.toString());
  }

  Future<void> clearBodyWeightLbs() {
    return _put(SettingKeys.bodyWeightLbs, '');
  }

  Future<double?> storedMachineStartingWeightLbs(VariableMachineKind kind) async {
    final raw = await _get(_machineStartingWeightKey(kind));
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = double.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  Future<void> setMachineStartingWeightLbs(
    VariableMachineKind kind,
    double lbs,
  ) {
    return _put(_machineStartingWeightKey(kind), lbs.toString());
  }

  Future<void> clearMachineStartingWeightLbs(VariableMachineKind kind) {
    return _put(_machineStartingWeightKey(kind), '');
  }

  Future<DailyLiftReminderSettings> loadDailyLiftReminderSettings() async {
    final enabled =
        (await _get(SettingKeys.dailyLiftReminderEnabled)) == 'true';
    final storedTime = await _get(SettingKeys.dailyLiftReminderTime);
    final time = sanitizeReminderTimeHHmm(
      storedTime ?? dailyLiftReminderDefaultTime,
    );
    final days = decodeReminderWeekdays(
      await _get(SettingKeys.dailyLiftReminderDays),
    );
    final message = await _get(SettingKeys.dailyLiftReminderMessage);
    return DailyLiftReminderSettings(
      enabled: enabled,
      timeHHmm: time,
      weekdays: days,
      customMessage: message,
    );
  }

  Future<void> saveDailyLiftReminderSettings(
    DailyLiftReminderSettings settings,
  ) async {
    await _put(
      SettingKeys.dailyLiftReminderEnabled,
      settings.enabled ? 'true' : 'false',
    );
    await _put(
      SettingKeys.dailyLiftReminderTime,
      sanitizeReminderTimeHHmm(settings.timeHHmm),
    );
    await _put(
      SettingKeys.dailyLiftReminderDays,
      encodeReminderWeekdays(settings.weekdays),
    );
    await _put(
      SettingKeys.dailyLiftReminderMessage,
      settings.customMessage?.trim() ?? '',
    );
  }

  Future<LoggedSetFill?> _fillForNewSet({
    required String name,
    String? libraryId,
    required String? targetReps,
    required String dateKey,
    required bool isCircuit,
    required bool isCardio,
  }) async {
    if (isCircuit || isCardio) return null;
    if (!await autoFillSetsEnabled()) return null;
    return loggedSetFill(
      exerciseName: name,
      libraryId: libraryId,
      bodyWeightLbs: await storedBodyWeightLbs(),
      history: historySetsFromDays(await allDays()),
      currentTargetReps: targetReps,
      excludeDateKey: dateKey,
      displayUnit: (await storedWeightUnit()) == WeightUnit.kg ? 'kg' : 'lb',
    );
  }

  /// Body weight from Settings. Null when unset.
  Future<double?> storedBodyWeightLbs() async {
    final body = await _get(SettingKeys.bodyWeightLbs);
    if (body == null || body.trim().isEmpty) return null;
    final parsed = double.tryParse(body);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  /// Notes for lifts on [day], keyed by exercise id on that day.
  Future<Map<String, List<PriorExerciseNote>>> priorNotesForDay(
    String excludeDateKey,
    List<JournalExercise> onDay,
  ) async {
    final byLibraryId = <String, List<PriorExerciseNote>>{};
    final byName = <String, List<PriorExerciseNote>>{};
    for (final day in await allDays()) {
      if (day.dateKey == excludeDateKey) continue;
      for (final exercise in day.exercises) {
        final note = exercise.notes?.trim();
        if (note == null || note.isEmpty) continue;
        final entry = PriorExerciseNote(dateKey: day.dateKey, text: note);
        final libraryId = exercise.libraryId?.trim();
        if (libraryId != null && libraryId.isNotEmpty) {
          byLibraryId.putIfAbsent(libraryId, () => []).add(entry);
        } else {
          byName
              .putIfAbsent(exercise.name.trim().toLowerCase(), () => [])
              .add(entry);
        }
      }
    }
    for (final list in [...byLibraryId.values, ...byName.values]) {
      list.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    }
    final out = <String, List<PriorExerciseNote>>{};
    for (final exercise in onDay) {
      final libraryId = exercise.libraryId?.trim();
      final notes = libraryId != null && libraryId.isNotEmpty
          ? byLibraryId[libraryId]
          : byName[exercise.name.trim().toLowerCase()];
      if (notes != null && notes.isNotEmpty) {
        out[exercise.id] = notes;
      }
    }
    return out;
  }

  Future<void> updateExerciseNotes(String exerciseId, String notes) async {
    if (exerciseId.isEmpty) return;
    await db.transaction(() async {
      final exercise = await (db.select(
        db.exercises,
      )..where((row) => row.id.equals(exerciseId))).getSingleOrNull();
      if (exercise == null) return;
      await (db.update(db.exercises)..where((row) => row.id.equals(exerciseId)))
          .write(
        ExercisesCompanion(
          notes: Value(_blankToNull(notes)),
        ),
      );
      await _touchDay(exercise.dateKey);
    });
  }

  Future<CloudSettings?> localCloudSettings() async {
    final updatedAt = await _get(SettingKeys.settingsUpdatedAt);
    if (updatedAt == null || updatedAt.isEmpty) return null;
    final body = await _get(SettingKeys.bodyWeightLbs);
    return CloudSettings(
      updatedAt: updatedAt,
      weightUnit: await _get(SettingKeys.weightUnit),
      bodyWeightLbs: body == null ? null : double.tryParse(body),
      templatesJson: await _get(SettingKeys.templatesJson),
      settingsJson: await _get(SettingKeys.settingsJson),
    );
  }

  Future<void> applyCloudSettings(CloudSettings settings) async {
    await _put(SettingKeys.settingsUpdatedAt, settings.updatedAt);
    if (settings.weightUnit != null) {
      await _put(SettingKeys.weightUnit, settings.weightUnit!);
    }
    if (settings.bodyWeightLbs != null) {
      await _put(SettingKeys.bodyWeightLbs, settings.bodyWeightLbs.toString());
    }
    if (settings.templatesJson != null) {
      await _put(SettingKeys.templatesJson, settings.templatesJson!);
    }
    if (settings.settingsJson != null) {
      await _put(SettingKeys.settingsJson, settings.settingsJson!);
    }
  }

  Future<JournalDay> _hydrate(Day row) async {
    final exercises =
        await (db.select(db.exercises)
              ..where((exercise) => exercise.dateKey.equals(row.dateKey))
              ..orderBy([(exercise) => OrderingTerm.asc(exercise.sortOrder)]))
            .get();
    final ids = exercises.map((exercise) => exercise.id).toList();
    final sets = ids.isEmpty
        ? <WorkoutSet>[]
        : await (db.select(db.workoutSets)
                ..where((set) => set.exerciseId.isIn(ids))
                ..orderBy([(set) => OrderingTerm.asc(set.sortOrder)]))
              .get();
    final setsByExercise = <String, List<WorkoutSet>>{};
    for (final set in sets) {
      setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
    }
    return JournalDay(
      dateKey: row.dateKey,
      notes: row.notes,
      isRestDay: row.isRestDay,
      workoutName: row.workoutName,
      planName: row.planName,
      workoutNotes: row.workoutNotes,
      chosenRestSeconds: row.chosenRestSeconds,
      healthEnergyKcal: row.healthEnergyKcal,
      updatedAt: row.updatedAt,
      exercises: [
        for (final exercise in exercises)
          JournalExercise(
            id: exercise.id,
            sortOrder: exercise.sortOrder,
            name: exercise.name,
            libraryId: exercise.libraryId,
            notes: exercise.notes,
            isCircuit: exercise.isCircuit,
            isCardio: exercise.isCardio,
            isCore: exercise.isCore,
            targetDuration: exercise.targetDuration,
            targetTimeSeconds: exercise.targetTimeSeconds,
            targetDistance: exercise.targetDistance,
            loggedCalories: exercise.loggedCalories,
            targetReps: exercise.targetReps,
            targetWeight: exercise.targetWeight,
            supersetGroupId: exercise.supersetGroupId,
            supersetLabel: exercise.supersetLabel,
            supersetOrder: exercise.supersetOrder,
            preferredSwapLibraryIds: decodeStringList(
              exercise.preferredSwapLibraryIds,
            ),
            targetRestSeconds: exercise.targetRestSeconds,
            prescribedReps: exercise.prescribedReps,
            prescribedWeight: exercise.prescribedWeight,
            prescribedSetCount: exercise.prescribedSetCount,
            sets: [
              for (final set in setsByExercise[exercise.id] ?? const [])
                JournalSet(
                  id: set.id,
                  sortOrder: set.sortOrder,
                  reps: set.reps,
                  weight: set.weight,
                  durationSeconds: set.durationSeconds,
                  checked: set.checked,
                  isWarmup: set.isWarmup,
                  difficulty: canonicalSetDifficulty(set.difficulty),
                ),
            ],
          ),
      ],
    );
  }

  Future<String> _freshExerciseId(String preferred, Set<String> used) async {
    var id = preferred.isEmpty ? newId() : preferred;
    while (used.contains(id) || await _exerciseExists(id)) {
      id = newId();
    }
    used.add(id);
    return id;
  }

  Future<String> _freshSetId(String preferred, Set<String> used) async {
    var id = preferred.isEmpty ? newId() : preferred;
    while (used.contains(id) || await _setExists(id)) {
      id = newId();
    }
    used.add(id);
    return id;
  }

  Future<bool> _exerciseExists(String id) async {
    final row = await (db.select(
      db.exercises,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    return row != null;
  }

  Future<bool> _setExists(String id) async {
    final row = await (db.select(
      db.workoutSets,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    return row != null;
  }

  Future<String?> _get(String key) async {
    final row = await (db.select(
      db.localSettings,
    )..where((setting) => setting.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _put(String key, String value) {
    return db
        .into(db.localSettings)
        .insertOnConflictUpdate(
          LocalSettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<List<JournalSet>> _setsForNewExercise({
  required String name,
  required String? libraryId,
  required String dateKey,
  required List<JournalSet> sets,
  required bool isCircuit,
  required bool isCardio,
  required bool prescribeWarmup,
}) async {
  final logged = sets.isEmpty
      ? [const JournalSet(id: '', sortOrder: 0, reps: '', weight: '')]
      : [...sets];
  if (!prescribeWarmup || isCardio || isCircuit) return logged;
  if (!qualifiesForWarmupPrescription(name, libraryId: libraryId)) return logged;
  if (logged.any((set) => set.isWarmup)) return logged;
  var working = '';
  for (final set in logged) {
    if (set.weight.trim().isNotEmpty) {
      working = set.weight;
      break;
    }
  }
  if (working.isEmpty) {
    final fill = await _fillForNewSet(
      name: name,
      libraryId: libraryId,
      targetReps: null,
      dateKey: dateKey,
      isCircuit: isCircuit,
      isCardio: isCardio,
    );
    working = fill?.weight ?? '';
  }
  return [
    JournalSet(
      id: '',
      sortOrder: 0,
      reps: '5',
      weight: warmupWeightLbsFromWorking(working) ?? '',
      isWarmup: true,
    ),
    ...logged,
  ];
}

Future<void> _matchSetCount({
  required String exerciseId,
  required List<WorkoutSet> sets,
  required int count,
  required String repsForNew,
  required String weightForNew,
}) async {
  final ordered = [...sets]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final drop = <String>{};
  if (ordered.length > count) {
    var extra = ordered.length - count;
    for (final set in ordered.reversed) {
      if (extra <= 0) break;
      final logged = set.reps.trim().isNotEmpty || set.weight.trim().isNotEmpty;
      if (logged) continue;
      drop.add(set.id);
      extra -= 1;
    }
  }
  final kept = <WorkoutSet>[];
  for (final set in ordered) {
    if (!drop.contains(set.id)) {
      kept.add(set);
      continue;
    }
    await (db.delete(db.workoutSets)..where((row) => row.id.equals(set.id))).go();
  }
  if (kept.length >= count) return;
  final sort = kept.isEmpty
      ? 0
      : kept.map((set) => set.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  for (var index = 0; index < count - kept.length; index++) {
    await db.into(db.workoutSets).insert(
      WorkoutSetsCompanion.insert(
        id: newId(),
        exerciseId: exerciseId,
        sortOrder: sort + index,
        reps: Value(repsForNew),
        weight: Value(weightForNew),
      ),
    );
  }
  }
}

String? _blankToNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
