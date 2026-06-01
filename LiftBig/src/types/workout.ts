export type SetLog = {
  id: string
  reps: string
  weight: string
  checked?: boolean
  /** Warmup sets are logged but excluded from strength/progress predictions. */
  isWarmup?: boolean
}

/** Whether this set should feed progress charts and progressive-overload logic. */
export function setCountsTowardProgress(set: SetLog): boolean {
  return set.isWarmup !== true
}

export type Exercise = {
  id: string
  name: string
  libraryId?: string
  sets: SetLog[]
  isCircuit?: boolean
  targetReps?: string
  targetWeight?: string
  /** Session notes for this exercise on the logged day (stored in the workout log). */
  notes?: string
}

/** Single-day payload (with optional notes), or legacy flat exercise list */
export type WorkoutDay = {
  exercises: Exercise[]
  notes?: string
  /** Logged rest day: counts toward consistency; no exercises */
  isRestDay?: boolean
  /** Name of the plan/template that was assigned to this day. */
  planName?: string
  /** Name of the folder the plan belonged to when assigned. */
  planFolderName?: string
  /** Coaching notes from the assigned plan template (week focus, activity, etc.). */
  planNotes?: string
}

export type WorkoutLogDay = Exercise[] | WorkoutDay

export type WorkoutLog = Record<string, WorkoutLogDay>

export function getDayExercises(dayEntry: WorkoutLogDay | undefined): Exercise[] {
  if (dayEntry == null) return []
  if (Array.isArray(dayEntry)) return dayEntry
  return Array.isArray(dayEntry.exercises) ? dayEntry.exercises : []
}

export function getDayPlanName(dayEntry: WorkoutLogDay | undefined): string | undefined {
  if (dayEntry == null) return undefined
  if (Array.isArray(dayEntry)) return undefined
  return dayEntry.planName
}

export function getDayPlanFolderName(dayEntry: WorkoutLogDay | undefined): string | undefined {
  if (dayEntry == null) return undefined
  if (Array.isArray(dayEntry)) return undefined
  return dayEntry.planFolderName
}

export function getDayPlanNotes(dayEntry: WorkoutLogDay | undefined): string | undefined {
  if (dayEntry == null) return undefined
  if (Array.isArray(dayEntry)) return undefined
  return dayEntry.planNotes
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
  /** Week focus, activity description, and other coaching shown when viewing or assigning the plan. */
  notes?: string
}

export type TemplateFolder = {
  id: string
  name: string
  purpose?: string
}
