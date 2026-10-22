import { getDayExercises, exerciseIsCardio, type WorkoutLog } from '@/types/workout'
import { predictWorkoutGoals } from '@/utils/progressiveOverload'

export type AdaptiveSuggestion = {
  exerciseName: string
  suggestedReps: string
  suggestedWeightLbs: number
  reason: string
}

/** Next-session targets from logged history. Cardio is skipped. */
export function suggestNextSession(log: WorkoutLog, limit = 6): AdaptiveSuggestion[] {
  const dates = Object.keys(log).sort()
  const seen = new Set<string>()
  const suggestions: AdaptiveSuggestion[] = []

  for (let i = dates.length - 1; i >= 0 && suggestions.length < limit; i--) {
    const dateKey = dates[i]!
    for (const ex of getDayExercises(log[dateKey])) {
      if (exerciseIsCardio(ex) || ex.isCircuit) continue
      const key = ex.name.trim().toLowerCase()
      if (!key || seen.has(key)) continue
      seen.add(key)
      const pred = predictWorkoutGoals(ex.name, log, {
        currentTargetReps: ex.targetReps,
        currentTargetWeightLbs: Number(ex.targetWeight) || 0,
        excludeDateKey: undefined,
      })
      if (!pred.hasHistory) continue
      suggestions.push({
        exerciseName: ex.name,
        suggestedReps: pred.suggestedLogReps || pred.suggestedReps,
        suggestedWeightLbs: pred.suggestedWeightLbs,
        reason: pred.reason,
      })
      if (suggestions.length >= limit) break
    }
  }

  return suggestions
}
