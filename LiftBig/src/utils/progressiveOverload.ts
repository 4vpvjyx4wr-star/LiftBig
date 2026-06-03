import { getDayExercises, setCountsTowardProgress, type Exercise, type WorkoutLog } from '@/types/workout'
import { collectExerciseHistory } from '@/utils/exerciseProgress'
import type { WeightUnit } from '@/utils/units'
import { formatDeltaFromLbs, parseStoredLbs } from '@/utils/units'

type SetLogLike = { reps: string; weight: string; isWarmup?: boolean }

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
  suggestedReps: string
  suggestedWeightLbs: number
  reason: string
  hasHistory: boolean
}

function exerciseNameMatches(a: string, b: string): boolean {
  return a.trim().toLowerCase() === b.trim().toLowerCase()
}

function roundWeightToIncrement(lbs: number, increment: number): number {
  const step = increment >= 5 ? increment : 2.5
  return Math.round(lbs / step) * step
}

function linearSlope(ys: number[]): number {
  const n = ys.length
  if (n < 2) return 0
  const xs = ys.map((_, i) => i)
  let sumX = 0
  let sumY = 0
  let sumXY = 0
  let sumXX = 0
  for (let i = 0; i < n; i++) {
    sumX += xs[i]!
    sumY += ys[i]!
    sumXY += xs[i]! * ys[i]!
    sumXX += xs[i]! * xs[i]!
  }
  const denom = n * sumXX - sumX * sumX
  if (denom === 0) return 0
  return (n * sumXY - sumX * sumY) / denom
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

type SetPerformance = {
  dateKey: string
  weightLbs: number
  reps: number
  e1rm: number
  sessionTargetReps?: string
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

function collectSetPerformances(
  allWorkouts: WorkoutLog,
  exerciseName: string,
  excludeDateKey?: string,
): SetPerformance[] {
  const out: SetPerformance[] = []
  for (const [dateKey, dayEntry] of Object.entries(allWorkouts)) {
    if (excludeDateKey && dateKey === excludeDateKey) continue
    const ex = getDayExercises(dayEntry).find((e) => exerciseNameMatches(e.name, exerciseName))
    if (!ex) continue
    const sessionTargetReps = (ex.targetReps ?? '').trim() || undefined
    for (const s of ex.sets) {
      if (!setCountsTowardProgress(s)) continue
      const weightLbs = parseStoredLbs(s.weight)
      const reps = parseInt(s.reps, 10)
      if (Number.isNaN(weightLbs) || weightLbs <= 0 || Number.isNaN(reps) || reps <= 0) continue
      out.push({
        dateKey,
        weightLbs,
        reps,
        e1rm: estimateE1RMLbs(weightLbs, reps),
        sessionTargetReps,
      })
    }
  }
  return out
}

function sessionBestE1RMs(performances: SetPerformance[]): { dateKey: string; bestE1rm: number }[] {
  const byDate = new Map<string, number>()
  for (const p of performances) {
    byDate.set(p.dateKey, Math.max(byDate.get(p.dateKey) ?? 0, p.e1rm))
  }
  return [...byDate.entries()]
    .map(([dateKey, bestE1rm]) => ({ dateKey, bestE1rm }))
    .sort((a, b) => a.dateKey.localeCompare(b.dateKey))
}

function lastSessionSets(
  allWorkouts: WorkoutLog,
  exerciseName: string,
  excludeDateKey?: string,
): { sets: SetLogLike[]; sessionTargetReps?: string } {
  const sessions: { date: string; sets: SetLogLike[]; sessionTargetReps?: string }[] = []
  for (const [date, dayEntry] of Object.entries(allWorkouts)) {
    if (excludeDateKey && date === excludeDateKey) continue
    const ex = getDayExercises(dayEntry).find((e) => exerciseNameMatches(e.name, exerciseName))
    if (!ex) continue
    const completed = ex.sets.filter(
      (s) => setCountsTowardProgress(s) && s.reps.trim() !== '' && s.weight.trim() !== '',
    )
    if (completed.length > 0) {
      sessions.push({
        date,
        sets: completed,
        sessionTargetReps: (ex.targetReps ?? '').trim() || undefined,
      })
    }
  }
  sessions.sort((a, b) => b.date.localeCompare(a.date))
  const last = sessions[0]
  return last ? { sets: last.sets, sessionTargetReps: last.sessionTargetReps } : { sets: [] }
}

/**
 * Predicts attainable rep and weight goals from the user's full exercise history in local storage,
 * blending long-term trend with recent performance and progressive-overload rules.
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
  const displayUnit = options.displayUnit ?? 'lb'
  const currentReps = (options.currentTargetReps ?? '').trim()
  const currentWeight = options.ignoreStoredGoalWeight
    ? 0
    : (options.currentTargetWeightLbs ?? 0)
  const increment = getWeightIncrementLbs(exerciseName)

  const performances = collectSetPerformances(
    allWorkouts,
    exerciseName,
    options.excludeDateKey,
  )

  let history = collectExerciseHistory(allWorkouts, exerciseName)
  if (options.excludeDateKey) {
    history = history.filter((h) => h.dateKey !== options.excludeDateKey)
  }

  if (history.length === 0 && performances.length === 0) {
    return {
      suggestedReps: currentReps || '8-12',
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
      inferRepGoalFromHistory(history.map((h) => h.maxReps))

  const targetRepsForWeight = repCountForWeightGoal(repGoal)
  const { max: repMax, min: repMin } = parseRepRange(repGoal)

  let baseWeight = 0
  let repScaledFromHistory = false

  if (performances.length > 0) {
    const sessionE1rms = sessionBestE1RMs(performances)
    const e1rmValues = sessionE1rms.map((s) => s.bestE1rm)
    const lastSessionE1rm = e1rmValues[e1rmValues.length - 1] ?? 0
    const recentSlice = e1rmValues.slice(-Math.min(3, e1rmValues.length))
    const recentE1rmAvg = recentSlice.reduce((a, b) => a + b, 0) / recentSlice.length
    const e1rmSlope = linearSlope(e1rmValues)
    const e1rmStep = Math.min(Math.max(e1rmSlope, 0), increment)
    const trendE1rm = lastSessionE1rm + e1rmStep
    const blendedE1rm = 0.55 * trendE1rm + 0.45 * recentE1rmAvg
    baseWeight = weightForTargetRepsLbs(blendedE1rm, targetRepsForWeight)

    const lastPerf = performances
      .filter((p) => p.dateKey === sessionE1rms[sessionE1rms.length - 1]?.dateKey)
      .sort((a, b) => b.e1rm - a.e1rm)[0]
    if (lastPerf && lastPerf.reps < targetRepsForWeight - 2) {
      repScaledFromHistory = true
    }
  } else if (history.length > 0) {
    const last = history[history.length - 1]!
    baseWeight = weightForTargetRepsLbs(
      estimateE1RMLbs(last.maxWeightLbs, Math.max(1, last.maxReps)),
      targetRepsForWeight,
    )
    if (last.maxReps > 0 && last.maxReps < targetRepsForWeight - 2) {
      repScaledFromHistory = true
    }
  }

  const lastSession = lastSessionSets(allWorkouts, exerciseName, options.excludeDateKey)
  const lastSets = lastSession.sets
  const lastSessionRepGoal = lastSession.sessionTargetReps || repGoal
  const lastRepMax = parseRepRange(lastSessionRepGoal).max

  if (lastSets.length > 0) {
    const lastSetE1rms = lastSets.map((s) => {
      const w = parseStoredLbs(s.weight) || parseFloat(s.weight)
      const r = parseInt(s.reps, 10)
      return estimateE1RMLbs(w, Number.isNaN(r) ? 1 : r)
    })
    const lastBestE1rm = Math.max(...lastSetE1rms)
    const weightAtNewGoal = weightForTargetRepsLbs(lastBestE1rm, targetRepsForWeight)

    const allHitMax = lastSets.every((s) => {
      if (isAMRAP(lastSessionRepGoal)) return true
      return parseInt(s.reps, 10) >= lastRepMax
    })
    const anyFailed = lastSets.some((s) => parseInt(s.reps, 10) < parseRepRange(lastSessionRepGoal).min)

    if (allHitMax) {
      const bumpedE1rm = lastBestE1rm + increment
      baseWeight = Math.max(baseWeight, weightForTargetRepsLbs(bumpedE1rm, targetRepsForWeight))
    } else if (anyFailed) {
      baseWeight = Math.min(baseWeight, weightAtNewGoal)
    } else {
      baseWeight = (baseWeight + weightAtNewGoal) / 2
    }
  } else if (!options.ignoreStoredGoalWeight && currentWeight > 0 && baseWeight <= 0) {
    baseWeight = weightForTargetRepsLbs(
      estimateE1RMLbs(currentWeight, repCountForWeightGoal(currentReps || repGoal)),
      targetRepsForWeight,
    )
  }

  const suggestedWeightLbs = roundWeightToIncrement(
    Math.max(baseWeight, increment > 0 ? increment : 2.5),
    increment,
  )

  const sessionCount = Math.max(
    history.length,
    sessionBestE1RMs(performances).length,
  )
  let reason: string
  if (repScaledFromHistory && repGoal) {
    reason = `Adjusted for ${repGoal} reps — weight scaled from your history at different rep ranges`
  } else if (sessionCount >= 4) {
    reason = `Based on ${sessionCount} sessions — strength estimated across all logged sets`
  } else if (sessionCount >= 2) {
    reason = `Based on ${sessionCount} past sessions — tailored to your rep goal`
  } else {
    reason = 'Based on your last session — log more workouts to refine predictions'
  }

  return {
    suggestedReps: repGoal,
    suggestedWeightLbs,
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
    })
    if (!pred.hasHistory) continue

    if (!hasRepGoal) {
      ex.targetReps = pred.suggestedReps
    }
    ex.targetWeight = String(pred.suggestedWeightLbs)
  }
}
