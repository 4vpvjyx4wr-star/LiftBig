import {
  getDayExercises,
  setCountsTowardProgress,
  cardioLoggedDurationMinutes,
  type Exercise,
  type SetLog,
  type WorkoutLog,
} from '@/types/workout'
import type { LibraryExercise } from '@/utils/exerciseLibrary'
import { parseStoredLbs } from '@/utils/units'

function parseDurationMinutes(raw: string): number | null {
  const t = raw.trim()
  if (!t) return null
  const n = parseInt(t, 10)
  return !Number.isNaN(n) && n > 0 ? n : null
}

function norm(s: string): string {
  return s.trim().toLowerCase()
}

/** Logged exercise row matches a library entry by `libraryId` or case-insensitive name. */
export function exerciseMatchesLibrary(
  logEx: Exercise,
  libraryExercise: LibraryExercise,
): boolean {
  if (logEx.libraryId === libraryExercise.id) return true
  return norm(logEx.name) === norm(libraryExercise.name)
}

/** True if this library exercise appears in the log (by `libraryId` or matching name). */
export function hasUserLoggedLibraryExercise(
  log: WorkoutLog,
  libraryExercise: LibraryExercise,
): boolean {
  for (const dayEntry of Object.values(log)) {
    const exercises = getDayExercises(dayEntry)
    for (const ex of exercises) {
      if (exerciseMatchesLibrary(ex, libraryExercise)) return true
    }
  }
  return false
}

/** Set counts toward "at least one rep" for max-weight stats. */
function setHasAtLeastOneRep(set: SetLog): boolean {
  const t = set.reps.trim()
  if (t === '') return false
  const n = parseInt(t, 10)
  if (!Number.isNaN(n) && n >= 1) return true
  if (t.toLowerCase().includes('amrap')) return true
  return false
}

export type LibraryExerciseLogStats = {
  /** Heaviest load for a set with at least one recorded rep, across all history. */
  maxWeightLbs: number | null
  /** Longest logged duration in minutes (cardio only). */
  maxDurationMinutes: number | null
  /** First set of the most recent day this exercise was logged. */
  lastInitialSet: {
    dateKey: string
    repsDisplay: string
    weightLbs: number | null
  } | null
}

/**
 * Max load (for sets with ≥1 rep) and the first set of the most recent session,
 * matching by library id or exercise name (same rules as the logged-before check).
 */
export function getLibraryExerciseLogStats(
  log: WorkoutLog,
  libraryExercise: LibraryExercise,
): LibraryExerciseLogStats {
  let maxWeightLbs: number | null = null
  let maxDurationMinutes: number | null = null
  const isCardio = libraryExercise.isCardio === true

  for (const dayEntry of Object.values(log)) {
    const exercises = getDayExercises(dayEntry)
    for (const ex of exercises) {
      if (!exerciseMatchesLibrary(ex, libraryExercise)) continue
      if (isCardio || ex.isCardio) {
        const mins = parseDurationMinutes(cardioLoggedDurationMinutes(ex))
        if (mins != null) {
          maxDurationMinutes =
            maxDurationMinutes === null ? mins : Math.max(maxDurationMinutes, mins)
        }
        continue
      }
      for (const set of ex.sets) {
        if (!setCountsTowardProgress(set)) continue
        const w = parseStoredLbs(set.weight)
        if (Number.isNaN(w) || w <= 0) continue
        if (!setHasAtLeastOneRep(set)) continue
        maxWeightLbs = maxWeightLbs === null ? w : Math.max(maxWeightLbs, w)
      }
    }
  }

  const datesWithExercise = Object.keys(log)
    .filter((dk) => getDayExercises(log[dk]).some((e) => exerciseMatchesLibrary(e, libraryExercise)))
    .sort()
    .reverse()

  if (datesWithExercise.length === 0) {
    return { maxWeightLbs, maxDurationMinutes, lastInitialSet: null }
  }

  const latestKey = datesWithExercise[0]!
  const latestEx = getDayExercises(log[latestKey]).find((e) =>
    exerciseMatchesLibrary(e, libraryExercise),
  )
  if (!latestEx || latestEx.sets.length === 0) {
    return { maxWeightLbs, maxDurationMinutes, lastInitialSet: null }
  }

  if (isCardio || latestEx.isCardio) {
    const duration = cardioLoggedDurationMinutes(latestEx)
    return {
      maxWeightLbs,
      maxDurationMinutes,
      lastInitialSet: {
        dateKey: latestKey,
        repsDisplay: duration === '' ? '—' : duration,
        weightLbs: null,
      },
    }
  }

  const first = latestEx.sets.find((s) => setCountsTowardProgress(s)) ?? latestEx.sets[0]!
  const firstW = parseStoredLbs(first.weight)
  return {
    maxWeightLbs,
    maxDurationMinutes,
    lastInitialSet: {
      dateKey: latestKey,
      repsDisplay: first.reps.trim() === '' ? '—' : first.reps.trim(),
      weightLbs: Number.isNaN(firstW) || firstW <= 0 ? null : firstW,
    },
  }
}
