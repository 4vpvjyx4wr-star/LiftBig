import type { WorkoutTemplate } from '@/types/workout'

/** Minutes assumed per working set (performing the set). */
export const PLAN_DURATION_MINUTES_PER_SET = 1

/** Minutes assumed rest between consecutive sets (in workout order). */
export const PLAN_DURATION_MINUTES_REST_BETWEEN_SETS = 1

/**
 * Estimated session length: each set counts as `PER_SET` minutes of work plus
 * `REST_BETWEEN_SETS` minutes between every consecutive pair of sets.
 */
export function estimatePlanDurationMinutes(template: WorkoutTemplate): number {
  const totalSets = template.exercises.reduce((sum, ex) => sum + ex.sets.length, 0)
  if (totalSets <= 0) return 0
  return (
    totalSets * PLAN_DURATION_MINUTES_PER_SET +
    (totalSets - 1) * PLAN_DURATION_MINUTES_REST_BETWEEN_SETS
  )
}

export function formatPlanDurationEstimate(minutes: number): string {
  if (minutes <= 0) return '~0 min'
  if (minutes < 60) return `~${minutes} min`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  if (m === 0) return `~${h} hr`
  return `~${h} hr ${m} min`
}
