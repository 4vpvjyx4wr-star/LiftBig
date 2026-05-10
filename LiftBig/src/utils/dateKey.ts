/**
 * All calendar keys use the client's local timezone (getFullYear/getMonth/getDate).
 */

const pad = (n: number) => String(n).padStart(2, '0')

export function toDateKey(d: Date): string {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

export function todayKey(): string {
  return toDateKey(new Date())
}

const DATE_KEY_RE = /^\d{4}-\d{2}-\d{2}$/

export function isValidDateKey(key: string): boolean {
  if (!DATE_KEY_RE.test(key)) return false
  const parts = key.split('-').map(Number)
  const y = parts[0]!
  const m = parts[1]!
  const d = parts[2]!
  const dt = new Date(y, m - 1, d)
  return dt.getFullYear() === y && dt.getMonth() === m - 1 && dt.getDate() === d
}

export const MONTHS = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
] as const

export const WEEKDAYS = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'] as const

export function formatDisplayDate(dateKey: string): string {
  const parts = dateKey.split('-').map(Number)
  const y = parts[0]!
  const m = parts[1]!
  const d = parts[2]!
  return `${MONTHS[m - 1]} ${d}, ${y}`
}

export function parseDateKey(dateKey: string): Date {
  const parts = dateKey.split('-').map(Number)
  const y = parts[0]!
  const m = parts[1]!
  const d = parts[2]!
  return new Date(y, m - 1, d)
}

export function addDaysToDateKey(dateKey: string, deltaDays: number): string {
  const d = parseDateKey(dateKey)
  d.setDate(d.getDate() + deltaDays)
  return toDateKey(d)
}

/** Last calendar day of the month containing `dateKey` (local). */
export function endOfMonthKeyFor(dateKey: string): string {
  const d = parseDateKey(dateKey)
  const last = new Date(d.getFullYear(), d.getMonth() + 1, 0)
  return toDateKey(last)
}
