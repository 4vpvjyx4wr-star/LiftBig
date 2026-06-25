import { getDayExercises, isRestDayEntry, setCountsTowardProgress, type WorkoutLog } from '@/types/workout'
import { getLibraryExercise } from '@/utils/exerciseLibrary'
import { getLibraryExerciseLogStats } from '@/utils/libraryExerciseTracking'
import { parseStoredLbs } from '@/utils/units'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { loadJson, saveJson } from '@/utils/storage'

export type AchievementId =
  | 'first-workout'
  | 'sessions-50'
  | 'streak-7'
  | 'streak-12-weeks'
  | 'tonnage-10k'
  | 'tonnage-100k'
  | 'tonnage-500k'
  | 'sessions-100'
  | 'bench-2-plates'
  | 'bench-3-plates'
  | 'bench-4-plates'
  | 'squat-2-plates'
  | 'squat-3-plates'
  | 'squat-4-plates'
  | 'deadlift-2-plates'
  | 'deadlift-3-plates'
  | 'deadlift-4-plates'

export type AchievementDef = {
  id: AchievementId
  title: string
  description: string
  icon: string
}

export const ACHIEVEMENTS: AchievementDef[] = [
  {
    id: 'first-workout',
    title: 'First rep logged',
    description: 'Complete your first training day.',
    icon: 'fa-flag-checkered',
  },
  {
    id: 'tonnage-10k',
    title: '10K club',
    description: 'Move 10,000+ lbs of total tonnage across all logged sets.',
    icon: 'fa-dumbbell',
  },
  {
    id: 'streak-7',
    title: 'Week warrior',
    description: 'Train on 7 consecutive calendar days.',
    icon: 'fa-fire',
  },
  {
    id: 'sessions-50',
    title: 'Half century',
    description: 'Log 50 training sessions.',
    icon: 'fa-calendar-check',
  },
  {
    id: 'tonnage-100k',
    title: '100K tonnage',
    description: 'Accumulate 100,000+ lbs of total volume.',
    icon: 'fa-weight-hanging',
  },
  {
    id: 'streak-12-weeks',
    title: '12-week streak',
    description: 'Train every day for 12 consecutive weeks (84 days).',
    icon: 'fa-medal',
  },
  {
    id: 'sessions-100',
    title: 'Century sessions',
    description: 'Log 100 training sessions.',
    icon: 'fa-trophy',
  },
  {
    id: 'tonnage-500k',
    title: 'Half-million mover',
    description: 'Move 500,000+ lbs of total tonnage.',
    icon: 'fa-bolt',
  },
  {
    id: 'bench-2-plates',
    title: 'Bench two plates',
    description: 'Log a working set of 225+ lbs on barbell bench press.',
    icon: 'fa-layer-group',
  },
  {
    id: 'bench-3-plates',
    title: 'Bench three plates',
    description: 'Log a working set of 315+ lbs on barbell bench press.',
    icon: 'fa-layer-group',
  },
  {
    id: 'bench-4-plates',
    title: 'Bench four plates',
    description: 'Log a working set of 405+ lbs on barbell bench press.',
    icon: 'fa-layer-group',
  },
  {
    id: 'squat-2-plates',
    title: 'Squat two plates',
    description: 'Log a working set of 225+ lbs on barbell back squat.',
    icon: 'fa-arrows-down-to-line',
  },
  {
    id: 'squat-3-plates',
    title: 'Squat three plates',
    description: 'Log a working set of 315+ lbs on barbell back squat.',
    icon: 'fa-arrows-down-to-line',
  },
  {
    id: 'squat-4-plates',
    title: 'Squat four plates',
    description: 'Log a working set of 405+ lbs on barbell back squat.',
    icon: 'fa-arrows-down-to-line',
  },
  {
    id: 'deadlift-2-plates',
    title: 'Deadlift two plates',
    description: 'Log a working set of 225+ lbs on barbell deadlift.',
    icon: 'fa-dumbbell',
  },
  {
    id: 'deadlift-3-plates',
    title: 'Deadlift three plates',
    description: 'Log a working set of 315+ lbs on barbell deadlift.',
    icon: 'fa-dumbbell',
  },
  {
    id: 'deadlift-4-plates',
    title: 'Deadlift four plates',
    description: 'Log a working set of 405+ lbs on barbell deadlift.',
    icon: 'fa-dumbbell',
  },
]

const CELEBRATED_KEY = `${LIFTBIG_STORAGE_KEYS.settings}_achievement_celebrated`

