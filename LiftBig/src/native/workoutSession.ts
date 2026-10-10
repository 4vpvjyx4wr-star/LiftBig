import {
  buildWorkoutDayEntry,
  getDayExercises,
  type Exercise,
  type WorkoutLog,
} from '@/types/workout'
import { storedLbsStringToDisplay } from '@/utils/units'
import type { WeightUnit } from '@/utils/units'

export type WatchSession =
  | { version: 1; locked: true; reason: 'pro' | 'idle' }
  | {
      version: 1
      locked: false
      dateKey: string
      exerciseId: string
      exerciseName: string
      targetWeightDisplay: string
      targetReps: string
      setCount: number
      currentSetIndex: number
      restSeconds: number
      weightUnit: WeightUnit
    }

export type CompanionMessage = {
  version: 1
  kind: 'completeSet' | 'adjustSet' | 'skipRest'
  dateKey: string
  exerciseId: string
  setIndex: number
  reps?: string
  /** Weight already converted to stored pounds. */
  weightLbs?: string
}

function firstOpenSetIndex(ex: Exercise): number {
  const idx = ex.sets.findIndex((set) => set.checked !== true && (!set.reps.trim() || !set.weight.trim()))
  if (idx >= 0) return idx
  const unchecked = ex.sets.findIndex((set) => set.checked !== true)
  return unchecked >= 0 ? unchecked : 0
}

export function buildWatchSession(
  dateKey: string,
  exercises: Exercise[],
  restSeconds: number,
  weightUnit: WeightUnit,
  pro: boolean,
): WatchSession {
  if (!pro) return { version: 1, locked: true, reason: 'pro' }
  const exercise = exercises.find((ex) => !ex.isCardio && !ex.isCircuit) ?? exercises[0]
  if (!exercise) return { version: 1, locked: true, reason: 'idle' }
  const currentSetIndex = firstOpenSetIndex(exercise)
  return {
    version: 1,
    locked: false,
    dateKey,
    exerciseId: exercise.id,
    exerciseName: exercise.name,
    targetWeightDisplay: storedLbsStringToDisplay(exercise.targetWeight ?? '', weightUnit),
    targetReps: (exercise.targetReps ?? '').trim(),
    setCount: Math.max(exercise.sets.length, 1),
    currentSetIndex,
    restSeconds,
    weightUnit,
  }
}

export function applyCompanionMessage(log: WorkoutLog, message: CompanionMessage): WorkoutLog {
  if (message.kind === 'skipRest') return log
  const existing = log[message.dateKey]
  const exercises = getDayExercises(existing).map((ex) => ({
    ...ex,
    sets: ex.sets.map((set) => ({ ...set })),
  }))
  const exercise = exercises.find((ex) => ex.id === message.exerciseId)
  if (!exercise) return log
  while (exercise.sets.length <= message.setIndex) {
    exercise.sets.push({
      id: `watch-${exercise.id}-${exercise.sets.length}`,
      reps: '',
      weight: '',
      checked: false,
    })
  }
  const set = exercise.sets[message.setIndex]
  if (!set) return log
  if (message.reps != null) set.reps = message.reps
  if (message.weightLbs != null) set.weight = message.weightLbs
  if (message.kind === 'completeSet') set.checked = true
  return {
    ...log,
    [message.dateKey]: buildWorkoutDayEntry(exercises, existing),
  }
}
