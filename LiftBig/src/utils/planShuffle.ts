import type { LibraryExercise, MuscleGroup } from '@/utils/exerciseLibrary'
import { EXERCISE_LIBRARY, MUSCLE_GROUPS, MUSCLE_GROUP_LABELS } from '@/utils/exerciseLibrary'
import type { TemplateExercise, WorkoutTemplate } from '@/types/workout'
import type { PlanDurationAssumptions } from '@/utils/planDuration'
import { DEFAULT_PLAN_DURATION_ASSUMPTIONS, estimatePlanDurationMinutes } from '@/utils/planDuration'

export type MovementPattern = 'push' | 'pull' | 'legs'

/** Muscle groups plus movement patterns available in the shuffle filter UI. */
export type ShuffleFocus = MuscleGroup | MovementPattern

export const MOVEMENT_PATTERNS: MovementPattern[] = ['push', 'pull', 'legs']

export const MOVEMENT_PATTERN_LABELS: Record<MovementPattern, string> = {
  push: 'Push',
  pull: 'Pull',
  legs: 'Legs',
}

/** Distinct equipment strings present in the exercise library (stable sort). */
export const LIBRARY_EQUIPMENT_TYPES: string[] = Array.from(
  new Set(EXERCISE_LIBRARY.map((ex) => ex.equipment).filter((e): e is string => Boolean(e))),
).sort((a, b) => a.localeCompare(b))

const LEG_MUSCLES: MuscleGroup[] = ['quads', 'hamstrings', 'glutes', 'calves']

const FINISHER_TAGS = ['mobility', 'warm-up', 'recovery', 'stretch', 'cooldown', 'foam roll'] as const

const COMPOUND_MOVEMENT_TAGS = [
  'compound',
  'squat',
  'deadlift',
  'hinge',
  'oly lifting',
  'pull-up',
  'row',
  'press',
  'parallel bars',
] as const

function hasTag(ex: LibraryExercise, needle: string): boolean {
  return (ex.tags ?? []).some((t) => t.toLowerCase() === needle.toLowerCase())
}

function hasAnyTag(ex: LibraryExercise, needles: readonly string[]): boolean {
  return needles.some((n) => hasTag(ex, n))
}

/** Primary muscles for fatigue spacing (core treated as secondary when paired). */
export function primaryMuscleGroups(ex: LibraryExercise): MuscleGroup[] {
  const withoutCore = ex.muscleGroups.filter((m) => m !== 'core')
  return withoutCore.length > 0 ? withoutCore : ex.muscleGroups
}

export function muscleOverlap(a: LibraryExercise, b: LibraryExercise): number {
  const primary = new Set(primaryMuscleGroups(a))
  let overlap = 0
  for (const m of primaryMuscleGroups(b)) {
    if (primary.has(m)) overlap += 1
  }
  return overlap
}

/** Cardio, mobility, and recovery work belong at the end of the session. */
export function isSessionFinisher(ex: LibraryExercise): boolean {
  if (ex.isCardio) return true
  return hasAnyTag(ex, FINISHER_TAGS)
}

export function isCompoundLift(ex: LibraryExercise): boolean {
  if (ex.isCardio || isSessionFinisher(ex)) return false
  if (hasTag(ex, 'compound')) return true
  if (hasTag(ex, 'isolation')) return false

  if (primaryMuscleGroups(ex).length >= 2) return true

  const name = ex.name.toLowerCase()
  if (
    /\b(squat|deadlift|bench|press|row|pull-up|pullup|chin-up|lunge|rdl|thrust|clean|snatch|step-up)\b/.test(
      name,
    )
  ) {
    return true
  }
  if (COMPOUND_MOVEMENT_TAGS.some((t) => hasTag(ex, t))) return true
  if (/\b(curl|extension|fly|flye|raise|crunch|pushdown|kickback|pullover|plank)\b/.test(name)) {
    return false
  }

  return false
}

/**
 * Orders a fixed exercise list: compounds before isolation, finishers last,
 * and avoids back-to-back overlap on the same muscle groups.
 */
