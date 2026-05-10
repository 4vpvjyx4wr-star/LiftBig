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

export type WorkoutLog = Record<string, Exercise[]>

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
