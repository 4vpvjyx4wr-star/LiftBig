import type { Exercise, TemplateExercise } from '@/types/workout'
import type { SetLog } from '@/types/workout'
import {
  formatDurationSecondsDisplay,
  parseSetDurationSeconds,
} from '@/types/workout'
import type { WeightUnit } from '@/utils/units'
import { formatWeightWithUnit, parseStoredLbs } from '@/utils/units'

type CircuitGoalExercise = Pick<
  Exercise | TemplateExercise,
  'sets' | 'targetReps' | 'targetWeight' | 'isCircuit'
>

/** Resolved reps/weight for a circuit check-off row (set fields, then exercise goals). */
export function circuitSetTargets(
  set: Pick<SetLog, 'reps' | 'weight'>,
  ex: CircuitGoalExercise,
): { reps: string; weightRaw: string } {
  return {
    reps: (set.reps ?? '').trim() || (ex.targetReps ?? '').trim() || 'AMRAP',
    weightRaw: (set.weight ?? '').trim() || (ex.targetWeight ?? '').trim(),
  }
}

/** One circuit set line, e.g. "15 reps @ 85 lb", "45 sec", or "1 min @ 35 lb". */
export function formatCircuitSetLine(
  set: Pick<SetLog, 'reps' | 'weight' | 'durationSeconds'>,
  ex: CircuitGoalExercise,
  weightUnit: WeightUnit,
): string {
  const { reps, weightRaw } = circuitSetTargets(set, ex)
  const durationSec = parseSetDurationSeconds(set)

  let effortPart: string
  if (durationSec != null) {
    effortPart = formatDurationSecondsDisplay(durationSec)
  } else if (/\d+\s*sec|\d+\s*min/i.test(reps)) {
    effortPart = reps
  } else {
    effortPart = `${reps} reps`
  }

  if (!weightRaw) return effortPart
  const lbs = parseStoredLbs(weightRaw)
  if (Number.isNaN(lbs) || lbs <= 0) return effortPart
  return `${effortPart} @ ${formatWeightWithUnit(lbs, weightUnit, 1)}`
}

/** Compact goal for home / plan previews; matches circuit check-off targets. */
export function formatCircuitExerciseGoal(
  ex: CircuitGoalExercise,
  weightUnit: WeightUnit,
): string {
  const n = ex.sets.length
  const reps = (ex.targetReps ?? '').trim()
  const weightRaw = (ex.targetWeight ?? '').trim()
  if (!reps && !weightRaw) {
    return `${n} set${n !== 1 ? 's' : ''}`
  }
  const mid = reps ? `${n} × ${reps}` : `${n} sets`
  if (!weightRaw) return mid
  const lbs = parseStoredLbs(weightRaw)
  if (Number.isNaN(lbs) || lbs <= 0) return mid
  return `${mid} @ ${formatWeightWithUnit(lbs, weightUnit, 1)}`
}
