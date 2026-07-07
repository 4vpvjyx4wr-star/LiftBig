import {
  cardioLoggedDurationMinutes,
  coreSetLogged,
  exerciseIsCardio,
  getDayExercises,
  isRestDayEntry,
  parseSetDurationSeconds,
  setCountsTowardProgress,
  type Exercise,
  type SetLog,
  type WorkoutLog,
} from '@/types/workout'
import { addDaysToDateKey, parseDateKey, todayKey, toDateKey } from '@/utils/dateKey'
import {
  getLibraryExercise,
  MUSCLE_GROUP_LABELS,
  type MuscleGroup,
} from '@/utils/exerciseLibrary'
import type { PlanDurationAssumptions } from '@/utils/planDuration'
import { parseStoredLbs } from '@/utils/units'
import { estimateWorkoutCalories } from '@/utils/workoutCalories'
import {
  computeWeeklyVolume,
  formatWeekLabel,
  getPreviousWeekRange,
  getWeekRangeForDate,
  type WeekRange,
} from '@/utils/weeklyVolume'

export type DateRange = WeekRange

export type TrainingPeriodStats = {
  totalSets: number
  totalReps: number
  tonnageLbs: number
  trainedDays: number
  uniqueExercises: number
  cardioMinutes: number
  uniqueMuscleGroups: number
  heaviestSetLbs: number
  heaviestSetLabel: string | null
  personalBests: number
  circuitSets: number
  coreHoldSeconds: number
  estimatedCalories: number | null
  topMuscleGroup: string | null
  avgSetsPerTrainingDay: number
  /** Trained days ÷ elapsed calendar days in range (month-style windows). */
  consistencyPct: number | null
}

export type TrainingStatsOptions = {
  bodyWeightLbs?: number
  planAssumptions?: PlanDurationAssumptions
}

export function getTodayRange(date: Date = new Date()): DateRange {
  const key = toDateKey(date)
  return { startKey: key, endKey: key }
}

export function getMonthRangeForDate(date: Date = new Date()): DateRange {
  const y = date.getFullYear()
  const m = date.getMonth()
  const start = new Date(y, m, 1)
  const end = new Date(y, m + 1, 0)
  return { startKey: toDateKey(start), endKey: toDateKey(end) }
}

export function getPreviousMonthRange(range: DateRange): DateRange {
  const start = parseDateKey(range.startKey)
  const prevStart = new Date(start.getFullYear(), start.getMonth() - 1, 1)
  const prevEnd = new Date(start.getFullYear(), start.getMonth(), 0)
  return { startKey: toDateKey(prevStart), endKey: toDateKey(prevEnd) }
}

export function getAllTimeRange(log: WorkoutLog): DateRange {
  const keys = Object.keys(log).filter((k) => k <= todayKey()).sort()
  const startKey = keys[0] ?? todayKey()
  return { startKey, endKey: todayKey() }
}

export function formatMonthLabel(range: DateRange): string {
  const start = parseDateKey(range.startKey)
  return new Intl.DateTimeFormat(undefined, { month: 'long', year: 'numeric' }).format(start)
}

export function formatTodayLabel(date: Date = new Date()): string {
  return new Intl.DateTimeFormat(undefined, {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  }).format(date)
}

export { formatWeekLabel, getPreviousWeekRange, getWeekRangeForDate }

function dateKeyInRange(dateKey: string, range: DateRange): boolean {
  return dateKey >= range.startKey && dateKey <= range.endKey
}

function setCountsAsCompleted(set: SetLog, exercise: Exercise): boolean {
  if (!setCountsTowardProgress(set)) return false
  if (exercise.isCircuit) return set.checked === true
  if (exerciseIsCardio(exercise)) return false
  if (exercise.isCore) return coreSetLogged(set)
  return set.reps.trim() !== '' && set.weight.trim() !== ''
}

function exerciseKey(ex: Exercise): string {
  const id = (ex.libraryId ?? '').trim()
  if (id) return `id:${id}`
  return `name:${ex.name.trim().toLowerCase()}`
}

