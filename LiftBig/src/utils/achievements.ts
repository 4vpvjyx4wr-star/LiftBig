import {
  cardioLoggedDurationMinutes,
  exerciseIsCardio,
  getDayExercises,
  isRestDayEntry,
  parseSetDurationSeconds,
  parseSetRepsCount,
  setCountsTowardProgress,
  type WorkoutLog,
} from '@/types/workout'
import { getLibraryExercise } from '@/utils/exerciseLibrary'
import { getLibraryExerciseLogStats } from '@/utils/libraryExerciseTracking'
import { parseStoredLbs } from '@/utils/units'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { loadJson, saveJson } from '@/utils/storage'
import { getWeekRangeForDate } from '@/utils/weeklyVolume'

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
  | 'streak-3'
  | 'streak-14'
  | 'streak-30'
  | 'sessions-200'
  | 'sessions-500'
  | 'tonnage-1m'
  | 'cardio-debut'
  | 'cardio-10-hours'
  | 'cardio-50'
  | 'unique-25'
  | 'unique-50'
  | 'unique-100'
  | 'variety-week'
  | 'ohp-plate'
  | 'ohp-2-plates'
  | 'hip-thrust-2-plates'
  | 'hip-thrust-3-plates'
  | 'row-2-plates'
  | 'pull-up-debut'
  | 'pull-up-10'
  | 'core-1000'
  | 'core-10000'
  | 'rest-days-10'
  | 'month-20'
  | 'sets-1k'
  | 'sets-5k'
  | 'sets-10k'
  | 'reps-10k'
  | 'reps-100k'
  | 'superset-25'

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
    id: 'streak-3',
    title: 'Fire starter',
    description: 'Train on 3 consecutive calendar days.',
    icon: 'fa-fire-flame-curved',
  },
  {
    id: 'streak-7',
    title: 'Week warrior',
    description: 'Train on 7 consecutive calendar days.',
    icon: 'fa-fire',
  },
  {
    id: 'streak-14',
    title: 'Fortnight fighter',
    description: 'Train on 14 consecutive calendar days.',
    icon: 'fa-fire-flame-simple',
  },
  {
    id: 'streak-30',
    title: 'Monthly machine',
    description: 'Train on 30 consecutive calendar days.',
    icon: 'fa-meteor',
  },
  {
    id: 'cardio-debut',
    title: 'Cardio convert',
    description: 'Log your first cardio session.',
    icon: 'fa-person-running',
  },
  {
    id: 'pull-up-debut',
    title: 'First chin',
    description: 'Log your first pull-up set.',
    icon: 'fa-arrow-up',
  },
  {
    id: 'sessions-50',
    title: 'Half century',
    description: 'Log 50 training sessions.',
    icon: 'fa-calendar-check',
  },
  {
    id: 'unique-25',
    title: 'Movement explorer',
    description: 'Log 25 different exercises.',
    icon: 'fa-compass',
  },
  {
    id: 'sets-1k',
    title: 'Set collector',
    description: 'Log 1,000 working sets.',
    icon: 'fa-layer-group',
  },
  {
    id: 'reps-10k',
    title: 'Rep rally',
    description: 'Log 10,000 total reps.',
    icon: 'fa-repeat',
  },
  {
    id: 'tonnage-100k',
    title: '100K tonnage',
    description: 'Accumulate 100,000+ lbs of total volume.',
    icon: 'fa-weight-hanging',
  },
  {
    id: 'core-1000',
    title: 'Plank pro',
    description: 'Accumulate 1,000 seconds of logged core hold time.',
    icon: 'fa-stopwatch',
  },
  {
    id: 'cardio-10-hours',
    title: 'Endurance engine',
    description: 'Log 600+ minutes of cardio.',
    icon: 'fa-heart-pulse',
  },
  {
    id: 'rest-days-10',
    title: 'Recovery respect',
    description: 'Log 10 intentional rest days.',
    icon: 'fa-bed',
  },
  {
    id: 'variety-week',
    title: 'Mix master',
    description: 'Hit 8+ different exercises in a single calendar week.',
    icon: 'fa-shuffle',
  },
  {
    id: 'superset-25',
    title: 'Superset savvy',
    description: 'Log 25 exercises performed as supersets.',
    icon: 'fa-link',
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
    id: 'unique-50',
    title: 'Exercise encyclopedia',
    description: 'Log 50 different exercises.',
    icon: 'fa-book',
  },
  {
    id: 'pull-up-10',
    title: 'Double digits',
    description: 'Log a set of 10+ pull-ups.',
    icon: 'fa-arrow-up-right-dots',
  },
  {
    id: 'month-20',
    title: 'Twenty in thirty',
    description: 'Train on 20+ days in a single calendar month.',
    icon: 'fa-calendar-days',
  },
  {
    id: 'sessions-200',
    title: 'Double ton',
    description: 'Log 200 training sessions.',
    icon: 'fa-star',
  },
  {
    id: 'sets-5k',
    title: 'Set factory',
    description: 'Log 5,000 working sets.',
    icon: 'fa-cubes',
  },
  {
    id: 'reps-100k',
    title: 'Centurion reps',
    description: 'Log 100,000 total reps.',
    icon: 'fa-infinity',
  },
  {
    id: 'tonnage-500k',
    title: 'Half-million mover',
    description: 'Move 500,000+ lbs of total tonnage.',
    icon: 'fa-bolt',
  },
  {
    id: 'cardio-50',
    title: 'Steady state',
    description: 'Log 50 cardio sessions.',
    icon: 'fa-heart',
  },
  {
    id: 'unique-100',
    title: 'Library legend',
    description: 'Log 100 different exercises.',
    icon: 'fa-crown',
  },
  {
    id: 'core-10000',
    title: 'Core of steel',
    description: 'Accumulate 10,000 seconds of logged core hold time.',
    icon: 'fa-shield-halved',
  },
  {
    id: 'ohp-plate',
    title: 'Strict press club',
    description: 'Log a working set of 135+ lbs on overhead press.',
    icon: 'fa-arrow-up-from-bracket',
  },
  {
    id: 'bench-2-plates',
    title: 'Bench two plates',
    description: 'Log a working set of 225+ lbs on barbell bench press.',
    icon: 'fa-layer-group',
  },
  {
    id: 'squat-2-plates',
    title: 'Squat two plates',
    description: 'Log a working set of 225+ lbs on barbell back squat.',
    icon: 'fa-arrows-down-to-line',
  },
  {
    id: 'deadlift-2-plates',
    title: 'Deadlift two plates',
    description: 'Log a working set of 225+ lbs on barbell deadlift.',
    icon: 'fa-dumbbell',
  },
  {
    id: 'row-2-plates',
    title: 'Row two plates',
    description: 'Log a working set of 225+ lbs on barbell row.',
    icon: 'fa-grip-lines',
  },
  {
    id: 'hip-thrust-2-plates',
    title: 'Glute goals',
    description: 'Log a working set of 225+ lbs on hip thrust.',
    icon: 'fa-chart-line',
  },
  {
    id: 'ohp-2-plates',
    title: 'Press two plates',
    description: 'Log a working set of 225+ lbs on overhead press.',
    icon: 'fa-arrow-up-from-bracket',
  },
  {
    id: 'bench-3-plates',
    title: 'Bench three plates',
    description: 'Log a working set of 315+ lbs on barbell bench press.',
    icon: 'fa-layer-group',
  },
  {
    id: 'squat-3-plates',
    title: 'Squat three plates',
    description: 'Log a working set of 315+ lbs on barbell back squat.',
    icon: 'fa-arrows-down-to-line',
  },
  {
    id: 'deadlift-3-plates',
    title: 'Deadlift three plates',
    description: 'Log a working set of 315+ lbs on barbell deadlift.',
    icon: 'fa-dumbbell',
  },
  {
    id: 'hip-thrust-3-plates',
    title: 'Heavy thrust',
    description: 'Log a working set of 315+ lbs on hip thrust.',
    icon: 'fa-chart-line',
  },
  {
    id: 'sets-10k',
    title: 'Volume king',
    description: 'Log 10,000 working sets.',
    icon: 'fa-mountain',
  },
  {
    id: 'sessions-500',
    title: 'Iron veteran',
    description: 'Log 500 training sessions.',
    icon: 'fa-award',
  },
  {
    id: 'tonnage-1m',
    title: 'Million pound club',
    description: 'Move 1,000,000+ lbs of total tonnage.',
    icon: 'fa-gem',
  },
  {
    id: 'bench-4-plates',
    title: 'Bench four plates',
    description: 'Log a working set of 405+ lbs on barbell bench press.',
    icon: 'fa-layer-group',
  },
  {
    id: 'squat-4-plates',
    title: 'Squat four plates',
    description: 'Log a working set of 405+ lbs on barbell back squat.',
    icon: 'fa-arrows-down-to-line',
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

function totalSetCount(log: WorkoutLog): number {
  let total = 0
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      if (exerciseIsCardio(ex)) continue
      for (const s of ex.sets) {
        if (!setCountsTowardProgress(s)) continue
        if (ex.isCircuit) {
          if (s.checked === true) total++
          continue
        }
        if (ex.isCore) {
          if (parseSetRepsCount(s) != null || parseSetDurationSeconds(s) != null) total++
          continue
        }
        if (s.reps.trim() && s.weight.trim()) total++
      }
    }
  }
  return total
}

