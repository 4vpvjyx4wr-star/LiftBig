import { describe, expect, it } from 'vitest'
import { applyCompanionMessage, buildWatchSession } from '@/native/workoutSession'
import type { WorkoutLog } from '@/types/workout'

const exercises = [
  {
    id: 'squat',
    name: 'Back Squat',
    targetReps: '5',
    targetWeight: '225',
    sets: [
      { id: 'a', reps: '', weight: '', checked: false },
      { id: 'b', reps: '', weight: '', checked: false },
    ],
  },
]

describe('watch session', () => {
  it('hides the workout when Pro is inactive', () => {
    expect(buildWatchSession('2026-10-09', exercises, 90, 'lb', false)).toEqual({
      version: 1,
      locked: true,
      reason: 'pro',
    })
  })

  it('shows the current exercise targets for Pro', () => {
    const session = buildWatchSession('2026-10-09', exercises, 90, 'lb', true)
    expect(session).toMatchObject({
      locked: false,
      exerciseName: 'Back Squat',
      targetWeightDisplay: '225',
      targetReps: '5',
      currentSetIndex: 0,
      restSeconds: 90,
    })
  })

  it('writes a completed set into the phone log', () => {
    const log: WorkoutLog = { '2026-10-09': { exercises } }
    const next = applyCompanionMessage(log, {
      version: 1,
      kind: 'completeSet',
      dateKey: '2026-10-09',
      exerciseId: 'squat',
      setIndex: 0,
      reps: '5',
      weightLbs: '225',
    })
    const day = next['2026-10-09']
    const sets = Array.isArray(day) ? day[0]?.sets : day?.exercises[0]?.sets
    expect(sets?.[0]).toMatchObject({ reps: '5', weight: '225', checked: true })
    expect(sets?.[1]?.checked).toBe(false)
  })
})