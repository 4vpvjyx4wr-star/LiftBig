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
  /** Logged rest day: counts toward consistency; no exercises */
  isRestDay?: boolean
}

export type WorkoutLogDay = Exercise[] | WorkoutDay

export type WorkoutLog = Record<string, WorkoutLogDay>

export function getDayExercises(dayEntry: WorkoutLogDay | undefined): Exercise[] {
  if (dayEntry == null) return []
  if (Array.isArray(dayEntry)) return dayEntry
  return Array.isArray(dayEntry.exercises) ? dayEntry.exercises : []
}

export function isRestDayEntry(dayEntry: WorkoutLogDay | undefined): boolean {
  if (dayEntry == null) return false
  if (Array.isArray(dayEntry)) return false
  return dayEntry.isRestDay === true
}

export type TemplateSet = { targetReps: string; targetWeight: string }

export type TemplateExercise = {
  id: string
  name: string
  libraryId?: string
  sets: TemplateSet[]
  isCircuit?: boolean
  /** Optional targets for the workout log (same idea as live “Set goals”). */
  targetReps?: string
  targetWeight?: string
}

export type WorkoutTemplate = {
  id: string
  name: string
  exercises: TemplateExercise[]
  isCircuit?: boolean
  folderId?: string | null
}

export type TemplateFolder = {
  id: string
  name: string
  purpose?: string
}
