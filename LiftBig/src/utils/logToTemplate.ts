import type { Exercise, TemplateExercise } from '@/types/workout'
import {
  cardioLoggedDistance,
  cardioLoggedDurationMinutes,
  cardioTargetDistance,
  cardioTargetDurationMinutes,
} from '@/types/workout'
import { resolveExerciseIsCore } from '@/utils/exerciseLibrary'

function newId(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 11)}`
}

/** Map today's logged exercises into a new plan template (goals from logged or prior targets). */
export function logExercisesToTemplate(exercises: Exercise[]): TemplateExercise[] {
  return exercises.map((ex) => {
    if (ex.isCardio) {
      const duration =
        cardioLoggedDurationMinutes(ex) || cardioTargetDurationMinutes(ex) || ''
      const distance = cardioLoggedDistance(ex) || cardioTargetDistance(ex) || ''
      return {
        id: newId(),
        name: ex.name,
        libraryId: ex.libraryId,
        isCardio: true,
        targetDuration: duration || undefined,
        targetDistance: distance || undefined,
        sets: [{ targetReps: duration, targetWeight: distance }],
      }
    }

    const isCore = resolveExerciseIsCore({
      libraryId: ex.libraryId,
      isCore: ex.isCore,
      isCircuit: ex.isCircuit,
      name: ex.name,
    })

    if (ex.isCircuit) {
      return {
        id: newId(),
        name: ex.name,
        libraryId: ex.libraryId,
        isCircuit: true,
        sets: ex.sets.map((s) => ({
          targetReps: (s.reps ?? '').trim(),
          targetWeight: (s.weight ?? '').trim(),
        })),
      }
    }

    const repsGoal = (ex.targetReps ?? '').trim()
    const weightGoal = (ex.targetWeight ?? '').trim()

    return {
      id: newId(),
      name: ex.name,
      libraryId: ex.libraryId,
      isCore: isCore ? true : undefined,
      targetReps: repsGoal || undefined,
      targetWeight: weightGoal || undefined,
      targetTimeSeconds: ex.targetTimeSeconds,
      supersetGroupId: ex.supersetGroupId,
      supersetLabel: ex.supersetLabel,
      supersetOrder: ex.supersetOrder,
      sets: ex.sets.map((s) => ({
        targetReps: (s.reps ?? '').trim() || repsGoal,
        targetWeight: (s.weight ?? '').trim() || weightGoal,
      })),
    }
  })
}
