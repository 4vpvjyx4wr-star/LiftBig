import type { Exercise, TemplateExercise, WorkoutTemplate } from '@/types/workout'

function newId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 11)}`
}

/**
 * Copies exercises to another day: preserves names, library links, circuit flag, set count,
 * and rep/weight goals — working sets are empty (no logged reps or weights).
 */
export function cloneExercisesForCopy(source: Exercise[]): Exercise[] {
  return source.map((ex) => ({
    id: newId(),
    name: ex.name,
    libraryId: ex.libraryId,
    isCircuit: ex.isCircuit,
    targetReps: ex.targetReps,
    targetWeight: ex.targetWeight,
    sets: ex.sets.map(() => {
      const base = { id: newId(), reps: '', weight: '' }
      return ex.isCircuit ? { ...base, checked: false } : base
    }),
  }))
}

/** Maps a template to logged exercises with circuit + target fields preserved (Vue spec). */
export function cloneTemplateToExercises(template: WorkoutTemplate): Exercise[] {
  return template.exercises.map((tex: TemplateExercise) => {
    const first = tex.sets[0]
    const repsGoal = (tex.targetReps ?? '').trim() || first?.targetReps
    const weightGoal = (tex.targetWeight ?? '').trim() || first?.targetWeight
    return {
      id: newId(),
      name: tex.name,
      libraryId: tex.libraryId,
      isCircuit: tex.isCircuit,
      targetReps: repsGoal,
      targetWeight: weightGoal,
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
