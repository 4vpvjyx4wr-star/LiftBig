import { describe, expect, it } from 'vitest'
import { healthActivityForLibrary, healthWorkoutDuplicates, healthWritesForLog } from '@/utils/healthWorkout'
import type { WorkoutLog } from '@/types/workout'

describe('health workouts', () => {
  it('maps library ids onto Health activity types', () => {
    expect(healthActivityForLibrary('running')).toBe('running')
    expect(healthActivityForLibrary('outdoor-cycling')).toBe('cycling')
    expect(healthActivityForLibrary('unknown')).toBe('mixedCardio')
  })

  it('writes strength and cardio separately and skips a matching duration', () => {
    const log: WorkoutLog = {
      '2026-10-09': {
        exercises: [
          {
            id: 'squat',
            name: 'Squat',
            sets: [{ id: 's1', reps: '5', weight: '135', checked: true }],
          },
          {
            id: 'run',
            name: 'Running',
            libraryId: 'running',
            isCardio: true,
            sets: [{ id: 'c1', reps: '20', weight: '2' }],
          },
        ],
      },
    }
    const writes = healthWritesForLog(log, {
      bodyWeightLbs: 180,
      assumptions: { minutesPerSet: 1, minutesRestBetweenSets: 1 },
      distanceUnit: 'mi',
      now: new Date('2026-10-09T20:00:00'),
    })
    expect(writes.map((w) => w.activity)).toEqual(['strength', 'running'])
    const run = writes[1]!
    expect(run.distanceMeters).toBeCloseTo(3218.688, 2)
    expect(
      healthWorkoutDuplicates(
        { activity: 'running', startMs: run.startMs, endMs: run.endMs },
        run,
      ),
    ).toBe(true)
  })
})
