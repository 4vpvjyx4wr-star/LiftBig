import { DEFAULT_PLANS } from "./defaultPlans";

export type SetLog = { id?: string; reps: string; weight: string; isWarmup?: boolean; checked?: boolean };
export type ExerciseLog = { id: string; name: string; sets: SetLog[]; isCircuit?: boolean };
export type WorkoutLog = { [dateKey: string]: ExerciseLog[] };
export type TemplateExercise = { id: string; name: string; isCircuit?: boolean };
export type WorkoutTemplate = { id: string; name: string; exercises: TemplateExercise[] };

export type CompletedSet = { weight: number; reps: number };

export type LiftStatSet = { weight: number; reps: number };

export type LiftStats = {
  max: LiftStatSet | null;
  avg: LiftStatSet | null;
  setCount: number;
};

/** Epley formula — compares sets with different weight/rep combos fairly. */
export function estimate1RM(weight: number, reps: number): number {
  if (weight <= 0 || reps <= 0) return 0;
  if (reps === 1) return weight;
  return weight * (1 + reps / 30);
}

export function formatSetStat(weight: number, reps: number): string {
  const w = Number.isInteger(weight) ? String(weight) : String(Math.round(weight * 10) / 10);
  return `${w} x ${Math.round(reps)}`;
}

function parseCompletedSet(set: SetLog): CompletedSet | null {
  if (set.isWarmup) return null;
  const reps = parseInt(set.reps, 10);
  const weight = parseFloat(set.weight);
  if (isNaN(reps) || reps <= 0 || isNaN(weight) || weight <= 0) return null;
  return { weight, reps };
}

export function getCompletedSetsForExercise(
  allWorkouts: WorkoutLog,
  exerciseName: string
): CompletedSet[] {
  const out: CompletedSet[] = [];
  const target = exerciseName.toLowerCase();

  for (const exercises of Object.values(allWorkouts)) {
    const match = exercises.find((ex) => ex.name.toLowerCase() === target);
    if (!match || match.isCircuit) continue;
    for (const set of match.sets) {
      const parsed = parseCompletedSet(set);
      if (parsed) out.push(parsed);
    }
  }
  return out;
}

export function computeLiftStats(sets: CompletedSet[]): LiftStats {
  if (sets.length === 0) {
    return { max: null, avg: null, setCount: 0 };
  }

  let bestSet = sets[0];
  let bestE1RM = estimate1RM(bestSet.weight, bestSet.reps);

  for (let i = 1; i < sets.length; i++) {
    const e1rm = estimate1RM(sets[i].weight, sets[i].reps);
    if (e1rm > bestE1RM) {
      bestE1RM = e1rm;
      bestSet = sets[i];
    }
  }

  const totalWeight = sets.reduce((sum, s) => sum + s.weight, 0);
  const totalReps = sets.reduce((sum, s) => sum + s.reps, 0);
  const avgWeight = Math.round((totalWeight / sets.length) * 10) / 10;
  const avgReps = Math.round(totalReps / sets.length);

  return {
    max: { weight: bestSet.weight, reps: bestSet.reps },
    avg: { weight: avgWeight, reps: avgReps },
    setCount: sets.length,
  };
}

export function getLiftStatsForExercise(
  allWorkouts: WorkoutLog,
  exerciseName: string
): LiftStats {
  return computeLiftStats(getCompletedSetsForExercise(allWorkouts, exerciseName));
}

export function getLibraryLiftNames(
  templates: WorkoutTemplate[],
  workouts: WorkoutLog
): string[] {
  const names = new Set<string>();

  for (const plan of DEFAULT_PLANS) {
    for (const ex of plan.exercises) {
      if (ex.name?.trim() && !ex.isCircuit) names.add(ex.name.trim());
    }
  }
  for (const plan of templates) {
    for (const ex of plan.exercises) {
      if (ex.name?.trim() && !ex.isCircuit) names.add(ex.name.trim());
    }
  }
  for (const exercises of Object.values(workouts)) {
    for (const ex of exercises) {
      if (ex.name?.trim() && !ex.isCircuit) names.add(ex.name.trim());
    }
  }

  return [...names].sort((a, b) => a.localeCompare(b));
}
