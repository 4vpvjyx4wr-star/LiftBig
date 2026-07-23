import { ref } from 'vue'

export type ExerciseAsset = {
  id: string
  name: string
  /** Empty string or null when no static illustration should be shown. */
  thumbnail: string | null
  animation: string | null
  primaryMuscles: string[]
  secondaryMuscles: string[]
  source?: string
  licenseNote?: string
}

const assetsById = ref<Map<string, ExerciseAsset>>(new Map())
let loadPromise: Promise<void> | null = null

async function loadExerciseAssets(): Promise<void> {
  if (assetsById.value.size > 0) return
  if (loadPromise) return loadPromise

  loadPromise = (async () => {
    try {
      const res = await fetch('/data/exercise_assets.json', { cache: 'no-cache' })
      if (!res.ok) {
        loadPromise = null
        return
      }
      const list = (await res.json()) as ExerciseAsset[]
      const map = new Map<string, ExerciseAsset>()
      for (const entry of list) {
        if (entry?.id) map.set(entry.id, entry)
      }
      assetsById.value = map
    } catch {
      loadPromise = null
    }
  })()

  return loadPromise
}

/** Ensure the manifest is loaded, then return the asset for a library exercise id. */
export async function ensureExerciseAsset(libraryId: string): Promise<ExerciseAsset | null> {
  await loadExerciseAssets()
  return assetsById.value.get(libraryId) ?? null
}

export function getExerciseAsset(libraryId: string): ExerciseAsset | null {
  return assetsById.value.get(libraryId) ?? null
}

/** Kick off a background load (call once from app bootstrap or first sheet open). */
export function prefetchExerciseAssets(): void {
  void loadExerciseAssets()
}
