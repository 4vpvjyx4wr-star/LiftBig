import {
  coreSetLogged,
  exerciseIsCardio,
  getDayExercises,
  setCountsTowardProgress,
  type Exercise,
  type SetLog,
  type WorkoutLog,
} from '@/types/workout'
import { addDaysToDateKey, parseDateKey, toDateKey } from '@/utils/dateKey'
import { parseStoredLbs } from '@/utils/units'

export type WeeklyVolumeStats = {
  totalSets: number
  totalReps: number
  tonnageLbs: number
  trainedDays: number
}

export type WeekRange = {
  startKey: string
  endKey: string
}

/** Calendar weeks run Sunday through Saturday (matches MonthGrid). */
export function getWeekRangeForDate(date: Date = new Date()): WeekRange {
  const local = new Date(date.getFullYear(), date.getMonth(), date.getDate())
  const sunday = new Date(local)
  sunday.setDate(local.getDate() - local.getDay())
  const saturday = new Date(sunday)
  saturday.setDate(sunday.getDate() + 6)
  return { startKey: toDateKey(sunday), endKey: toDateKey(saturday) }
}

export function getPreviousWeekRange(range: WeekRange): WeekRange {
  return {
    startKey: addDaysToDateKey(range.startKey, -7),
    endKey: addDaysToDateKey(range.endKey, -7),
  }
}

function dateKeyInRange(dateKey: string, range: WeekRange): boolean {
  return dateKey >= range.startKey && dateKey <= range.endKey
}

function setCountsAsCompleted(set: SetLog, exercise: Exercise): boolean {
  if (!setCountsTowardProgress(set)) return false
  if (exercise.isCircuit) return set.checked === true
  if (exerciseIsCardio(exercise)) return false
  if (exercise.isCore) return coreSetLogged(set)
  return set.reps.trim() !== '' && set.weight.trim() !== ''
}

function repsFromSet(set: SetLog, exercise: Exercise): number {
  if (exercise.isCircuit || exerciseIsCardio(exercise)) return 0
  if (exercise.isCore) {
    const r = parseInt(set.reps.trim(), 10)
    return Number.isNaN(r) || r < 1 ? 0 : r
  }
  const r = parseInt(set.reps.trim(), 10)
  return Number.isNaN(r) || r < 1 ? 0 : r
}

function tonnageFromSet(set: SetLog, exercise: Exercise): number {
  if (!setCountsTowardProgress(set)) return 0
  if (exercise.isCircuit || exerciseIsCardio(exercise) || exercise.isCore) return 0
  const w = parseStoredLbs(set.weight)
  const r = parseInt(set.reps.trim(), 10)
  if (Number.isNaN(w) || w <= 0 || Number.isNaN(r) || r <= 0) return 0
  if (set.reps.trim() === '' || set.weight.trim() === '') return 0
  return w * r
}

export function computeWeeklyVolume(log: WorkoutLog, range: WeekRange): WeeklyVolumeStats {
  let totalSets = 0
  let totalReps = 0
  let tonnageLbs = 0
  const trainedDayKeys = new Set<string>()

  for (const [dateKey, dayEntry] of Object.entries(log)) {
    if (!dateKeyInRange(dateKey, range)) continue
    const exercises = getDayExercises(dayEntry)
    let dayHasWork = false

    for (const exercise of exercises) {
      for (const set of exercise.sets) {
        if (!setCountsAsCompleted(set, exercise)) continue
        dayHasWork = true
        totalSets++
        totalReps += repsFromSet(set, exercise)
        tonnageLbs += tonnageFromSet(set, exercise)
      }
    }

    if (dayHasWork) trainedDayKeys.add(dateKey)
  }

  return {
    totalSets,
    totalReps,
    tonnageLbs,
    trainedDays: trainedDayKeys.size,
  }
}

export function formatWeekLabel(range: WeekRange): string {
  const start = parseDateKey(range.startKey)
  const end = parseDateKey(range.endKey)
  const sameMonth = start.getMonth() === end.getMonth()
  const monthFmt = new Intl.DateTimeFormat(undefined, { month: 'short' })
  const dayFmt = new Intl.DateTimeFormat(undefined, { day: 'numeric' })
  if (sameMonth) {
    return `${monthFmt.format(start)} ${dayFmt.format(start)}–${dayFmt.format(end)}`
  }
  return `${monthFmt.format(start)} ${dayFmt.format(start)} – ${monthFmt.format(end)} ${dayFmt.format(end)}`
}

export type VolumeDelta = {
  sets: number
  reps: number
  tonnageLbs: number
  days: number
}

export function volumeDelta(current: WeeklyVolumeStats, previous: WeeklyVolumeStats): VolumeDelta {
  return {
    sets: current.totalSets - previous.totalSets,
    reps: current.totalReps - previous.totalReps,
    tonnageLbs: current.tonnageLbs - previous.tonnageLbs,
    days: current.trainedDays - previous.trainedDays,
  }
}