export function orderExercisesForSession(
  exercises: LibraryExercise[],
  random: () => number = Math.random,
): LibraryExercise[] {
  if (exercises.length <= 1) return [...exercises]

  const remaining = [...exercises]
  const ordered: LibraryExercise[] = []

  while (remaining.length > 0) {
    let bestIdx = 0
    let bestScore = -Infinity

    for (let i = 0; i < remaining.length; i++) {
      const ex = remaining[i]!
      const score = scoreExerciseOrderCandidate(ex, ordered, remaining, random)
      if (score > bestScore) {
        bestScore = score
        bestIdx = i
      }
    }

    ordered.push(remaining.splice(bestIdx, 1)[0]!)
  }

  return ordered
}

function scoreExerciseOrderCandidate(
  ex: LibraryExercise,
  ordered: LibraryExercise[],
  remaining: LibraryExercise[],
  random: () => number,
): number {
  let score = random() * 2

  const finisher = isSessionFinisher(ex)
  const mainStillAvailable = remaining.some((e) => e !== ex && !isSessionFinisher(e))

  if (finisher) {
    if (mainStillAvailable) score -= 80
    else score += ordered.length * 3
    if (ex.isCardio) score += ordered.length * 2
  } else if (isCompoundLift(ex)) {
    const compoundsLeft = remaining.filter((e) => !isSessionFinisher(e) && isCompoundLift(e)).length
    if (compoundsLeft > 0) score += 25
    score += Math.max(0, 18 - ordered.filter((e) => !isSessionFinisher(e)).length)
  } else {
    const compoundsLeft = remaining.filter((e) => !isSessionFinisher(e) && isCompoundLift(e)).length
    if (compoundsLeft > 0) score -= 22
    else score += 10
  }

  const last = ordered[ordered.length - 1]
  if (last) {
    const overlap = muscleOverlap(ex, last)
    score -= overlap * 14
    if (overlap > 0 && isCompoundLift(ex) && isCompoundLift(last)) score -= 10
    const lastPatterns = exerciseMovementPatterns(last)
    const exPatterns = exerciseMovementPatterns(ex)
    const sharesPattern = lastPatterns.some((p) => exPatterns.includes(p))
    if (overlap === 0 && !sharesPattern) score += 4
    else if (overlap === 0 && sharesPattern) score -= 2
  }

  const secondLast = ordered[ordered.length - 2]
  if (secondLast) score -= muscleOverlap(ex, secondLast) * 5

  return score
}

/**
 * Bro-split style movement tags derived from muscle groups and library tags.
 */
export function exerciseMovementPatterns(ex: LibraryExercise): MovementPattern[] {
  const mg = ex.muscleGroups
  const s = new Set<MovementPattern>()
  if (mg.some((m) => LEG_MUSCLES.includes(m))) s.add('legs')
  if (mg.includes('back') || mg.includes('biceps') || hasTag(ex, 'pull')) s.add('pull')
  if (mg.includes('chest') || mg.includes('triceps') || hasTag(ex, 'push')) s.add('push')
  if (
    mg.includes('shoulders') &&
    !mg.includes('back') &&
    !mg.includes('core') &&
    !mg.some((m) => LEG_MUSCLES.includes(m))
  ) {
    s.add('push')
  }
  return [...s]
}

export function exerciseMatchesEquipment(ex: LibraryExercise, selectedEquipment: string[]): boolean {
  if (selectedEquipment.length === 0) return false
  return Boolean(ex.equipment && selectedEquipment.includes(ex.equipment))
}

export function exerciseMatchesFocus(ex: LibraryExercise, selectedFocus: ShuffleFocus[]): boolean {
  if (selectedFocus.length === 0) return true
  const patterns = exerciseMovementPatterns(ex)
  for (const f of selectedFocus) {
    if (f === 'push' || f === 'pull' || f === 'legs') {
      if (patterns.includes(f)) return true
    } else if (ex.muscleGroups.includes(f)) {
      return true
    }
  }
  return false
}

export function filterLibraryForShuffle(
  selectedEquipment: string[],
  selectedFocus: ShuffleFocus[],
  includeCardio = false,
): LibraryExercise[] {
  return EXERCISE_LIBRARY.filter((ex) => {
    if (ex.isCardio && !includeCardio) return false
    return exerciseMatchesEquipment(ex, selectedEquipment) && exerciseMatchesFocus(ex, selectedFocus)
  })
}

