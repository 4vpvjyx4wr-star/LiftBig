import type { LibraryExercise, MuscleGroup } from '@/utils/exerciseLibrary'
import { EXERCISE_LIBRARY, MUSCLE_GROUPS, MUSCLE_GROUP_LABELS } from '@/utils/exerciseLibrary'
import type { TemplateExercise, WorkoutTemplate } from '@/types/workout'
import { estimatePlanDurationMinutes } from '@/utils/planDuration'

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

function hasTag(ex: LibraryExercise, needle: string): boolean {
  return (ex.tags ?? []).some((t) => t.toLowerCase() === needle.toLowerCase())
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
): LibraryExercise[] {
  return EXERCISE_LIBRARY.filter(
    (ex) => exerciseMatchesEquipment(ex, selectedEquipment) && exerciseMatchesFocus(ex, selectedFocus),
  )
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
  mode: ShuffleMode
  /** Target minutes when mode === 'duration' */
  targetMinutes: number
  /** Number of unique exercises when mode === 'count' */
  exerciseCount: number
}

function emptyTemplate(id: string, name: string, exercises: TemplateExercise[]): WorkoutTemplate {
  return { id, name, exercises }
}

function estimateMinutes(template: WorkoutTemplate): number {
  return estimatePlanDurationMinutes(template)
}

/**
 * Builds a randomized plan from the library using the given constraints.
 */
export function buildShuffledPlan(params: ShuffleParams, random: () => number = Math.random): WorkoutTemplate {
  const pool = filterLibraryForShuffle(params.selectedEquipment, params.selectedFocus)
  const draftId = `shuffle-${Date.now()}`
  const name = 'Shuffled plan'

  if (pool.length === 0) {
    return emptyTemplate(draftId, name, [])
  }

  const shuffled = [...pool]
  shuffleInPlace(shuffled, random)

  if (params.mode === 'count') {
    const n = Math.max(1, Math.floor(params.exerciseCount))
    const picked = shuffled.slice(0, Math.min(n, shuffled.length))
    const exercises = picked.map((ex, i) => libraryExerciseToTemplateExercise(ex, draftId, i))
    return emptyTemplate(draftId, name, exercises)
  }

  const target = Math.max(5, Math.floor(params.targetMinutes))
  const exercises: TemplateExercise[] = []
  let i = 0
  for (const ex of shuffled) {
    const next = libraryExerciseToTemplateExercise(ex, draftId, i)
    const candidate = emptyTemplate(draftId, name, [...exercises, next])
    exercises.push(next)
    i += 1
    if (estimateMinutes(candidate) >= target) break
  }

  return emptyTemplate(draftId, name, exercises)
}

export function formatFocusLabel(f: ShuffleFocus): string {
  if (f === 'push' || f === 'pull' || f === 'legs') return MOVEMENT_PATTERN_LABELS[f]
  return MUSCLE_GROUP_LABELS[f]
}

export function allMuscleGroups(): MuscleGroup[] {
  return [...MUSCLE_GROUPS]
}
