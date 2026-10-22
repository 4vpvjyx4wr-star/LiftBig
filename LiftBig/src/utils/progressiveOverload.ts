import { getDayExercises, setCountsTowardProgress, type Exercise, type WorkoutLog } from '@/types/workout'
import type { WeightUnit } from '@/utils/units'
import { parseStoredLbs } from '@/utils/units'

const INCREMENT_MAP: Record<string, number> = {
  'leg press': 10,
  squat: 5,
  rdl: 5,
  'leg extension': 5,
  'hamstring curl': 5,
  'seated hamstring curl': 5,
  'calf raises': 10,
  'walking lunges': 5,
  'incline db press': 5,
  'flat db press': 5,
  'incline machine press': 5,
  'pull ups': 5,
  'lat pulldown': 5,
  'single arm lat pulldown': 2.5,
  'row variation': 5,
  'seated/bentover row': 5,
  'bentover row': 5,
  'chest supported row': 5,
  'cable curl': 2.5,
  'incline cable curl': 2.5,
  'incline db curl': 2.5,
  'incline dumbbell curl': 2.5,
  'tricep pushdown': 2.5,
  'rope pushdown': 2.5,
  'overhead tricep extension': 2.5,
  'overhead cable tricep': 2.5,
  'face pulls': 2.5,
  'cable lateral raise': 2.5,
  'lateral raises': 2.5,
  'db lateral raise': 2.5,
  'lateral raise dropset': 2.5,
  'rear delt fly': 2.5,
  'machine flyes': 2.5,
  'cable flyes': 2.5,
  'cable woodchops': 2.5,
  'cable woodchop': 2.5,
  'cable crunches': 2.5,
  'ab machine': 5,
  'weighted reverse crunches': 2.5,
  'decline reverse crunch': 2.5,
}

/** Typical single-sided jump (lb) when progressing this lift (progressive overload). */
export function getWeightIncrementLbs(exerciseName: string): number {
  const lower = exerciseName.toLowerCase()
  for (const key of Object.keys(INCREMENT_MAP)) {
    if (lower.includes(key)) return INCREMENT_MAP[key]!
  }
  return 2.5
}

function isAMRAP(repGoal: string): boolean {
  return repGoal.toLowerCase().includes('amrap')
}

export function parseRepRange(repGoal: string): { min: number; max: number } {
  if (isAMRAP(repGoal)) return { min: 1, max: 9999 }
  const match = repGoal.match(/(\d+)\s*[-–]\s*(\d+)/)
  if (match) return { min: parseInt(match[1]!, 10), max: parseInt(match[2]!, 10) }
  const single = parseInt(repGoal, 10)
  if (!isNaN(single)) return { min: single, max: single }
  return { min: 0, max: 9999 }
}

/** Rep count to prefill for set logging: top of programmed range; empty for AMRAP or invalid. */
export function getDefaultLogRepsForTarget(targetReps: string): string {
  const t = targetReps.trim()
  if (!t) return ''
  if (isAMRAP(t)) return ''
  const { max } = parseRepRange(t)
  if (max <= 0 || max >= 9999) return ''
  return String(max)
}

const REP_PICKER_MAX = 50

/** Rep quick-pick list: 50 down to 1. */
export const REP_QUICK_PICK_DESCENDING: readonly string[] = Array.from(
  { length: REP_PICKER_MAX },
  (_, i) => String(REP_PICKER_MAX - i),
)

/**
 * Programmed rep-range ceiling for scrolling the picker (1–50), or null when there is no finite target
 * (no goal, AMRAP, unparsable).
 */
export function finiteGoalRepMaxForScroll(targetReps: string | undefined): number | null {
  const g = (targetReps ?? '').trim()
  if (!g) return null
  const { max } = parseRepRange(g)
  if (max <= 0 || max >= 9999) return null
  return Math.min(REP_PICKER_MAX, max)
}