function shuffleInPlace<T>(items: T[], random: () => number): void {
  for (let i = items.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1))
    const a = items[i]!
    const b = items[j]!
    items[i] = b
    items[j] = a
  }
}

function defaultSets(): TemplateExercise['sets'] {
  return [
    { targetReps: '8-12', targetWeight: '' },
    { targetReps: '8-12', targetWeight: '' },
    { targetReps: '8-12', targetWeight: '' },
  ]
}

export function libraryExerciseToTemplateExercise(
  ex: LibraryExercise,
  planKey: string,
  index: number,
): TemplateExercise {
  if (ex.isCardio) {
    return {
      id: `${planKey}__${ex.id}__${index}`,
      name: ex.name,
      libraryId: ex.id,
      isCardio: true,
      targetDuration: '30',
      sets: [{ targetReps: '30', targetWeight: '' }],
    }
  }
  return {
    id: `${planKey}__${ex.id}__${index}`,
    name: ex.name,
    libraryId: ex.id,
    sets: defaultSets(),
  }
}

export type ShuffleMode = 'duration' | 'count'

export type ShuffleParams = {
  selectedEquipment: string[]
  selectedFocus: ShuffleFocus[]
  includeCardio?: boolean
  mode: ShuffleMode
  /** Target minutes when mode === 'duration' */
  targetMinutes: number
  /** Number of unique exercises when mode === 'count' */
  exerciseCount: number
  durationAssumptions?: PlanDurationAssumptions
}

function emptyTemplate(id: string, name: string, exercises: TemplateExercise[]): WorkoutTemplate {
  return { id, name, exercises }
}

function estimateMinutes(
  template: WorkoutTemplate,
  assumptions: PlanDurationAssumptions = DEFAULT_PLAN_DURATION_ASSUMPTIONS,
): number {
  return estimatePlanDurationMinutes(template, assumptions)
}

function pickExercisesFromPool(
  pool: LibraryExercise[],
  params: ShuffleParams,
  draftId: string,
  random: () => number,
): LibraryExercise[] {
  const shuffled = [...pool]
  shuffleInPlace(shuffled, random)

  if (params.mode === 'count') {
    const n = Math.max(1, Math.floor(params.exerciseCount))
    return shuffled.slice(0, Math.min(n, shuffled.length))
  }

  const target = Math.max(5, Math.floor(params.targetMinutes))
  const assumptions = params.durationAssumptions ?? DEFAULT_PLAN_DURATION_ASSUMPTIONS
  const picked: LibraryExercise[] = []
  let i = 0
  for (const ex of shuffled) {
    const next = libraryExerciseToTemplateExercise(ex, draftId, i)
    const candidate = emptyTemplate(
      draftId,
      'Shuffled plan',
      [
        ...picked.map((p, j) => libraryExerciseToTemplateExercise(p, draftId, j)),
        next,
      ],
    )
    picked.push(ex)
    i += 1
    if (estimateMinutes(candidate, assumptions) >= target) break
  }
  return picked
}

/**
 * Builds a randomized plan from the library using the given constraints.
 * Exercises are picked at random, then ordered compounds → isolation with muscle-group spacing.
 */
export function buildShuffledPlan(params: ShuffleParams, random: () => number = Math.random): WorkoutTemplate {
  const pool = filterLibraryForShuffle(
    params.selectedEquipment,
    params.selectedFocus,
    params.includeCardio === true,
  )
  const draftId = `shuffle-${Date.now()}`
  const name = 'Shuffled plan'

  if (pool.length === 0) {
    return emptyTemplate(draftId, name, [])
  }

  const picked = pickExercisesFromPool(pool, params, draftId, random)
  const ordered = orderExercisesForSession(picked, random)
  const exercises = ordered.map((ex, i) => libraryExerciseToTemplateExercise(ex, draftId, i))

  return emptyTemplate(draftId, name, exercises)
}

export function formatFocusLabel(f: ShuffleFocus): string {
  if (f === 'push' || f === 'pull' || f === 'legs') return MOVEMENT_PATTERN_LABELS[f]
  return MUSCLE_GROUP_LABELS[f]
}

export function allMuscleGroups(): MuscleGroup[] {
  return [...MUSCLE_GROUPS]
}
