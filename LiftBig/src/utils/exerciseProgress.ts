import { getDayExercises, setCountsTowardProgress, type SetLog, type WorkoutLog } from '@/types/workout'
import type { LibraryExercise } from '@/utils/exerciseLibrary'
import { addDaysToDateKey, todayKey } from '@/utils/dateKey'
import { exerciseMatchesLibrary } from '@/utils/libraryExerciseTracking'
import { getWeightIncrementLbs } from '@/utils/progressiveOverload'
import { parseStoredLbs } from '@/utils/units'

export type SessionPoint = {
  dateKey: string
  timeMs: number
  maxWeightLbs: number
  avgReps: number
  maxReps: number
  volume: number
  setCount: number
}

export type FuturePoint = {
  timeMs: number
  projectedMaxWeightLbs: number
}

const FUTURE_SESSIONS = 10

function exerciseNameMatches(a: string, b: string): boolean {
  return a.trim().toLowerCase() === b.trim().toLowerCase()
}

function dateKeyToTimeMs(dateKey: string): number {
  const t = new Date(`${dateKey}T12:00:00`).getTime()
  return Number.isNaN(t) ? 0 : t
}

function medianDiffs(timeMs: number[]): number {
  if (timeMs.length < 2) return 7 * 86_400_000
  const gaps: number[] = []
  for (let i = 1; i < timeMs.length; i++) {
    gaps.push(timeMs[i]! - timeMs[i - 1]!)
  }
  gaps.sort((x, y) => x - y)
  const mid = Math.floor(gaps.length / 2)
  return gaps.length % 2 === 1 ? gaps[mid]! : (gaps[mid - 1]! + gaps[mid]!) / 2
}

function linearRegression(
  xs: number[],
  ys: number[],
): { a: number; b: number } {
  const n = xs.length
  if (n === 0) return { a: 0, b: 0 }
  if (n === 1) return { a: ys[0]!, b: 0 }
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
  if (denom === 0) return { a: sumY / n, b: 0 }
  const b = (n * sumXY - sumX * sumY) / denom
  const a = (sumY - b * sumX) / n
  return { a, b }
}

