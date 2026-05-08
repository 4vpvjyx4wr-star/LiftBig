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
 */
export function estimatePlanDurationMinutes(
  template: WorkoutTemplate,
  assumptions: PlanDurationAssumptions = DEFAULT_PLAN_DURATION_ASSUMPTIONS,
): number {
  const totalSets = template.exercises.reduce((sum, ex) => sum + ex.sets.length, 0)
  if (totalSets <= 0) return 0
  return totalSets * assumptions.minutesPerSet + (totalSets - 1) * assumptions.minutesRestBetweenSets
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