export type PredictedGoals = {
  /** Programmed range, such as `8-12`. */
  suggestedReps: string
  /** Reps to log next. Empty when there is no history. */
  suggestedLogReps: string
  suggestedWeightLbs: number
  reason: string
  hasHistory: boolean
}

function exerciseNameMatches(a: string, b: string): boolean {
  return a.trim().toLowerCase() === b.trim().toLowerCase()
}

function collectHistoricalRepGoals(allWorkouts: WorkoutLog, exerciseName: string): string[] {
  const goals: string[] = []
  for (const dayEntry of Object.values(allWorkouts)) {
    const ex = getDayExercises(dayEntry).find((e) => exerciseNameMatches(e.name, exerciseName))
    const g = (ex?.targetReps ?? '').trim()
    if (g) goals.push(g)
  }
  return goals
}

function mostCommonRepGoal(goals: string[]): string | undefined {
  if (goals.length === 0) return undefined
  const counts = new Map<string, number>()
  for (const g of goals) {
    counts.set(g, (counts.get(g) ?? 0) + 1)
  }
  let best = goals[0]!
  let bestN = 0
  for (const [g, n] of counts) {
    if (n > bestN) {
      bestN = n
      best = g
    }
  }
  return best
}

/** Suggest a rep range from logged max reps across sessions (median-based). */
export function inferRepGoalFromHistory(maxRepsPerSession: number[]): string {
  const vals = maxRepsPerSession.filter((r) => r > 0)
  if (vals.length === 0) return '8-12'
  const sorted = [...vals].sort((a, b) => a - b)
  const median = sorted[Math.floor(sorted.length / 2)]!
  if (median <= 5) return '3-5'
  if (median <= 8) return '6-8'
  if (median <= 12) return '8-12'
  if (median <= 15) return '10-15'
  return '12-15'
}

/** Epley estimated 1-rep max from a weight × reps set. */
export function estimateE1RMLbs(weightLbs: number, reps: number): number {
  if (weightLbs <= 0) return 0
  if (reps <= 1) return weightLbs
  return weightLbs * (1 + reps / 30)
}

/** Working weight attainable for a given rep count from estimated 1RM (Epley inverse). */
export function weightForTargetRepsLbs(e1rmLbs: number, targetReps: number): number {
  if (e1rmLbs <= 0) return 0
  if (targetReps <= 1) return e1rmLbs
  return e1rmLbs / (1 + targetReps / 30)
}

/** Rep count used for weight prediction — top of programmed range (most attainable). */
export function repCountForWeightGoal(repGoal: string): number {
  const { min, max } = parseRepRange(repGoal)
  if (max >= 9999) return min > 0 ? min : 10
  return max
}

const LB_PER_KG = 2.2046226218

type WorkSession = {
  dateKey: string
  achievedReps: number
  peakReps: number
  weightLbs: number
  difficulty: 'Easy' | 'Moderate' | 'Difficult' | null
}

function canonicalDifficulty(raw: string | undefined): 'Easy' | 'Moderate' | 'Difficult' | null {
  const text = (raw ?? '').trim().toLowerCase()
  if (text === 'easy') return 'Easy'
  if (text === 'moderate' || text === 'mod') return 'Moderate'
  if (text === 'difficult' || text === 'hard') return 'Difficult'
  return null
}

/** One Difficult set does not define the session when another rating is logged. */
function sessionDifficulty(
  sets: { difficulty?: string }[],
): 'Easy' | 'Moderate' | 'Difficult' | null {
  let easy = 0
  let moderate = 0
  let difficult = 0
  for (const set of sets) {
    const rating = canonicalDifficulty(set.difficulty)
    if (rating === 'Easy') easy += 1
    if (rating === 'Moderate') moderate += 1
    if (rating === 'Difficult') difficult += 1
  }
  const rated = easy + moderate + difficult
  if (rated === 0) return null
  if (difficult === 1 && rated > 1) difficult = 0
  if (difficult > easy && difficult > moderate) return 'Difficult'
  if (easy > difficult && easy > moderate) return 'Easy'
  if (moderate > easy && moderate > difficult) return 'Moderate'
  if (easy === 0 && moderate === 0 && difficult === 0) return null
  return 'Moderate'
}

