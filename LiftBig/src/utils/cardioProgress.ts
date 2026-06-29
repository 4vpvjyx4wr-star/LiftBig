import {
  cardioLoggedDistance,
  cardioLoggedDurationMinutes,
  exerciseIsCardio,
  getDayExercises,
  type WorkoutLog,
} from '@/types/workout'
import { normalizeDistanceInput } from '@/utils/distances'

export type CardioSessionPoint = {
  dateKey: string
  timeMs: number
  durationMinutes: number
  distance: number | null
  /** Minutes per distance unit when both logged; null otherwise. */
  paceMinutesPerUnit: number | null
}

function exerciseNameMatches(a: string, b: string): boolean {
  return a.trim().toLowerCase() === b.trim().toLowerCase()
}

function dateKeyToTimeMs(dateKey: string): number {
  const t = new Date(`${dateKey}T12:00:00`).getTime()
  return Number.isNaN(t) ? 0 : t
}

export function listCardioExerciseNamesFromLog(log: WorkoutLog): string[] {
  const names = new Set<string>()
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      if (!exerciseIsCardio(ex)) continue
      const n = ex.name.trim()
      if (n) names.add(n)
    }
  }
  return [...names].sort((a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' }))
}

export function collectCardioHistory(log: WorkoutLog, exerciseName: string): CardioSessionPoint[] {
  const out: CardioSessionPoint[] = []
  for (const [dateKey, dayEntry] of Object.entries(log)) {
    const exercises = getDayExercises(dayEntry)
    const ex = exercises.find((e) => exerciseIsCardio(e) && exerciseNameMatches(e.name, exerciseName))
    if (!ex) continue

    const durRaw = cardioLoggedDurationMinutes(ex)
    const dur = parseInt(durRaw, 10)
    if (Number.isNaN(dur) || dur <= 0) continue

    const distRaw = cardioLoggedDistance(ex)
    const distParsed = distRaw ? parseFloat(normalizeDistanceInput(distRaw)) : NaN
    const distance = !Number.isNaN(distParsed) && distParsed > 0 ? distParsed : null
    const pace =
      distance != null && distance > 0 ? Math.round((dur / distance) * 100) / 100 : null

    out.push({
      dateKey,
      timeMs: dateKeyToTimeMs(dateKey),
      durationMinutes: dur,
      distance,
      paceMinutesPerUnit: pace,
    })
  }
  out.sort((a, b) => a.dateKey.localeCompare(b.dateKey))
  return out
}