function normalizeDateKey(key: string): string {
  return key
}

function trainedDateKeys(log: WorkoutLog): string[] {
  const keys: string[] = []
  for (const [dateKey, entry] of Object.entries(log)) {
    if (isRestDayEntry(entry)) continue
    const exercises = getDayExercises(entry)
    if (exercises.length === 0) continue
    const hasWork = exercises.some((ex) =>
      ex.sets.some((s) => {
        if (ex.isCardio) {
          const d = parseInt((s.reps ?? '').trim(), 10)
          return !Number.isNaN(d) && d > 0
        }
        return setCountsTowardProgress(s) && s.reps.trim() && s.weight.trim()
      }),
    )
    if (hasWork) keys.push(normalizeDateKey(dateKey))
  }
  keys.sort()
  return keys
}

function totalTonnageLbs(log: WorkoutLog): number {
  let total = 0
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      if (ex.isCardio) continue
      for (const s of ex.sets) {
        if (!setCountsTowardProgress(s)) continue
        const w = parseStoredLbs(s.weight)
        const r = parseInt(s.reps, 10)
        if (Number.isNaN(w) || w <= 0 || Number.isNaN(r) || r <= 0) continue
        total += w * r
      }
    }
  }
  return total
}

function longestTrainingStreakDays(dates: string[]): number {
  if (dates.length === 0) return 0
  let best = 1
  let run = 1
  for (let i = 1; i < dates.length; i++) {
    const prev = new Date(`${dates[i - 1]}T12:00:00`)
    const cur = new Date(`${dates[i]}T12:00:00`)
    const gapDays = Math.round((cur.getTime() - prev.getTime()) / 86_400_000)
    if (gapDays === 1) {
      run++
      best = Math.max(best, run)
    } else if (gapDays > 1) {
      run = 1
    }
  }
  return best
}

function maxLoggedLiftLbs(log: WorkoutLog, libraryId: string): number {
  const lib = getLibraryExercise(libraryId)
  if (!lib) return 0
  const stats = getLibraryExerciseLogStats(log, lib)
  return stats.maxWeightLbs ?? 0
}

export function computeUnlockedAchievements(log: WorkoutLog): Set<AchievementId> {
  const unlocked = new Set<AchievementId>()
  const sessions = trainedDateKeys(log)
  const sessionCount = sessions.length
  const tonnage = totalTonnageLbs(log)
  const streak = longestTrainingStreakDays(sessions)

  if (sessionCount >= 1) unlocked.add('first-workout')
  if (tonnage >= 10_000) unlocked.add('tonnage-10k')
  if (tonnage >= 100_000) unlocked.add('tonnage-100k')
  if (tonnage >= 500_000) unlocked.add('tonnage-500k')
  if (sessionCount >= 50) unlocked.add('sessions-50')
  if (sessionCount >= 100) unlocked.add('sessions-100')
  if (streak >= 7) unlocked.add('streak-7')
  if (streak >= 84) unlocked.add('streak-12-weeks')

  const benchMax = maxLoggedLiftLbs(log, 'bench-press')
  if (benchMax >= 225) unlocked.add('bench-2-plates')
  if (benchMax >= 315) unlocked.add('bench-3-plates')
  if (benchMax >= 405) unlocked.add('bench-4-plates')

  const squatMax = maxLoggedLiftLbs(log, 'squat')
  if (squatMax >= 225) unlocked.add('squat-2-plates')
  if (squatMax >= 315) unlocked.add('squat-3-plates')
  if (squatMax >= 405) unlocked.add('squat-4-plates')

  const deadliftMax = maxLoggedLiftLbs(log, 'deadlift')
  if (deadliftMax >= 225) unlocked.add('deadlift-2-plates')
  if (deadliftMax >= 315) unlocked.add('deadlift-3-plates')
  if (deadliftMax >= 405) unlocked.add('deadlift-4-plates')

  return unlocked
}

export function loadCelebratedAchievementIds(): Set<AchievementId> {
  const raw = loadJson<string[]>(CELEBRATED_KEY, [])
  return new Set(raw.filter((id): id is AchievementId => ACHIEVEMENTS.some((a) => a.id === id)))
}

export function markAchievementCelebrated(id: AchievementId): void {
  const cur = loadCelebratedAchievementIds()
  if (cur.has(id)) return
  cur.add(id)
  saveJson(CELEBRATED_KEY, [...cur])
}

export function markAllAchievementsCelebrated(ids: Iterable<AchievementId>): void {
  saveJson(CELEBRATED_KEY, [...ids])
}
