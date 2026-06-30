import { a as getExerciseRepsOrDuration, b as isWorkingSet, f as getExercisesFromDay } from "./workout-Dl4ULJf6.js";
import { s as parseWeightLbs } from "./units-D1Q8qPMV.js";

function parsePositiveInt(value) {
  const trimmed = value.trim();
  if (!trimmed) return null;
  const n = parseInt(trimmed, 10);
  return !Number.isNaN(n) && n > 0 ? n : null;
}

function isCompletedSet(set) {
  const reps = set.reps.trim();
  if (reps === "") return false;
  const n = parseInt(reps, 10);
  return (!Number.isNaN(n) && n >= 1) || reps.toLowerCase().includes("amrap");
}

function normalizeName(name) {
  return name.trim().toLowerCase();
}

function matchesExercise(logged, library) {
  if (logged.libraryId === library.id) return true;
  return normalizeName(logged.name) === normalizeName(library.name);
}

function estimate1RM(weightLbs, reps) {
  if (weightLbs <= 0 || reps <= 0) return 0;
  if (reps === 1) return weightLbs;
  return weightLbs * (1 + reps / 30);
}

function hasLoggedExercise(workouts, exercise) {
  for (const day of Object.values(workouts)) {
    const exercises = getExercisesFromDay(day);
    for (const ex of exercises) {
      if (matchesExercise(ex, exercise)) return true;
    }
  }
  return false;
}

function getExerciseLogStats(workouts, exercise) {
  let maxWeightLbs = null;
  let maxDurationMinutes = null;
  const completedSets = [];
  const isCardio = exercise.isCardio === true;

  for (const day of Object.values(workouts)) {
    const exercises = getExercisesFromDay(day);
    for (const ex of exercises) {
      if (!matchesExercise(ex, exercise)) continue;

      if (isCardio || ex.isCardio) {
        const duration = parsePositiveInt(getExerciseRepsOrDuration(ex));
        if (duration != null) {
          maxDurationMinutes =
            maxDurationMinutes === null ? duration : Math.max(maxDurationMinutes, duration);
        }
        continue;
      }

      for (const set of ex.sets) {
        if (!isWorkingSet(set) || !isCompletedSet(set)) continue;
        const weightLbs = parseWeightLbs(set.weight);
        const repsRaw = set.reps.trim();
        const reps = parseInt(repsRaw, 10);
        if (Number.isNaN(weightLbs) || weightLbs <= 0 || Number.isNaN(reps) || reps <= 0) continue;
        completedSets.push({ weightLbs, reps });
        maxWeightLbs = maxWeightLbs === null ? weightLbs : Math.max(maxWeightLbs, weightLbs);
      }
    }
  }

  let maxSet = null;
  if (completedSets.length > 0) {
    let bestE1rm = 0;
    for (const set of completedSets) {
      const e1rm = estimate1RM(set.weightLbs, set.reps);
      if (e1rm > bestE1rm) {
        bestE1rm = e1rm;
        maxSet = set;
      }
    }
  }

  let avgSet = null;
  if (completedSets.length > 0) {
    const totalWeight = completedSets.reduce((sum, s) => sum + s.weightLbs, 0);
    const totalReps = completedSets.reduce((sum, s) => sum + s.reps, 0);
    avgSet = {
      weightLbs: Math.round((totalWeight / completedSets.length) * 10) / 10,
      reps: Math.round(totalReps / completedSets.length),
    };
  }

  const dateKeys = Object.keys(workouts)
    .filter((dateKey) =>
      getExercisesFromDay(workouts[dateKey]).some((ex) => matchesExercise(ex, exercise))
    )
    .sort()
    .reverse();

  if (dateKeys.length === 0) {
    return { maxWeightLbs, maxDurationMinutes, maxSet, avgSet, lastInitialSet: null };
  }

  const lastDate = dateKeys[0];
  const lastEx = getExercisesFromDay(workouts[lastDate]).find((ex) =>
    matchesExercise(ex, exercise)
  );

  if (!lastEx || lastEx.sets.length === 0) {
    return { maxWeightLbs, maxDurationMinutes, maxSet, avgSet, lastInitialSet: null };
  }

  if (isCardio || lastEx.isCardio) {
    const duration = parsePositiveInt(getExerciseRepsOrDuration(lastEx));
    return {
      maxWeightLbs,
      maxDurationMinutes,
      maxSet,
      avgSet,
      lastInitialSet: {
        dateKey: lastDate,
        repsDisplay: duration == null ? "—" : String(duration),
        weightLbs: null,
      },
    };
  }

  const firstWorking =
    lastEx.sets.find((set) => isWorkingSet(set) && isCompletedSet(set)) ?? lastEx.sets[0];
  const weightLbs = parseWeightLbs(firstWorking.weight);

  return {
    maxWeightLbs,
    maxDurationMinutes,
    maxSet,
    avgSet,
    lastInitialSet: {
      dateKey: lastDate,
      repsDisplay: firstWorking.reps.trim() === "" ? "—" : firstWorking.reps.trim(),
      weightLbs: Number.isNaN(weightLbs) || weightLbs <= 0 ? null : weightLbs,
    },
  };
}

export { hasLoggedExercise as n, getExerciseLogStats as t };