function muscleGroupsForExercise(ex: Exercise): MuscleGroup[] {
  if (ex.libraryId) {
    const lib = getLibraryExercise(ex.libraryId)
    if (lib) return lib.muscleGroups
  }
  return []
}

function elapsedDaysInRange(range: DateRange, throughKey: string): number {
  const endKey = range.endKey < throughKey ? range.endKey : throughKey
  if (endKey < range.startKey) return 0
  const start = parseDateKey(range.startKey)
  const end = parseDateKey(endKey)
  const diff = Math.round((end.getTime() - start.getTime()) / 86_400_000)
  return diff + 1
}

/** Max logged weight per exercise key strictly before `beforeKey`. */
function maxWeightBeforeDate(log: WorkoutLog, beforeKey: string): Map<string, number> {
  const maxes = new Map<string, number>()
  for (const [dateKey, dayEntry] of Object.entries(log)) {
    if (dateKey >= beforeKey) continue
    for (const ex of getDayExercises(dayEntry)) {
      if (exerciseIsCardio(ex) || ex.isCircuit || ex.isCore) continue
      const key = exerciseKey(ex)
      for (const s of ex.sets) {
        if (!setCountsTowardProgress(s)) continue
        const w = parseStoredLbs(s.weight)
        const r = parseInt(s.reps.trim(), 10)
        if (Number.isNaN(w) || w <= 0 || Number.isNaN(r) || r <= 0) continue
        maxes.set(key, Math.max(maxes.get(key) ?? 0, w))
      }
    }
  }
  return maxes
}

function countPersonalBestsInRange(log: WorkoutLog, range: DateRange): number {
  const priorMax = maxWeightBeforeDate(log, range.startKey)
  const seenInRange = new Map<string, number>()
  let count = 0

  for (const [dateKey, dayEntry] of Object.entries(log)) {
    if (!dateKeyInRange(dateKey, range)) continue
    for (const ex of getDayExercises(dayEntry)) {
      if (exerciseIsCardio(ex) || ex.isCircuit || ex.isCore) continue
      const key = exerciseKey(ex)
      for (const s of ex.sets) {
        if (!setCountsTowardProgress(s)) continue
        const w = parseStoredLbs(s.weight)
        const r = parseInt(s.reps.trim(), 10)
        if (Number.isNaN(w) || w <= 0 || Number.isNaN(r) || r <= 0) continue
        const prev = Math.max(priorMax.get(key) ?? 0, seenInRange.get(key) ?? 0)
        if (w > prev) {
          count++
          seenInRange.set(key, Math.max(seenInRange.get(key) ?? 0, w))
        }
      }
    }
  }
  return count
}

