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
  /** Cardio / sports: duration-only logging (no weight). */
  isCardio?: boolean
  /** Target duration in minutes (plans and optional workout goals). */
  targetDuration?: string
  /** Optional goal distance for distance-based cardio (numeric string; unit from settings). */
  targetDistance?: string
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

/** Merge exercises with preserved day metadata (user notes, assigned plan, rest flag). */
export function buildWorkoutDayEntry(
  exercises: Exercise[],
  existing: WorkoutLogDay | undefined,
  options?: { userNotes?: string | null },
): WorkoutDay | Exercise[] {
  const prior = existing && !Array.isArray(existing) ? existing : undefined
  const userNotes =
    options?.userNotes === null
      ? undefined
      : options?.userNotes !== undefined
        ? options.userNotes.trim() || undefined
        : prior?.notes?.trim() || undefined

  const planName = prior?.planName
  const planFolderName = prior?.planFolderName
  const planNotes = prior?.planNotes
  const isRestDay = prior?.isRestDay === true && exercises.length === 0

  const needsObject =
    userNotes !== undefined ||
    planName !== undefined ||
    planFolderName !== undefined ||
    planNotes !== undefined ||
    isRestDay

  if (!needsObject) return exercises

  const entry: WorkoutDay = { exercises }
  if (userNotes !== undefined) entry.notes = userNotes
  if (planName) entry.planName = planName
  if (planFolderName) entry.planFolderName = planFolderName
  if (planNotes) entry.planNotes = planNotes
  if (isRestDay) entry.isRestDay = true
  return entry
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
  /** Cardio / sports: duration-only (no weight). */
  isCardio?: boolean
  /** Target duration in minutes. */
  targetDuration?: string
  /** Optional goal distance for distance-based cardio (numeric string; unit from settings). */
  targetDistance?: string
  /** Optional targets for the workout log (same idea as live “Set goals”). */
  targetReps?: string
  targetWeight?: string
}

/** Whether an exercise should use duration-only cardio UI and storage. */
export function exerciseIsCardio(
  ex: Pick<Exercise | TemplateExercise, 'isCardio' | 'libraryId'>,
): boolean {
  return ex.isCardio === true
}

/** Goal duration in minutes for cardio (explicit field, then legacy set target). */
export function cardioTargetDurationMinutes(
  ex: Pick<Exercise | TemplateExercise, 'targetDuration' | 'sets' | 'isCardio'>,
): string {
  const explicit = (ex.targetDuration ?? '').trim()
  if (explicit) return explicit
  const first = ex.sets[0]
  if (!first) return ''
  if ('targetReps' in first) return (first.targetReps ?? '').trim()
  return ''
}

/** Logged duration in minutes for a cardio exercise (stored on the single set’s reps field). */
export function cardioLoggedDurationMinutes(ex: Exercise): string {
  return (ex.sets[0]?.reps ?? '').trim()
}

/** Goal distance for distance-based cardio. */
export function cardioTargetDistance(
  ex: Pick<Exercise | TemplateExercise, 'targetDistance'>,
): string {
  return (ex.targetDistance ?? '').trim()
}

/** Logged distance for distance-based cardio (stored on the single set’s weight field). */
export function cardioLoggedDistance(ex: Exercise): string {
  return (ex.sets[0]?.weight ?? '').trim()
}

export function cardioExerciseComplete(ex: Exercise): boolean {
  const d = cardioLoggedDurationMinutes(ex)
  if (!d) return false
  const n = parseInt(d, 10)
  return !Number.isNaN(n) && n > 0
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
