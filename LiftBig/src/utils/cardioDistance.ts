import type { Exercise, TemplateExercise } from '@/types/workout'
import { exerciseIsCardio } from '@/types/workout'

/** Cardio library entries where optional distance logging makes sense. */
export const DISTANCE_CARDIO_LIBRARY_IDS = new Set([
  'walking',
  'treadmill-walking',
  'running',
  'treadmill-running',
  'stairmaster',
  'swimming',
  'hiking',
  'indoor-cycling',
  'outdoor-cycling',
  'rowing-machine',
  'elliptical',
  'cross-country-skiing',
  'kayaking',
  'golf-walking',
  'roller-skating',
])

export function cardioExerciseSupportsDistance(
  exercise: Pick<Exercise | TemplateExercise, 'libraryId' | 'isCardio'>,
): boolean {
  if (!exerciseIsCardio(exercise)) return false
  if (!exercise.libraryId) return false
  return DISTANCE_CARDIO_LIBRARY_IDS.has(exercise.libraryId)
}
