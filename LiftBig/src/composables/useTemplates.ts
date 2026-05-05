import { ref } from 'vue'
import type { WorkoutTemplate } from '@/types/workout'
import { DEFAULT_PLANS } from '@/utils/defaultPlans'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { saveJson } from '@/utils/storage'

const KEY = LIFTBIG_STORAGE_KEYS.templates

function clonePlans(plans: WorkoutTemplate[]): WorkoutTemplate[] {
  return JSON.parse(JSON.stringify(plans)) as WorkoutTemplate[]
}

function loadTemplatesInitial(): WorkoutTemplate[] {
  if (typeof localStorage === 'undefined') return clonePlans(DEFAULT_PLANS)
  const raw = localStorage.getItem(KEY)
  if (raw === null) {
    const seed = clonePlans(DEFAULT_PLANS)
    saveJson(KEY, seed)
    return seed
  }
  try {
    const parsed = JSON.parse(raw) as WorkoutTemplate[]
    if (!Array.isArray(parsed)) {
      const seed = clonePlans(DEFAULT_PLANS)
      saveJson(KEY, seed)
      return seed
    }
    return parsed
  } catch {
    const seed = clonePlans(DEFAULT_PLANS)
    saveJson(KEY, seed)
    return seed
  }
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
