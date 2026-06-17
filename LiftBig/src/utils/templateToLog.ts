import type { Exercise, TemplateExercise, WorkoutTemplate } from '@/types/workout'
import { cardioTargetDurationMinutes } from '@/types/workout'

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
    isCardio: ex.isCardio,
    targetDuration: ex.targetDuration,
    targetDistance: ex.targetDistance,
    targetReps: ex.targetReps,
    targetWeight: ex.targetWeight,
    sets: ex.sets.map((s) => {
      if (ex.isCircuit) {
        return {
          id: newId(),
          reps: s.reps,
          weight: s.weight,
          checked: false,
        }
      }
      return { id: newId(), reps: '', weight: '' }
    }),
  }))
}

/** Maps a template to logged exercises with circuit + target fields preserved (Vue spec). */
export function cloneTemplateToExercises(template: WorkoutTemplate): Exercise[] {
  return template.exercises.map((tex: TemplateExercise) => {
    if (tex.isCardio) {
      const durationGoal = cardioTargetDurationMinutes(tex)
      return {
        id: newId(),
        name: tex.name,
        libraryId: tex.libraryId,
        isCardio: true,
        targetDuration: durationGoal || undefined,
        targetDistance: (tex.targetDistance ?? '').trim() || undefined,
        sets: [{ id: newId(), reps: '', weight: '' }],
      }
    }

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
      sets: tex.sets.map((ts) => {
        if (tex.isCircuit) {
          return {
            id: newId(),
            reps: (ts.targetReps ?? '').trim(),
            weight: (ts.targetWeight ?? '').trim(),
            checked: false,
          }
        }
        // Plan assignment creates empty working sets so users enter all reps/weight manually.
        return {
          id: newId(),
          reps: '',
          weight: '',
        }
      }),
    }
  })
}
