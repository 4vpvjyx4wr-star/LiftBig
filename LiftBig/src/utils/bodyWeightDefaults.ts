import type { Exercise } from '@/types/workout'
import { DEFAULT_SETTINGS, type AppSettings } from '@/composables/useSettings'
import { resolveExerciseIsBodyweight } from '@/utils/exerciseLibrary'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { loadJson } from '@/utils/storage'
import { parseStoredLbs } from '@/utils/units'

export function readStoredBodyWeightLbs(): number {
  const s = loadJson<AppSettings>(LIFTBIG_STORAGE_KEYS.settings, DEFAULT_SETTINGS)
  const lbs = s.bodyWeightLbs ?? 0
  return Number.isFinite(lbs) && lbs > 0 ? lbs : 0
}

export function isEmptyOrZeroStoredWeight(w: string | undefined): boolean {
  const t = (w ?? '').trim()
  if (!t) return true
  const n = parseStoredLbs(t)
  return Number.isNaN(n) || n <= 0
}

export function storedBodyWeightLbsString(bodyWeightLbs: number): string {
  if (!Number.isFinite(bodyWeightLbs) || bodyWeightLbs <= 0) return ''
  return String(bodyWeightLbs)
}

export function defaultBodyWeightForExercise(
  exercise: Pick<Exercise, 'libraryId' | 'isCardio' | 'name' | 'isCircuit'>,
  bodyWeightLbs: number,
): string {
  if (bodyWeightLbs <= 0 || exercise.isCircuit || exercise.isCardio) return ''
  if (!resolveExerciseIsBodyweight(exercise)) return ''
  return storedBodyWeightLbsString(bodyWeightLbs)
}

/** Fill empty set weights and goal weight for bodyweight library exercises. */
export function applyBodyWeightDefaultsToExercise(ex: Exercise, bodyWeightLbs: number): Exercise {
  const defaultW = defaultBodyWeightForExercise(ex, bodyWeightLbs)
  if (!defaultW) return ex

  let changed = false
  const nextSets = ex.sets.map((s) => {
    if (!isEmptyOrZeroStoredWeight(s.weight)) return s
    changed = true
    return { ...s, weight: defaultW }
  })

  let targetWeight = ex.targetWeight
  if (isEmptyOrZeroStoredWeight(ex.targetWeight)) {
    changed = true
    targetWeight = defaultW
  }

  if (!changed) return ex
  return { ...ex, sets: nextSets, targetWeight }
}

export function applyBodyWeightDefaultsToExercises(
  exercises: Exercise[],
  bodyWeightLbs: number,
): Exercise[] {
  if (bodyWeightLbs <= 0) return exercises
  return exercises.map((ex) => applyBodyWeightDefaultsToExercise(ex, bodyWeightLbs))
}

export function defaultWeightForNewSet(
  exercise: Exercise,
  bodyWeightLbs: number,
): string {
  const prior = exercise.sets[exercise.sets.length - 1]?.weight ?? ''
  if (!isEmptyOrZeroStoredWeight(prior)) return prior.trim()
  return defaultBodyWeightForExercise(exercise, bodyWeightLbs)
}

/** After swapping to a bodyweight exercise, replace stale barbell weights with body weight. */
export function applyBodyWeightOnExerciseSwap(ex: Exercise, bodyWeightLbs: number): Exercise {
  if (bodyWeightLbs <= 0 || !resolveExerciseIsBodyweight(ex)) return ex
  const defaultW = storedBodyWeightLbsString(bodyWeightLbs)
  return {
    ...ex,
    targetWeight: defaultW,
    sets: ex.sets.map((s) => ({ ...s, weight: defaultW })),
  }
}
