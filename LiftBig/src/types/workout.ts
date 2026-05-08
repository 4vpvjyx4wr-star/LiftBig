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

export type WorkoutDay = {
  exercises: Exercise[]
  notes?: string
}

export type WorkoutLog = Record<string, WorkoutDay | Exercise[]>

export function getDayExercises(entry: WorkoutLog[string] | undefined): Exercise[] {
  if (!entry) return []
  if (Array.isArray(entry)) return entry
  return entry.exercises
}

export function getDayNotes(entry: WorkoutLog[string] | undefined): string {
  if (!entry || Array.isArray(entry)) return ''
  return entry.notes ?? ''
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
  folderId?: string | null
}

export type TemplateFolder = {
  id: string
  name: string
  purpose?: string
}
