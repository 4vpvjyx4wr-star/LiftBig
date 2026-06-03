import type { WorkoutTemplate } from '@/types/workout'

/** Minutes assumed per working set (performing the set). */
export const PLAN_DURATION_MINUTES_PER_SET = 1

/** Minutes assumed rest between consecutive sets (in workout order). */
export const PLAN_DURATION_MINUTES_REST_BETWEEN_SETS = 1

export type PlanDurationAssumptions = {
  minutesPerSet: number
  minutesRestBetweenSets: number
}

export const DEFAULT_PLAN_DURATION_ASSUMPTIONS: PlanDurationAssumptions = {
  minutesPerSet: PLAN_DURATION_MINUTES_PER_SET,
  minutesRestBetweenSets: PLAN_DURATION_MINUTES_REST_BETWEEN_SETS,
}

export function planDurationAssumptionsFromSeconds(
  averageLiftSeconds: number,
  averageRestSeconds: number,
): PlanDurationAssumptions {
  return {
    minutesPerSet: Math.max(0, averageLiftSeconds) / 60,
    minutesRestBetweenSets: Math.max(0, averageRestSeconds) / 60,
  }
}

/**
 * Estimated session length: each set counts as `PER_SET` minutes of work plus
 * `REST_BETWEEN_SETS` minutes between every consecutive pair of sets.
 * Cardio entries use their target duration in minutes when set.
 */
export function estimatePlanDurationMinutes(
  template: WorkoutTemplate,
  assumptions: PlanDurationAssumptions = DEFAULT_PLAN_DURATION_ASSUMPTIONS,
): number {
  let total = 0
  let strengthSets = 0

  for (const ex of template.exercises) {
    if (ex.isCardio) {
      const raw = (ex.targetDuration ?? ex.sets[0]?.targetReps ?? '').trim()
      const mins = parseInt(raw, 10)
      if (!Number.isNaN(mins) && mins > 0) total += mins
      continue
    }
    strengthSets += ex.sets.length
  }

  if (strengthSets <= 0) return total
  const strengthMinutes =
    strengthSets * assumptions.minutesPerSet +
    (strengthSets - 1) * assumptions.minutesRestBetweenSets
  return total + strengthMinutes
}

export function formatPlanDurationEstimate(minutes: number): string {
  const rounded = Math.max(0, Math.round(minutes))
  if (rounded <= 0) return '~0 min'
  if (rounded < 60) return `~${rounded} min`
  const h = Math.floor(rounded / 60)
  const m = rounded % 60
  if (m === 0) return `~${h} hr`
  return `~${h} hr ${m} min`
}
