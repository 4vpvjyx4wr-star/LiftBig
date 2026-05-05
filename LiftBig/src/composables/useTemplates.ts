import { ref } from 'vue'
import type { WorkoutTemplate } from '@/types/workout'
import { DEFAULT_PLANS } from '@/utils/defaultPlans'
import { LIFTBIG_LEGACY_STORAGE_KEY_ALIASES, LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { loadJsonWithRecovery, saveJson } from '@/utils/storage'

const KEY = LIFTBIG_STORAGE_KEYS.templates

function clonePlans(plans: WorkoutTemplate[]): WorkoutTemplate[] {
  return JSON.parse(JSON.stringify(plans)) as WorkoutTemplate[]
}

function loadTemplatesInitial(): WorkoutTemplate[] {
  const loaded = loadJsonWithRecovery<unknown>(KEY, null, {
    legacyKeys: LIFTBIG_LEGACY_STORAGE_KEY_ALIASES.templates,
  })
  if (loaded === null) {
    const seed = clonePlans(DEFAULT_PLANS)
    saveJson(KEY, seed)
    return seed
  }
  if (!Array.isArray(loaded)) {
    const seed = clonePlans(DEFAULT_PLANS)
    saveJson(KEY, seed)
    return seed
  }
  return loaded as WorkoutTemplate[]
}

export function useTemplates() {
  const templates = ref<WorkoutTemplate[]>(loadTemplatesInitial())

  function persist() {
    saveJson(KEY, templates.value)
  }

  function setAll(next: WorkoutTemplate[]) {
    templates.value = next
    persist()
  }

  return {
    templates,
    persist,
    setAll,
  }
}