function totalRepCount(log: WorkoutLog): number {
  let total = 0
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      if (exerciseIsCardio(ex) || ex.isCircuit) continue
      for (const s of ex.sets) {
        if (!setCountsTowardProgress(s)) continue
        const r = parseInt(s.reps.trim(), 10)
        if (!Number.isNaN(r) && r > 0) total += r
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

function countUniqueExercises(log: WorkoutLog): number {
  const names = new Set<string>()
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      const n = ex.name.trim().toLowerCase()
      if (n) names.add(n)
    }
  }
  return names.size
}

function totalCardioMinutes(log: WorkoutLog): number {
  let total = 0
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      if (!exerciseIsCardio(ex)) continue
      const d = parseInt(cardioLoggedDurationMinutes(ex), 10)
      if (!Number.isNaN(d) && d > 0) total += d
    }
  }
  return total
}

function countCardioSessions(log: WorkoutLog): number {
  let count = 0
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      if (!exerciseIsCardio(ex)) continue
      const d = parseInt(cardioLoggedDurationMinutes(ex), 10)
      if (!Number.isNaN(d) && d > 0) count++
    }
  }
  return count
}

function hasCardioSession(log: WorkoutLog): boolean {
  return countCardioSessions(log) > 0
}

function countRestDays(log: WorkoutLog): number {
  let count = 0
  for (const entry of Object.values(log)) {
    if (isRestDayEntry(entry)) count++
  }
  return count
}

