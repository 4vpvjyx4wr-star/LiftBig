import {
  cardioLoggedDurationMinutes,
  cardioTargetDurationMinutes,
  exerciseIsCardio,
  type Exercise,
} from '@/types/workout'
import type { PlanDurationAssumptions } from '@/utils/planDuration'
import { formatPlanDurationEstimate } from '@/utils/planDuration'
import { lbsToKg } from '@/utils/units'

/** Compendium of Physical Activities — moderate resistance training. */
export const STRENGTH_TRAINING_MET = 5

/** MET values for cardio library entries (moderate effort unless noted). */
const CARDIO_MET_BY_LIBRARY_ID: Record<string, number> = {
  walking: 3.5,
  'treadmill-walking': 3.5,
  running: 9.8,
  'treadmill-running': 9.8,
  stairmaster: 9,
  swimming: 5.8,
  hiking: 6,
  'indoor-cycling': 6.8,
  'outdoor-cycling': 6.8,
  tennis: 7.3,
  pickleball: 6.5,
  'table-tennis': 4,
  basketball: 6.5,
  soccer: 7,
  volleyball: 4,
  'rowing-machine': 7,
  elliptical: 5,
  'jump-rope': 11,
  boxing: 7.8,
  kickboxing: 7.3,
  racquetball: 7,
  badminton: 5.5,
  'golf-walking': 4.3,
  'dance-cardio': 6.5,
  'yoga-flow': 3,
  pilates: 3,
  'martial-arts': 7.3,
  'rock-climbing': 8,
  skiing: 6.3,
  'cross-country-skiing': 9,
  snowboarding: 5.3,
  kayaking: 5,
  paddleboarding: 6,
  'roller-skating': 7,
  'hiit-class': 8,
}

const DEFAULT_CARDIO_MET = 5

export function metForCardioLibraryId(libraryId: string | undefined): number {
  if (!libraryId) return DEFAULT_CARDIO_MET
  return CARDIO_MET_BY_LIBRARY_ID[libraryId] ?? DEFAULT_CARDIO_MET
}

function caloriesFromMet(minutes: number, met: number, bodyWeightKg: number): number {
  if (minutes <= 0 || met <= 0 || bodyWeightKg <= 0) return 0
  return met * bodyWeightKg * (minutes / 60)
}

function strengthExerciseMinutes(setCount: number, assumptions: PlanDurationAssumptions): number {
  if (setCount <= 0) return 0
  return (
    setCount * assumptions.minutesPerSet +
    (setCount - 1) * assumptions.minutesRestBetweenSets
  )
}

export type WorkoutCalorieEstimate = {
  calories: number
  durationMinutes: number
}

/**
 * Estimate calories burned for a logged workout using MET × body weight × duration.
 * Cardio uses logged duration (or target when not yet logged). Strength uses set count
 * and the user's average lift/rest settings.
 */
export function estimateWorkoutCalories(
  exercises: Exercise[],
  bodyWeightLbs: number,
  assumptions: PlanDurationAssumptions,
): WorkoutCalorieEstimate | null {
  if (!Number.isFinite(bodyWeightLbs) || bodyWeightLbs <= 0 || exercises.length === 0) {
    return null
  }

  const bodyWeightKg = lbsToKg(bodyWeightLbs)
  let totalCalories = 0
  let totalMinutes = 0

  for (const ex of exercises) {
    if (exerciseIsCardio(ex)) {
      const logged = cardioLoggedDurationMinutes(ex)
      const target = cardioTargetDurationMinutes(ex)
      const raw = logged || target
      const mins = parseInt(raw, 10)
      if (Number.isNaN(mins) || mins <= 0) continue
      const met = metForCardioLibraryId(ex.libraryId)
      totalCalories += caloriesFromMet(mins, met, bodyWeightKg)
      totalMinutes += mins
      continue
    }

    const setCount = ex.sets.length
    const mins = strengthExerciseMinutes(setCount, assumptions)
    if (mins <= 0) continue
    totalCalories += caloriesFromMet(mins, STRENGTH_TRAINING_MET, bodyWeightKg)
    totalMinutes += mins
  }

  if (totalMinutes <= 0) return null

  return {
    calories: Math.round(totalCalories),
    durationMinutes: totalMinutes,
  }
}

export function formatWorkoutCalories(calories: number): string {
  const n = Math.max(0, Math.round(calories))
  return `~${n.toLocaleString()} kcal`
}

export function formatWorkoutCalorieSummary(estimate: WorkoutCalorieEstimate): string {
  const duration = formatPlanDurationEstimate(estimate.durationMinutes)
  return `${formatWorkoutCalories(estimate.calories)} · ${duration}`
}
