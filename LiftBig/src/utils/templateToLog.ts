import type { Exercise, TemplateExercise, WorkoutTemplate } from '@/types/workout'

function newId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 11)}`
}

/** Maps a template to logged exercises with circuit + target fields preserved (Vue spec). */
export function cloneTemplateToExercises(template: WorkoutTemplate): Exercise[] {
  return template.exercises.map((tex: TemplateExercise) => {
    const first = tex.sets[0]
    return {
      id: newId(),
      name: tex.name,
      isCircuit: tex.isCircuit,
      targetReps: first?.targetReps,
      targetWeight: first?.targetWeight,
      sets: tex.sets.map((s) => {
        const base = { id: newId(), reps: s.targetReps, weight: s.targetWeight }
        return tex.isCircuit ? { ...base, checked: false } : base
      }),
    }
  })
}