function totalCoreSeconds(log: WorkoutLog): number {
  let total = 0
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      if (!ex.isCore) continue
      for (const s of ex.sets) {
        if (!setCountsTowardProgress(s)) continue
        total += parseSetDurationSeconds(s) ?? 0
      }
    }
  }
  return total
}

function countSupersetExercises(log: WorkoutLog): number {
  let count = 0
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      if (ex.supersetGroupId?.trim()) count++
    }
  }
  return count
}

function maxDaysTrainedInMonth(log: WorkoutLog): number {
  const byMonth = new Map<string, number>()
  for (const dateKey of trainedDateKeys(log)) {
    const monthKey = dateKey.slice(0, 7)
    byMonth.set(monthKey, (byMonth.get(monthKey) ?? 0) + 1)
  }
  let best = 0
  for (const n of byMonth.values()) best = Math.max(best, n)
  return best
}

function hasVarietyWeek(log: WorkoutLog): boolean {
  const dates = trainedDateKeys(log)
  if (dates.length === 0) return false

  const weekStarts = new Set<string>()
  for (const dateKey of dates) {
    weekStarts.add(getWeekRangeForDate(new Date(`${dateKey}T12:00:00`)).startKey)
  }

  for (const startKey of weekStarts) {
    const range = getWeekRangeForDate(new Date(`${startKey}T12:00:00`))
    const names = new Set<string>()
    for (const [dateKey, dayEntry] of Object.entries(log)) {
      if (dateKey < range.startKey || dateKey > range.endKey) continue
      for (const ex of getDayExercises(dayEntry)) {
        const n = ex.name.trim().toLowerCase()
        if (n) names.add(n)
      }
    }
    if (names.size >= 8) return true
  }
  return false
}

