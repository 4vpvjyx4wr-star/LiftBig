import { describe, expect, it } from 'vitest'
import { nextDailyReminderAt } from '@/utils/reminderSchedule'

describe('daily reminder schedule', () => {
  const now = new Date(2026, 9, 9, 12, 0, 0)

  it('fires later today when the user has not trained', () => {
    const at = nextDailyReminderAt('17:00', false, now)
    expect(at.getDate()).toBe(9)
    expect(at.getHours()).toBe(17)
  })

  it('moves to tomorrow after a workout is logged', () => {
    const at = nextDailyReminderAt('17:00', true, now)
    expect(at.getDate()).toBe(10)
    expect(at.getHours()).toBe(17)
  })

  it('moves to tomorrow when the time has already passed', () => {
    const evening = new Date(2026, 9, 9, 18, 0, 0)
    const at = nextDailyReminderAt('17:00', false, evening)
    expect(at.getDate()).toBe(10)
  })
})
