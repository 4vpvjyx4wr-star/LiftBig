/** Re-exports from the production workout chunk (same logic, readable form). */
export type WorkoutSet = {
  reps: string;
  weight: string;
  isWarmup?: boolean;
  durationSeconds?: string;
};

export type LoggedExercise = {
  name: string;
  libraryId?: string;
  isCardio?: boolean;
  sets: WorkoutSet[];
  targetDuration?: string;
  targetReps?: string;
};

export function isWorkingSet(set: WorkoutSet): boolean {
  return set.isWarmup !== true;
}

export function getExercisesFromDay(
  day: LoggedExercise[] | { exercises: LoggedExercise[] } | null | undefined
): LoggedExercise[] {
  if (day == null) return [];
  if (Array.isArray(day)) return day;
  if (Array.isArray(day.exercises)) return day.exercises;
  return [];
}

export function cardioDurationMinutes(exercise: LoggedExercise): number | null {
  const fromField = (exercise.targetDuration ?? '').trim();
  const reps = (exercise.sets[0]?.reps ?? '').trim();
  const raw = fromField || reps;
  if (!raw) return null;
  const n = parseInt(raw, 10);
  return !Number.isNaN(n) && n > 0 ? n : null;
}