/** Warmups never move the next target, even when they carry a rating. */
function workingSessions(
  allWorkouts: WorkoutLog,
  exerciseName: string,
  excludeDateKey?: string,
): WorkSession[] {
  const out: WorkSession[] = []
  const dates = Object.keys(allWorkouts).sort()
  for (const dateKey of dates) {
    if (excludeDateKey && dateKey === excludeDateKey) continue
    const ex = getDayExercises(allWorkouts[dateKey]).find((e) => exerciseNameMatches(e.name, exerciseName))
    if (!ex) continue
    const weights: number[] = []
    const reps: number[] = []
    const rated: { difficulty?: string }[] = []
    for (const set of ex.sets) {
      if (!setCountsTowardProgress(set)) continue
      const weight = parseStoredLbs(set.weight)
      const count = parseInt(set.reps, 10)
      if (Number.isNaN(weight) || weight <= 0 || Number.isNaN(count) || count <= 0) continue
      weights.push(weight)
      reps.push(count)
      rated.push(set)
    }
    if (reps.length === 0) continue
    out.push({
      dateKey,
      achievedReps: Math.min(...reps),
      peakReps: Math.max(...reps),
      weightLbs: modeWeight(weights),
      difficulty: sessionDifficulty(rated),
    })
  }
  return out
}

function modeWeight(weights: number[]): number {
  const counts = new Map<number, number>()
  let bestKey = 0
  let bestCount = 0
  let bestWeight = 0
  for (const weight of weights) {
    const key = Math.round(weight * 1000)
    const count = (counts.get(key) ?? 0) + 1
    counts.set(key, count)
    if (count > bestCount || (count === bestCount && weight > bestWeight)) {
      bestCount = count
      bestKey = key
      bestWeight = weight
    }
  }
  return bestKey / 1000
}

function progressionStepLbs(exerciseName: string, unit: WeightUnit): number {
  const pounds = getWeightIncrementLbs(exerciseName)
  if (unit !== 'kg') return pounds
  if (pounds >= 10) return 5 * LB_PER_KG
  if (pounds >= 5) return 2.5 * LB_PER_KG
  return LB_PER_KG
}

function quantize(value: number, step: number): number {
  if (step <= 0) return value
  return Math.round((Math.round(value / step) * step) * 1000) / 1000
}

function stepUp(weightLbs: number, stepLbs: number, unit: WeightUnit): number {
  if (unit !== 'kg') {
    let next = quantize(weightLbs + stepLbs, stepLbs)
    if (next <= weightLbs + 0.05) next = quantize(weightLbs + stepLbs * 2, stepLbs)
    return next
  }
  const stepKg = stepLbs / LB_PER_KG
  const kg = weightLbs / LB_PER_KG
  const aligned = Math.round(kg / stepKg) * stepKg
  let nextKg = aligned + stepKg
  if (nextKg * LB_PER_KG <= weightLbs + 0.05) nextKg += stepKg
  return quantize(nextKg * LB_PER_KG, 0.001)
}

function stepDown(weightLbs: number, stepLbs: number, unit: WeightUnit): number {
  if (unit !== 'kg') {
    let next = quantize(weightLbs - stepLbs, stepLbs)
    if (next >= weightLbs - 0.05) next = weightLbs - stepLbs
    if (next <= 0) return weightLbs
    return Math.round(next * 1000) / 1000
  }
  const stepKg = stepLbs / LB_PER_KG
  const kg = weightLbs / LB_PER_KG
  const aligned = Math.round(kg / stepKg) * stepKg
  let nextKg = aligned - stepKg
  if (nextKg * LB_PER_KG >= weightLbs - 0.05) nextKg = kg - stepKg
  if (nextKg <= 0) return weightLbs
  return Math.round(nextKg * LB_PER_KG * 1000) / 1000
}

