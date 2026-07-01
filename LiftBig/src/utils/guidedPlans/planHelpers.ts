import type { TemplateExercise, WorkoutTemplate } from '@/types/workout'

export function row(n: number, reps: string, weight: string) {
  return Array.from({ length: n }, () => ({ targetReps: reps, targetWeight: weight }))
}

export function te(
  planId: string,
  slug: string,
  name: string,
  sets: number,
  reps: string,
  weight: string,
  isCircuit = false,
  libraryId?: string,
): TemplateExercise {
  return {
    id: `${planId}__${slug}`,
    name,
    libraryId,
    isCircuit,
    sets: row(sets, reps, weight),
  }
}

export function repeatTemplate(
  id: string,
  name: string,
  folderId: string,
  exercises: TemplateExercise[],
  notes?: string,
): WorkoutTemplate {
  return { id, name, folderId, exercises, notes }
}

export function dayTemplate(
  id: string,
  name: string,
  folderId: string,
  exercises: TemplateExercise[],
  notes?: string,
): WorkoutTemplate {
  return { id, name, folderId, exercises, notes }
}