export function listExerciseNamesFromLog(log: WorkoutLog): string[] {
  const names = new Set<string>()
  for (const dayEntry of Object.values(log)) {
    const exercises = getDayExercises(dayEntry)
    for (const ex of exercises) {
      const n = ex.name.trim()
      if (n) names.add(n)
    }
  }
  return [...names].sort((a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' }))
}

export function collectExerciseHistory(log: WorkoutLog, exerciseName: string): SessionPoint[] {
  const out: SessionPoint[] = []
  for (const [dateKey, dayEntry] of Object.entries(log)) {
    const exercises = getDayExercises(dayEntry)
    const ex = exercises.find((e) => exerciseNameMatches(e.name, exerciseName))
    if (!ex) continue
    const sets = ex.sets.filter(
      (s) => setCountsTowardProgress(s) && s.reps.trim() !== '' && s.weight.trim() !== '',
    )
    if (sets.length === 0) continue

    let maxW = 0
    let sumR = 0
    let maxR = 0
    let vol = 0
    let counted = 0
    for (const s of sets) {
      const w = parseStoredLbs(s.weight)
      const r = parseInt(s.reps, 10)
      if (Number.isNaN(w) || w <= 0) continue
      counted++
      const reps = Number.isNaN(r) ? 0 : Math.max(0, r)
      maxW = Math.max(maxW, w)
      sumR += reps
      maxR = Math.max(maxR, reps)
      vol += w * reps
    }
    if (maxW <= 0 || counted === 0) continue

    out.push({
      dateKey,
      timeMs: dateKeyToTimeMs(dateKey),
      maxWeightLbs: maxW,
      avgReps: sumR / counted,
      maxReps: maxR,
      volume: vol,
      setCount: counted,
    })
  }
  out.sort((a, b) => a.dateKey.localeCompare(b.dateKey))
  return out
}

function sessionPointFromExercise(dateKey: string, ex: { sets: SetLog[] }): SessionPoint | null {
  const sets = ex.sets.filter(
    (s) => setCountsTowardProgress(s) && s.reps.trim() !== '' && s.weight.trim() !== '',
  )
  if (sets.length === 0) return null

  let maxW = 0
  let sumR = 0
  let maxR = 0
  let vol = 0
  let counted = 0
  for (const s of sets) {
    const w = parseStoredLbs(s.weight)
    const r = parseInt(s.reps, 10)
    if (Number.isNaN(w) || w <= 0) continue
    counted++
    const reps = Number.isNaN(r) ? 0 : Math.max(0, r)
    maxW = Math.max(maxW, w)
    sumR += reps
    maxR = Math.max(maxR, reps)
    vol += w * reps
  }
  if (maxW <= 0 || counted === 0) return null

  return {
    dateKey,
    timeMs: dateKeyToTimeMs(dateKey),
    maxWeightLbs: maxW,
    avgReps: sumR / counted,
    maxReps: maxR,
    volume: vol,
    setCount: counted,
  }
}

export function collectLibraryExerciseHistory(
  log: WorkoutLog,
  libraryExercise: LibraryExercise,
): SessionPoint[] {
  if (libraryExercise.isCardio) return []
  const out: SessionPoint[] = []
  for (const [dateKey, dayEntry] of Object.entries(log)) {
    const exercises = getDayExercises(dayEntry)
    const ex = exercises.find((e) => exerciseMatchesLibrary(e, libraryExercise))
    if (!ex || ex.isCardio) continue
    const point = sessionPointFromExercise(dateKey, ex)
    if (point) out.push(point)
  }
  out.sort((a, b) => a.dateKey.localeCompare(b.dateKey))
  return out
}

export type StrengthListStats = {
  sessions: number
  /** Average session max weight over the last 14 calendar days (inclusive). */
  avg14DayMaxLbs: number | null
  maxLbs: number | null
}

export function strengthListStats(
  history: SessionPoint[],
  referenceDateKey: string = todayKey(),
): StrengthListStats {
  if (history.length === 0) {
    return { sessions: 0, avg14DayMaxLbs: null, maxLbs: null }
  }
  const cutoff = addDaysToDateKey(referenceDateKey, -13)
  const recent = history.filter((h) => h.dateKey >= cutoff)
  const avg14DayMaxLbs =
    recent.length > 0
      ? recent.reduce((sum, h) => sum + h.maxWeightLbs, 0) / recent.length
      : null
  const maxLbs = Math.max(...history.map((h) => h.maxWeightLbs))
  return { sessions: history.length, avg14DayMaxLbs, maxLbs }
}

/**
 * Projects future max weight using linear trend on session index, capped per session by the same
 * increment ladder used elsewhere for progressive overload (so gains stay realistic).
 */
export function projectFutureStrength(
  history: SessionPoint[],
  exerciseName: string,
): FuturePoint[] {
  if (history.length === 0) return []

  const incrementCap = getWeightIncrementLbs(exerciseName)
  const n = history.length
  const xs = history.map((_, i) => i)
  const ys = history.map((h) => h.maxWeightLbs)
  const { b } = linearRegression(xs, ys)
  const perSessionStep = Math.min(Math.max(b, 0), incrementCap)

  const times = history.map((h) => h.timeMs)
  const gapMs = medianDiffs(times)
  const last = history[n - 1]!

  const out: FuturePoint[] = []
  let prev = last.maxWeightLbs
  for (let k = 0; k < FUTURE_SESSIONS; k++) {
    prev += perSessionStep
    out.push({
      timeMs: last.timeMs + gapMs * (k + 1),
      projectedMaxWeightLbs: prev,
    })
  }
  return out
}
