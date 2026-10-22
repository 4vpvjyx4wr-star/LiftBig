import { describe, expect, it } from 'vitest'
import type { WorkoutLog } from '@/types/workout'
import { predictWorkoutGoals } from '@/utils/progressiveOverload'

function log(sets: { reps: string; weight: string; isWarmup?: boolean; difficulty?: 'Easy' | 'Moderate' | 'Difficult' }[], targetReps = '8-12', name = 'Bench Press'): WorkoutLog {
  return {
    '2026-01-01': {
      exercises: [
        {
          id: 'ex',
          name,
          targetReps,
          sets: sets.map((set, index) => ({ id: `s${index}`, ...set })),
        },
      ],
    },
  }
}

describe('progressive overload', () => {
  it('does not invent a weight with no history and ignores warmups', () => {
    const empty = predictWorkoutGoals('Bench Press', {})
    expect(empty.hasHistory).toBe(false)
    expect(empty.suggestedWeightLbs).toBe(0)
    expect(empty.suggestedLogReps).toBe('')

    const warmupOnly = predictWorkoutGoals('Bench Press', log([
      { reps: '5', weight: '300', isWarmup: true, difficulty: 'Easy' },
    ]))
    expect(warmupOnly.hasHistory).toBe(false)

    const withWork = predictWorkoutGoals('Bench Press', log([
      { reps: '5', weight: '300', isWarmup: true, difficulty: 'Easy' },
      { reps: '9', weight: '100' },
    ]))
    const workOnly = predictWorkoutGoals('Bench Press', log([{ reps: '9', weight: '100' }]))
    expect(withWork.suggestedWeightLbs).toBe(workOnly.suggestedWeightLbs)
    expect(withWork.suggestedLogReps).toBe(workOnly.suggestedLogReps)
  })

  it('adds reps inside the range and load at the top', () => {
    const inside = predictWorkoutGoals('Bench Press', log([{ reps: '9', weight: '100' }]))
    expect(inside.suggestedWeightLbs).toBe(100)
    expect(inside.suggestedLogReps).toBe('10')
    expect(inside.reason).toContain('Add reps before adding weight')

    const top = predictWorkoutGoals('Bench Press', log([{ reps: '12', weight: '100' }]))
    expect(top.suggestedWeightLbs).toBe(102.5)
    expect(top.suggestedLogReps).toBe('8')

    const squat = predictWorkoutGoals('Squat', log([{ reps: '5', weight: '200' }], '5', 'Squat'))
    expect(squat.suggestedWeightLbs).toBe(205)
    expect(squat.suggestedLogReps).toBe('5')
  })

  it('lets Easy, Moderate, and Difficult change the next target', () => {
    const easy = predictWorkoutGoals('Bench Press', log([
      { reps: '8', weight: '100', difficulty: 'Easy' },
    ]))
    expect(easy.suggestedWeightLbs).toBe(100)
    expect(easy.suggestedLogReps).toBe('10')
    expect(easy.reason).toContain('Rated Easy')

    const moderate = predictWorkoutGoals('Bench Press', log([
      { reps: '8', weight: '100', difficulty: 'Moderate' },
    ]))
    expect(moderate.suggestedLogReps).toBe('9')
    expect(moderate.suggestedWeightLbs).toBe(100)

    const held = predictWorkoutGoals('Bench Press', log([
      { reps: '12', weight: '100', difficulty: 'Difficult' },
    ]))
    expect(held.suggestedWeightLbs).toBe(100)
    expect(held.suggestedLogReps).toBe('12')

    const oneHardSet = predictWorkoutGoals('Bench Press', log([
      { reps: '12', weight: '100', difficulty: 'Easy' },
      { reps: '12', weight: '100', difficulty: 'Easy' },
      { reps: '12', weight: '100', difficulty: 'Difficult' },
    ]))
    expect(oneHardSet.suggestedWeightLbs).toBe(102.5)

    const short = predictWorkoutGoals('Bench Press', log([
      { reps: '6', weight: '100', difficulty: 'Difficult' },
    ]))
    expect(short.suggestedWeightLbs).toBe(97.5)
    expect(short.suggestedWeightLbs).toBeGreaterThan(90)

    const missed = predictWorkoutGoals('Bench Press', log([{ reps: '6', weight: '100' }]))
    expect(missed.suggestedWeightLbs).toBe(100)
    expect(missed.reason).toContain('Short of the rep range')
  })

  it('steps back once after repeated Difficult sessions and snaps kilograms', () => {
    const repeated: WorkoutLog = {
      '2026-01-01': {
        exercises: [{
          id: 'a',
          name: 'Bench Press',
          targetReps: '8-12',
          sets: [{ id: 'a1', reps: '12', weight: '100', difficulty: 'Difficult' }],
        }],
      },
      '2026-01-08': {
        exercises: [{
          id: 'b',
          name: 'Bench Press',
          targetReps: '8-12',
          sets: [{ id: 'b1', reps: '12', weight: '100', difficulty: 'Difficult' }],
        }],
      },
    }
    const back = predictWorkoutGoals('Bench Press', repeated)
    expect(back.suggestedWeightLbs).toBe(97.5)
    expect(back.suggestedLogReps).toBe('8')
    expect(back.reason).toContain('Several Difficult sessions')

    const kg = predictWorkoutGoals('Bench Press', log([{ reps: '12', weight: '100' }]), {
      displayUnit: 'kg',
      currentTargetReps: '8-12',
      lockRepGoal: true,
    })
    expect(kg.suggestedWeightLbs).toBeCloseTo(46 * 2.2046226218, 1)
    expect(kg.reason).toContain('1 kg')
  })
})
