import { ref, watch } from 'vue'
import { loadJson, saveJson } from '@/utils/storage'
import type { WeightUnit } from '@/utils/units'

const STORAGE_KEY = 'liftbig_settings'

export type ThemeId = 'default' | 'forest' | 'violet' | 'sunset'

export type AppSettings = {
  theme: ThemeId
  weightUnit: WeightUnit
}

const DEFAULT_SETTINGS: AppSettings = {
  theme: 'default',
  weightUnit: 'lb',
}

export const THEME_OPTIONS: { id: ThemeId; label: string }[] = [
  { id: 'default', label: 'LiftBig (orange)' },
  { id: 'forest', label: 'Forest' },
  { id: 'violet', label: 'Violet' },
  { id: 'sunset', label: 'Sunset' },
]

function applyTheme(theme: ThemeId) {
  if (typeof document === 'undefined') return
  const el = document.documentElement
  if (theme === 'default') {
    delete el.dataset.theme
  } else {
    el.dataset.theme = theme
  }
}

export function useSettings() {
  const loaded = loadJson<AppSettings>(STORAGE_KEY, DEFAULT_SETTINGS)
  const theme = ref<ThemeId>(loaded.theme ?? DEFAULT_SETTINGS.theme)
  const weightUnit = ref<WeightUnit>(loaded.weightUnit ?? DEFAULT_SETTINGS.weightUnit)

  function persist() {
    saveJson(STORAGE_KEY, { theme: theme.value, weightUnit: weightUnit.value })
  }

  watch(
    [theme, weightUnit],
    () => {
      persist()
      applyTheme(theme.value)
    },
    { flush: 'post' },
  )

  applyTheme(theme.value)

  return {
    theme,
    weightUnit,
    setTheme(id: ThemeId) {
      theme.value = id
    },
    setWeightUnit(u: WeightUnit) {
      weightUnit.value = u
    },
  }
}

export type SettingsApi = ReturnType<typeof useSettings>