export function computeTrainingStats(
  log: WorkoutLog,
  range: DateRange,
  options: TrainingStatsOptions = {},
): TrainingPeriodStats {
  const base = computeWeeklyVolume(log, range)
  const exerciseNames = new Set<string>()
  const muscleGroups = new Set<MuscleGroup>()
  const muscleSetCounts = new Map<MuscleGroup, number>()
  let cardioMinutes = 0
  let heaviestSetLbs = 0
  let heaviestSetLabel: string | null = null
  let circuitSets = 0
  let coreHoldSeconds = 0
  let estimatedCalories: number | null = null
  let calorieSum = 0
  let hasCalories = false

  for (const [dateKey, dayEntry] of Object.entries(log)) {
    if (!dateKeyInRange(dateKey, range)) continue
    const exercises = getDayExercises(dayEntry)

    for (const ex of exercises) {
      const name = ex.name.trim()
      if (name) exerciseNames.add(name.toLowerCase())

      if (exerciseIsCardio(ex)) {
        const dur = parseInt(cardioLoggedDurationMinutes(ex), 10)
        if (!Number.isNaN(dur) && dur > 0) cardioMinutes += dur
        continue
      }

      const groups = muscleGroupsForExercise(ex)
      for (const g of groups) muscleGroups.add(g)

      for (const s of ex.sets) {
        if (ex.isCircuit && setCountsTowardProgress(s) && s.checked === true) {
          circuitSets++
        }
        if (ex.isCore && coreSetLogged(s)) {
          coreHoldSeconds += parseSetDurationSeconds(s) ?? 0
        }
        if (!setCountsAsCompleted(s, ex)) continue

        for (const g of groups) {
          muscleSetCounts.set(g, (muscleSetCounts.get(g) ?? 0) + 1)
        }

        if (!ex.isCore && !ex.isCircuit) {
          const w = parseStoredLbs(s.weight)
          if (!Number.isNaN(w) && w > heaviestSetLbs) {
            heaviestSetLbs = w
            heaviestSetLabel = name || null
          }
        }
      }
    }

    if (options.bodyWeightLbs && options.bodyWeightLbs > 0 && options.planAssumptions) {
      const est = estimateWorkoutCalories(exercises, options.bodyWeightLbs, options.planAssumptions)
      if (est) {
        calorieSum += est.calories
        hasCalories = true
      }
    }
  }

  if (hasCalories) estimatedCalories = calorieSum

  let topMuscleGroup: string | null = null
  let topCount = 0
  for (const [g, n] of muscleSetCounts) {
    if (n > topCount) {
      topCount = n
      topMuscleGroup = MUSCLE_GROUP_LABELS[g]
    }
  }

  const personalBests = countPersonalBestsInRange(log, range)
  const avgSetsPerTrainingDay =
    base.trainedDays > 0 ? Math.round((base.totalSets / base.trainedDays) * 10) / 10 : 0

  const elapsed = elapsedDaysInRange(range, todayKey())
  const consistencyPct =
    elapsed > 0 ? Math.round((base.trainedDays / elapsed) * 100) : null

  return {
    ...base,
    uniqueExercises: exerciseNames.size,
    cardioMinutes,
    uniqueMuscleGroups: muscleGroups.size,
    heaviestSetLbs,
    heaviestSetLabel,
    personalBests,
    circuitSets,
    coreHoldSeconds,
    estimatedCalories,
    topMuscleGroup,
    avgSetsPerTrainingDay,
    consistencyPct,
  }
}

export type StatDelta = {
  sets: number
  reps: number
  tonnageLbs: number
  days: number
  uniqueExercises: number
  cardioMinutes: number
  personalBests: number
}

export function trainingStatsDelta(
  current: TrainingPeriodStats,
  previous: TrainingPeriodStats,
): StatDelta {
  return {
    sets: current.totalSets - previous.totalSets,
    reps: current.totalReps - previous.totalReps,
    tonnageLbs: current.tonnageLbs - previous.tonnageLbs,
    days: current.trainedDays - previous.trainedDays,
    uniqueExercises: current.uniqueExercises - previous.uniqueExercises,
    cardioMinutes: current.cardioMinutes - previous.cardioMinutes,
    personalBests: current.personalBests - previous.personalBests,
  }
}

export function formatAllTimeLabel(range: DateRange): string {
  if (range.startKey === range.endKey) return formatTodayLabel(parseDateKey(range.startKey))
  const start = parseDateKey(range.startKey)
  const end = parseDateKey(range.endKey)
  const fmt = new Intl.DateTimeFormat(undefined, { month: 'short', year: 'numeric' })
  return `${fmt.format(start)} – ${fmt.format(end)}`
}

/** Calendar days trained on within a range (for streak helpers elsewhere). */
export function trainedDateKeysInRange(log: WorkoutLog, range: DateRange): string[] {
  const keys: string[] = []
  for (const [dateKey, entry] of Object.entries(log)) {
    if (!dateKeyInRange(dateKey, range)) continue
    if (isRestDayEntry(entry)) continue
    const exercises = getDayExercises(entry)
    const hasWork = exercises.some((ex) =>
      ex.sets.some((s) => {
        if (exerciseIsCardio(ex)) {
          const d = parseInt((s.reps ?? '').trim(), 10)
          return !Number.isNaN(d) && d > 0
        }
        return setCountsTowardProgress(s) && s.reps.trim() && s.weight.trim()
      }),
    )
    if (hasWork) keys.push(dateKey)
  }
  return keys.sort()
}

export function addDaysRange(range: DateRange, deltaDays: number): DateRange {
  return {
    startKey: addDaysToDateKey(range.startKey, deltaDays),
    endKey: addDaysToDateKey(range.endKey, deltaDays),
  }
}
