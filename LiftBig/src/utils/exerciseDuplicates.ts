import { getDayExercises, type WorkoutLog } from '@/types/workout'
import { findLibraryExerciseByName } from '@/utils/exerciseLibrary'

export type DuplicateExerciseGroup = {
  /** Normalized key (trim + lowercase). */
  key: string
  /** Distinct spellings found in the log. */
  variants: string[]
  /** Library id when all variants resolve to the same exercise (or only one library match). */
  libraryId?: string
}

function canonicalVariant(names: string[]): string {
  const sorted = [...names].sort((a, b) => a.localeCompare(b))
  return sorted[0] ?? names[0]!
}

export function findDuplicateExerciseGroups(log: WorkoutLog): DuplicateExerciseGroup[] {
  const byKey = new Map<string, Set<string>>()

  for (const dayEntry of Object.values(log)) {
    for (const ex of getDayExercises(dayEntry)) {
      const raw = ex.name.trim()
      if (!raw) continue
      const key = raw.toLowerCase()
      if (!byKey.has(key)) byKey.set(key, new Set())
      byKey.get(key)!.add(raw)
    }
  }

  const out: DuplicateExerciseGroup[] = []
  for (const [key, variantsSet] of byKey) {
    const variants = [...variantsSet]
    if (variants.length <= 1) continue

    const libIds = new Set(
      variants
        .map((v) => findLibraryExerciseByName(v)?.id)
        .filter((id): id is string => !!id),
    )
    const libraryId = libIds.size === 1 ? [...libIds][0] : undefined

    out.push({ key, variants, libraryId })
  }

  out.sort((a, b) => canonicalVariant(a.variants).localeCompare(canonicalVariant(b.variants)))
  return out
}

/** Rename all matching variants to the canonical name across the log. */
export function mergeExerciseNameVariants(log: WorkoutLog, key: string, canonicalName: string): WorkoutLog {
  const target = canonicalName.trim()
  if (!target) return log

  const next: WorkoutLog = {}
  for (const [dateKey, dayEntry] of Object.entries(log)) {
    const exercises = getDayExercises(dayEntry).map((ex) => {
      const raw = ex.name.trim()
      if (!raw || raw.toLowerCase() !== key) return ex
      return { ...ex, name: target }
    })

    if (Array.isArray(dayEntry)) {
      next[dateKey] = exercises
    } else {
      next[dateKey] = { ...dayEntry, exercises }
    }
  }
  return next
}