function isPullUpExercise(ex: { libraryId?: string; name: string }): boolean {
  if (ex.libraryId === 'pull-up') return true
  return ex.name.trim().toLowerCase().includes('pull-up')
}

function hasLoggedPullUps(log: WorkoutLog): boolean {
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      if (!isPullUpExercise(ex)) continue
      for (const s of ex.sets) {
        if (!setCountsTowardProgress(s)) continue
        const r = parseSetRepsCount(s)
        if (r != null && r > 0) return true
      }
    }
  }
  return false
}

function maxPullUpReps(log: WorkoutLog): number {
  let best = 0
  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      if (!isPullUpExercise(ex)) continue
      for (const s of ex.sets) {
        if (!setCountsTowardProgress(s)) continue
        const r = parseSetRepsCount(s)
        if (r != null) best = Math.max(best, r)
      }
    }
  }
  return best
}

export function computeUnlockedAchievements(log: WorkoutLog): Set<AchievementId> {
  const unlocked = new Set<AchievementId>()
  const sessions = trainedDateKeys(log)
  const sessionCount = sessions.length
  const tonnage = totalTonnageLbs(log)
  const streak = longestTrainingStreakDays(sessions)
  const sets = totalSetCount(log)
  const reps = totalRepCount(log)

  if (sessionCount >= 1) unlocked.add('first-workout')
  if (tonnage >= 10_000) unlocked.add('tonnage-10k')
  if (tonnage >= 100_000) unlocked.add('tonnage-100k')
  if (tonnage >= 500_000) unlocked.add('tonnage-500k')
  if (tonnage >= 1_000_000) unlocked.add('tonnage-1m')
  if (sessionCount >= 50) unlocked.add('sessions-50')
  if (sessionCount >= 100) unlocked.add('sessions-100')
  if (sessionCount >= 200) unlocked.add('sessions-200')
  if (sessionCount >= 500) unlocked.add('sessions-500')
  if (streak >= 3) unlocked.add('streak-3')
  if (streak >= 7) unlocked.add('streak-7')
  if (streak >= 14) unlocked.add('streak-14')
  if (streak >= 30) unlocked.add('streak-30')
  if (streak >= 84) unlocked.add('streak-12-weeks')
  if (sets >= 1_000) unlocked.add('sets-1k')
  if (sets >= 5_000) unlocked.add('sets-5k')
  if (sets >= 10_000) unlocked.add('sets-10k')
  if (reps >= 10_000) unlocked.add('reps-10k')
  if (reps >= 100_000) unlocked.add('reps-100k')

  if (hasCardioSession(log)) unlocked.add('cardio-debut')
  if (totalCardioMinutes(log) >= 600) unlocked.add('cardio-10-hours')
  if (countCardioSessions(log) >= 50) unlocked.add('cardio-50')

  const unique = countUniqueExercises(log)
  if (unique >= 25) unlocked.add('unique-25')
  if (unique >= 50) unlocked.add('unique-50')
  if (unique >= 100) unlocked.add('unique-100')
  if (hasVarietyWeek(log)) unlocked.add('variety-week')

  if (countRestDays(log) >= 10) unlocked.add('rest-days-10')
  if (maxDaysTrainedInMonth(log) >= 20) unlocked.add('month-20')
  if (countSupersetExercises(log) >= 25) unlocked.add('superset-25')

  const coreSec = totalCoreSeconds(log)
  if (coreSec >= 1_000) unlocked.add('core-1000')
  if (coreSec >= 10_000) unlocked.add('core-10000')

  if (hasLoggedPullUps(log)) unlocked.add('pull-up-debut')
  if (maxPullUpReps(log) >= 10) unlocked.add('pull-up-10')

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

  const ohpMax = maxLoggedLiftLbs(log, 'overhead-press')
  if (ohpMax >= 135) unlocked.add('ohp-plate')
  if (ohpMax >= 225) unlocked.add('ohp-2-plates')

  const rowMax = maxLoggedLiftLbs(log, 'barbell-row')
  if (rowMax >= 225) unlocked.add('row-2-plates')

  const hipMax = maxLoggedLiftLbs(log, 'hip-thrust')
  if (hipMax >= 225) unlocked.add('hip-thrust-2-plates')
  if (hipMax >= 315) unlocked.add('hip-thrust-3-plates')

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
