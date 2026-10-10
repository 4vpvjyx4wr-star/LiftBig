/** Notification ids. Integers, stable across launches so they can be replaced. */
export const REST_NOTIFICATION_ID = 41001
export const DAILY_NOTIFICATION_ID = 41002

export function parseHourMinute(timeHHMM: string): { hour: number; minute: number } {
  const match = timeHHMM.trim().match(/^(\d{1,2}):(\d{2})$/)
  if (!match) return { hour: 17, minute: 0 }
  const hour = Number(match[1])
  const minute = Number(match[2])
  if (hour > 23 || minute > 59) return { hour: 17, minute: 0 }
  return { hour, minute }
}

/** Next time the daily reminder should fire. Skips today when today's workout is already logged. */
export function nextDailyReminderAt(timeHHMM: string, trainedToday: boolean, now = new Date()): Date {
  const { hour, minute } = parseHourMinute(timeHHMM)
  const fire = new Date(now)
  fire.setSeconds(0, 0)
  fire.setHours(hour, minute, 0, 0)
  const alreadyPassed = fire.getTime() <= now.getTime()
  if (alreadyPassed || trainedToday) fire.setDate(fire.getDate() + 1)
  return fire
}
