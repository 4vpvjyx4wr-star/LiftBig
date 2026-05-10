export type SetLog = {
  id: string
  reps: string
  weight: string
  checked?: boolean
}

export type Exercise = {
  id: string
  name: string
  libraryId?: string
  sets: SetLog[]
  isCircuit?: boolean
  targetReps?: string
  targetWeight?: string
}

/** Single-day payload (with optional notes), or legacy flat exercise list */
export type WorkoutDay = {
  exercises: Exercise[]
  notes?: string
}

export type WorkoutLogDay = Exercise[] | WorkoutDay

export type WorkoutLog = Record<string, WorkoutLogDay>

export function getDayExercises(dayEntry: WorkoutLogDay | undefined): Exercise[] {
  if (dayEntry == null) return []
  if (Array.isArray(dayEntry)) return dayEntry
  return Array.isArray(dayEntry.exercises) ? dayEntry.exercises : []
}

export type TemplateSet = { targetReps: string; targetWeight: string }

export type TemplateExercise = {
  id: string
  name: string
  libraryId?: string
  sets: TemplateSet[]
  isCircuit?: boolean
}

export type WorkoutTemplate = {
  id: string
  name: string
  exercises: TemplateExercise[]
  isCircuit?: boolean
}