function stepLabel(stepLbs: number, unit: WeightUnit): string {
  if (unit === 'kg') {
    const kg = Math.round((stepLbs / LB_PER_KG) * 10) / 10
    return `${kg} kg`
  }
  return `${formatLbs(stepLbs)} lb`
}

function weightLabel(lbs: number, unit: WeightUnit): string {
  if (unit === 'kg') {
    const kg = Math.round((lbs / LB_PER_KG) * 10) / 10
    return `${kg} kg`
  }
  return `${formatLbs(lbs)} lb`
}

function formatLbs(lbs: number): string {
  const scaled = Math.round(lbs * 1000) / 1000
  if (scaled === Math.round(scaled)) return String(Math.round(scaled))
  return String(scaled)
}

function capReps(value: number, finite: boolean, max: number): number {
  if (value < 1) return 1
  if (finite && value > max) return max
  return value
}

/**
 * Next session from the last working sets.
 * Double progression inside the range. Easy climbs reps faster.
 * Difficult holds, or takes one small step back.
 */
export function predictWorkoutGoals(
  exerciseName: string,
  allWorkouts: WorkoutLog,
  options: {
    currentTargetReps?: string
    currentTargetWeightLbs?: number
    excludeDateKey?: string
    displayUnit?: WeightUnit
    /** When true, rep goal stays on currentTargetReps (e.g. copied workout structure). */
    lockRepGoal?: boolean
    /** When true, never use stored/copied goal weight — only history-derived weight. */
    ignoreStoredGoalWeight?: boolean
  } = {},
): PredictedGoals {
  const currentReps = (options.currentTargetReps ?? '').trim()
  const currentWeight = options.ignoreStoredGoalWeight
    ? 0
    : (options.currentTargetWeightLbs ?? 0)
  const unit: WeightUnit = options.displayUnit === 'kg' ? 'kg' : 'lb'
  const sessions = workingSessions(allWorkouts, exerciseName, options.excludeDateKey)

  // No history: do not invent a starting weight.
  if (sessions.length === 0) {
    return {
      suggestedReps: currentReps || '8-12',
      suggestedLogReps: '',
      suggestedWeightLbs: currentWeight,
      reason: 'No history yet',
      hasHistory: false,
    }
  }

  const historicalRepGoals = collectHistoricalRepGoals(allWorkouts, exerciseName)
  const repGoal = options.lockRepGoal && currentReps
    ? currentReps
    : currentReps ||
      mostCommonRepGoal(historicalRepGoals) ||
      inferRepGoalFromHistory(sessions.map((session) => session.peakReps))
  const range = parseRepRange(repGoal)
  const finite = range.max > 0 && range.max < 9999
  const minReps = range.min > 0 ? range.min : 1
  const last = sessions[sessions.length - 1]!
  const achieved = last.achievedReps
  const atTop = finite && achieved >= range.max
  const short = finite && achieved < minReps
  const step = progressionStepLbs(exerciseName, unit)
  const label = stepLabel(step, unit)
  const rating = last.difficulty
  const streak =
    rating === 'Difficult' &&
    sessions.slice(-3).filter((session) => session.difficulty === 'Difficult').length >= 2

  let weight = last.weightLbs
  let reps = achieved
  let reason: string

  if (rating === 'Difficult' && streak) {
    const nextWeight = stepDown(weight, step, unit)
    const dropped = nextWeight < weight - 0.05
    reps = capReps(short ? achieved : minReps, finite, range.max)
    if (dropped) weight = nextWeight
    reason = dropped
      ? `Several Difficult sessions. Drop ${label} and rebuild at ${reps} reps.`
      : `Several Difficult sessions. Hold ${weightLabel(weight, unit)} and aim for ${reps} reps.`
  } else if (rating === 'Difficult' && short) {
    const nextWeight = stepDown(weight, step, unit)
    const dropped = nextWeight < weight - 0.05
    reps = capReps(achieved, finite, range.max)
    if (dropped) weight = nextWeight
    reason = dropped
      ? `Rated Difficult and short of the range. Drop ${label} and rebuild at ${reps} reps.`
      : `Rated Difficult and short of the range. Hold ${weightLabel(weight, unit)} and aim for ${reps} reps.`
  } else if (rating === 'Difficult') {
    reps = capReps(achieved, finite, range.max)
    reason = `Rated Difficult. Hold ${weightLabel(weight, unit)} and aim for ${reps} reps.`
  } else if (rating === 'Easy' && atTop) {
    weight = stepUp(weight, step, unit)
    reps = capReps(minReps, finite, range.max)
    reason = `Rated Easy at the top of the range. Add ${label} and start back at ${reps} reps.`
  } else if (rating === 'Easy') {
    reps = capReps(achieved + 2, finite, range.max)
    reason = `Rated Easy. Same weight, move up to ${reps} reps.`
  } else if (atTop) {
    weight = stepUp(weight, step, unit)
    reps = capReps(minReps, finite, range.max)
    reason =
      rating === 'Moderate'
        ? `Rated Moderate and at the top of the range. Add ${label} and start back at ${reps} reps.`
        : `Working sets hit the top of the range. Add ${label} and start back at ${reps} reps.`
  } else if (short) {
    reps = capReps(achieved, finite, range.max)
    reason =
      rating === 'Moderate'
        ? `Rated Moderate and short of the range. Hold ${weightLabel(weight, unit)} and aim for ${reps} reps.`
        : `Short of the rep range. Hold ${weightLabel(weight, unit)} and aim for ${reps} reps.`
  } else {
    reps = capReps(achieved + 1, finite, range.max)
    reason =
      rating === 'Moderate'
        ? `Rated Moderate. Same weight, aim for ${reps} reps.`
        : `Same weight, aim for ${reps} reps. Add reps before adding weight.`
  }

  return {
    suggestedReps: repGoal,
    suggestedLogReps: String(reps),
    suggestedWeightLbs: weight,
    reason,
    hasHistory: true,
  }
}

