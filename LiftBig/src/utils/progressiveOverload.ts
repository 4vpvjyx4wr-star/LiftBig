import { getDayExercises, type WorkoutLog } from '@/types/workout'
import type { WeightUnit } from '@/utils/units'
import { formatDeltaFromLbs } from '@/utils/units'

type SetLogLike = { reps: string; weight: string }

const INCREMENT_MAP: Record<string, number> = {
  'leg press': 10,
  squat: 5,
  rdl: 5,
  'leg extension': 5,
  'hamstring curl': 5,
  'seated hamstring curl': 5,
  'calf raises': 10,
  'walking lunges': 5,
  'incline db press': 5,
  'flat db press': 5,
  'incline machine press': 5,
  'pull ups': 5,
  'lat pulldown': 5,
  'single arm lat pulldown': 2.5,
  'row variation': 5,
  'seated/bentover row': 5,
  'bentover row': 5,
  'chest supported row': 5,
  'cable curl': 2.5,
  'incline cable curl': 2.5,
  'tricep pushdown': 2.5,
  'overhead tricep extension': 2.5,
  'face pulls': 2.5,
  'cable lateral raise': 2.5,
  'lateral raises': 2.5,
  'lateral raise dropset': 2.5,
  'rear delt fly': 2.5,
  'machine flyes': 2.5,
  'cable flyes': 2.5,
  'cable woodchops': 2.5,
  'cable crunches': 2.5,
  'ab machine': 5,
  'weighted reverse crunches': 2.5,
}

/** Typical single-sided jump (lb) when progressing this lift (progressive overload). */
export function getWeightIncrementLbs(exerciseName: string): number {
  const lower = exerciseName.toLowerCase()
  for (const key of Object.keys(INCREMENT_MAP)) {
    if (lower.includes(key)) return INCREMENT_MAP[key]!
  }
  return 2.5
}

function isAMRAP(repGoal: string): boolean {
  return repGoal.toLowerCase().includes('amrap')
}

export function parseRepRange(repGoal: string): { min: number; max: number } {
  if (isAMRAP(repGoal)) return { min: 1, max: 9999 }
  const match = repGoal.match(/(\d+)\s*[-–]\s*(\d+)/)
  if (match) return { min: parseInt(match[1]!, 10), max: parseInt(match[2]!, 10) }
  const single = parseInt(repGoal, 10)
  if (!isNaN(single)) return { min: single, max: single }
  return { min: 0, max: 9999 }
}

/** Rep count to prefill for set logging: top of programmed range; empty for AMRAP or invalid. */
export function getDefaultLogRepsForTarget(targetReps: string): string {
  const t = targetReps.trim()
  if (!t) return ''
  if (isAMRAP(t)) return ''
  const { max } = parseRepRange(t)
  if (max <= 0 || max >= 9999) return ''
  return String(max)
}

export function getSuggestedWeight(
  exerciseName: string,
  targetRepGoal: string,
  currentGoalWeight: number,
  allWorkouts: WorkoutLog,
  displayUnit: WeightUnit = 'lb',
): { suggestedWeight: number; reason: string } {
  try {
    if (!allWorkouts || Object.keys(allWorkouts).length === 0) {
      return { suggestedWeight: currentGoalWeight, reason: 'No history yet' }
    }

    const { max: repMax } = parseRepRange(targetRepGoal)

    const history: { date: string; sets: SetLogLike[] }[] = []
    for (const [date, dayEntry] of Object.entries(allWorkouts)) {
      const exercises = getDayExercises(dayEntry)
      const match = exercises.find((ex) => ex.name.toLowerCase() === exerciseName.toLowerCase())
      if (match) history.push({ date, sets: match.sets })
    }
    history.sort((a, b) => b.date.localeCompare(a.date))

    if (history.length === 0) {
      return { suggestedWeight: currentGoalWeight, reason: 'No history yet' }
    }

    const lastSession = history[0]!
    const completedSets = lastSession.sets.filter((s) => s.reps !== '' && s.weight !== '')
    if (completedSets.length === 0) {
      return { suggestedWeight: currentGoalWeight, reason: 'No completed sets found' }
    }

    const allHitMax = completedSets.every((s) => {
      if (isAMRAP(targetRepGoal)) return true
      return parseInt(s.reps, 10) >= repMax
    })

    const lastWeight =
      parseFloat(completedSets[completedSets.length - 1]!.weight) || currentGoalWeight
    const increment = getWeightIncrementLbs(exerciseName)

    if (allHitMax) {
      return {
        suggestedWeight: lastWeight + increment,
        reason: `Hit top of range last session — increase by ${formatDeltaFromLbs(increment, displayUnit)}`,
      }
    }

    const { min: repMin } = parseRepRange(targetRepGoal)
    const anyFailed = completedSets.some((s) => parseInt(s.reps, 10) < repMin)
    if (anyFailed) {
      return {
        suggestedWeight: lastWeight,
        reason: 'Stay at current weight — keep working toward the top of the range',
      }
    }

    return {
      suggestedWeight: lastWeight,
      reason: 'Good progress — maintain weight and push for more reps',
    }
  } catch {
    return { suggestedWeight: currentGoalWeight, reason: 'Could not load history' }
  }
}
