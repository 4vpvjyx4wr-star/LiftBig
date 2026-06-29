import { getDayExercises, isRestDayEntry, type WorkoutLog } from '@/types/workout'
import { todayKey } from '@/utils/dateKey'
import { showDailyLiftReminderNotification } from '@/utils/notifications'

const DISMISS_KEY_PREFIX = 'liftbig_daily_reminder_dismissed_'

function dismissStorageKey(dateKey: string): string {
  return `${DISMISS_KEY_PREFIX}${dateKey}`
}

export function isDailyReminderDismissedToday(dateKey = todayKey()): boolean {
  if (typeof localStorage === 'undefined') return false
  return localStorage.getItem(dismissStorageKey(dateKey)) === '1'
}

export function dismissDailyReminderForToday(dateKey = todayKey()): void {
  if (typeof localStorage === 'undefined') return
  localStorage.setItem(dismissStorageKey(dateKey), '1')
}

/** True when the day has logged work (exercises with at least one set). */
export function hasTrainedToday(log: WorkoutLog, dateKey = todayKey()): boolean {
  const entry = log[dateKey]
  if (entry == null) return false
  if (isRestDayEntry(entry)) return false
  const exercises = getDayExercises(entry)
  if (exercises.length === 0) return false
  return exercises.some((ex) => ex.sets.length > 0)
}

export function parseReminderMinutes(timeHHMM: string): number {
  const m = timeHHMM.trim().match(/^(\d{1,2}):(\d{2})$/)
  if (!m) return 17 * 60
  const h = Number(m[1])
  const min = Number(m[2])
  if (!Number.isFinite(h) || !Number.isFinite(min)) return 17 * 60
  return h * 60 + min
}

export function reminderTimeReached(timeHHMM: string, now = new Date()): boolean {
  const target = parseReminderMinutes(timeHHMM)
  const current = now.getHours() * 60 + now.getMinutes()
  return current >= target
}

export type DailyReminderState = {
  shouldNudge: boolean
  shouldNotify: boolean
}

let lastNotifiedDateKey = ''

export function evaluateDailyLiftReminder(
  log: WorkoutLog,
  enabled: boolean,
  timeHHMM: string,
  now = new Date(),
): DailyReminderState {
  if (!enabled) return { shouldNudge: false, shouldNotify: false }
  const dateKey = todayKey()
  if (hasTrainedToday(log, dateKey)) return { shouldNudge: false, shouldNotify: false }
  if (!reminderTimeReached(timeHHMM, now)) return { shouldNudge: false, shouldNotify: false }
  if (isDailyReminderDismissedToday(dateKey)) return { shouldNudge: false, shouldNotify: false }
  return { shouldNudge: true, shouldNotify: true }
}

/** Fire browser notification once per day when appropriate. */
export function maybeFireDailyLiftNotification(
  log: WorkoutLog,
  enabled: boolean,
  timeHHMM: string,
  now = new Date(),
): void {
  const state = evaluateDailyLiftReminder(log, enabled, timeHHMM, now)
  const dateKey = todayKey()
  if (!state.shouldNotify) return
  if (lastNotifiedDateKey === dateKey) return
  lastNotifiedDateKey = dateKey
  showDailyLiftReminderNotification()
}