/** @deprecated Prefer predictWorkoutGoals — kept for callers that only need weight. */
export function getSuggestedWeight(
  exerciseName: string,
  targetRepGoal: string,
  currentGoalWeight: number,
  allWorkouts: WorkoutLog,
  displayUnit: WeightUnit = 'lb',
): { suggestedWeight: number; reason: string } {
  const pred = predictWorkoutGoals(exerciseName, allWorkouts, {
    currentTargetReps: targetRepGoal,
    currentTargetWeightLbs: currentGoalWeight,
    displayUnit,
  })
  return {
    suggestedWeight: pred.suggestedWeightLbs,
    reason: pred.reason,
  }
}

/** Apply history-based goals to exercises that have not been logged yet this session. */
export function applyPredictedGoalsToExercises(
  exercises: Exercise[],
  allWorkouts: WorkoutLog,
  dateKey: string,
  options: {
    /** Refresh from full history (e.g. after copy); keeps rep goals, replaces weight. */
    refreshFromHistory?: boolean
    displayUnit?: WeightUnit
  } = {},
): void {
  for (const ex of exercises) {
    if (ex.isCircuit || ex.isCardio) continue
    const allEmpty = ex.sets.every((s) => !s.reps.trim() && !s.weight.trim())
    if (!allEmpty && !options.refreshFromHistory) continue

    const hasRepGoal = !!(ex.targetReps ?? '').trim()
    const pred = predictWorkoutGoals(ex.name, allWorkouts, {
      currentTargetReps: ex.targetReps,
      excludeDateKey: dateKey,
      lockRepGoal: hasRepGoal,
      ignoreStoredGoalWeight: true,
      displayUnit: options.displayUnit,
    })
    if (!pred.hasHistory) continue

    if (!hasRepGoal) {
      ex.targetReps = pred.suggestedReps
    }
    ex.targetWeight = String(pred.suggestedWeightLbs)
  }
}
