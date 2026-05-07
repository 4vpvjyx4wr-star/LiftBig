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
      libraryId: tex.libraryId,
      isCircuit: tex.isCircuit,
      targetReps: first?.targetReps,
      targetWeight: first?.targetWeight,
      sets: tex.sets.map(() => {
        // Plan assignment creates empty working sets so users enter all reps/weight manually.
        const base = {
          id: newId(),
          reps: '',
          weight: '',
        }
        return tex.isCircuit ? { ...base, checked: false } : base
      }),
    }
  })
}
