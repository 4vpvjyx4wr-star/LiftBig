import type { DistanceUnit } from '@/utils/distances'
import type { Exercise, WorkoutLog } from '@/types/workout'
import {
  cardioLoggedDistance,
  cardioLoggedDurationMinutes,
  cardioTargetDurationMinutes,
  exerciseIsCardio,
  getDayExercises,
  parseCardioLoggedCalories,
} from '@/types/workout'
import {
  estimateCardioExerciseCalories,
  estimateWorkoutCalories,
} from '@/utils/workoutCalories'
import type { PlanDurationAssumptions } from '@/utils/planDuration'

/** Activity names the native Health plugins understand. */
export type HealthActivity =
  | 'strength'
  | 'walking'
  | 'running'
  | 'cycling'
  | 'swimming'
  | 'rowing'
  | 'hiking'
  | 'elliptical'
  | 'stairs'
  | 'mixedCardio'

export type HealthWorkoutWrite = {
  id: string
  activity: HealthActivity
  startMs: number
  endMs: number
  energyKcal: number | null
  distanceMeters: number | null
}

const ACTIVITY_BY_LIBRARY: Record<string, HealthActivity> = {
  walking: 'walking',
  'treadmill-walking': 'walking',
  running: 'running',
  'treadmill-running': 'running',
  'indoor-cycling': 'cycling',
  'outdoor-cycling': 'cycling',
  swimming: 'swimming',
  'rowing-machine': 'rowing',
  hiking: 'hiking',
  elliptical: 'elliptical',
  stairmaster: 'stairs',
}

export function healthActivityForLibrary(libraryId: string | undefined): HealthActivity {
  if (!libraryId) return 'mixedCardio'
  return ACTIVITY_BY_LIBRARY[libraryId] ?? 'mixedCardio'
}

function minutesOf(ex: Exercise): number {
  const logged = parseInt(cardioLoggedDurationMinutes(ex), 10)
  if (Number.isFinite(logged) && logged > 0) return logged
  const target = parseInt(cardioTargetDurationMinutes(ex), 10)
  if (Number.isFinite(target) && target > 0) return target
  return 0
}

function metersOf(ex: Exercise, unit: DistanceUnit): number | null {
  const raw = parseFloat(cardioLoggedDistance(ex))
  if (!Number.isFinite(raw) || raw <= 0) return null
  return unit === 'mi' ? raw * 1609.344 : raw * 1000
}

function endMsFor(dateKey: string, now: Date): number {
  const today = now.toISOString().slice(0, 10)
  if (dateKey === today) return now.getTime()
  const parsed = Date.parse(`${dateKey}T18:00:00`)
  return Number.isNaN(parsed) ? now.getTime() : parsed
}

export function healthWritesForLog(
  log: WorkoutLog,
  options: {
    bodyWeightLbs: number
    assumptions: PlanDurationAssumptions
    distanceUnit: DistanceUnit
    now?: Date
  },
): HealthWorkoutWrite[] {
  const now = options.now ?? new Date()
  const writes: HealthWorkoutWrite[] = []

  for (const [dateKey, entry] of Object.entries(log)) {
    const exercises = getDayExercises(entry)
    if (exercises.length === 0) continue
    const end = endMsFor(dateKey, now)

    const strength = exercises.filter((ex) => !exerciseIsCardio(ex))
    const strengthEstimate = estimateWorkoutCalories(
      strength,
      options.bodyWeightLbs,
      options.assumptions,
    )
    if (strengthEstimate && strengthEstimate.durationMinutes > 0) {
      const durationMs = strengthEstimate.durationMinutes * 60 * 1000
      writes.push({
        id: `liftbig-${dateKey}-strength`,
        activity: 'strength',
        startMs: end - durationMs,
        endMs: end,
        energyKcal: strengthEstimate.calories,
        distanceMeters: null,
      })
    }

    exercises.filter(exerciseIsCardio).forEach((ex, index) => {
      const minutes = minutesOf(ex)
      if (minutes <= 0) return
      const custom = parseCardioLoggedCalories(ex)
      const estimated = estimateCardioExerciseCalories(ex, options.bodyWeightLbs)
      writes.push({
        id: `liftbig-${dateKey}-cardio-${index}`,
        activity: healthActivityForLibrary(ex.libraryId),
        startMs: end - minutes * 60 * 1000,
        endMs: end,
        energyKcal: custom ?? estimated,
        distanceMeters: metersOf(ex, options.distanceUnit),
      })
    })
  }

  return writes
}

/** True when an existing Health workout is the same session we would write. */
export function healthWorkoutDuplicates(
  existing: { activity: HealthActivity; startMs: number; endMs: number; syncId?: string },
  next: HealthWorkoutWrite,
): boolean {
  if (existing.syncId && existing.syncId === next.id) return true
  if (existing.activity !== next.activity) return false
  const existingMinutes = Math.abs(existing.endMs - existing.startMs) / 60000
  const nextMinutes = Math.abs(next.endMs - next.startMs) / 60000
  const sameDay = new Date(existing.startMs).toDateString() === new Date(next.startMs).toDateString()
  return sameDay && Math.abs(existingMinutes - nextMinutes) <= 1
}
