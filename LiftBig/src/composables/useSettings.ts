import { ref, watch } from 'vue'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { loadJson, saveJson } from '@/utils/storage'
import type { WeightUnit } from '@/utils/units'

const STORAGE_KEY = LIFTBIG_STORAGE_KEYS.settings

export type ThemeId =
  | 'default'
  | 'forest'
  | 'violet'
  | 'sunset'
  | 'loud'
  | 'cyberpunk'
  | 'iron'
  | 'caffeine'
  | 'aurora'
  | 'bubblegum'
  | 'midnight'
  | 'sandstorm'
  | 'cherrylime'
  | 'terminal'
  | 'disco'
  | 'ocean'

export type AppSettings = {
  theme: ThemeId
  weightUnit: WeightUnit
}

export const DEFAULT_SETTINGS: AppSettings = {
  theme: 'default',
  weightUnit: 'lb',
}

export const THEME_OPTIONS: { id: ThemeId; label: string }[] = [
  { id: 'default', label: 'LiftBig (orange)' },
  { id: 'forest', label: 'Forest' },
  { id: 'violet', label: 'Violet' },
  { id: 'sunset', label: 'Sunset' },
  { id: 'loud', label: 'Loud' },
  { id: 'cyberpunk', label: 'Cyberpunk' },
  { id: 'iron', label: 'Iron & steel (gym floor)' },
  { id: 'caffeine', label: 'Caffeine molecule' },
  { id: 'aurora', label: 'Aurora' },
  { id: 'bubblegum', label: 'Bubblegum' },
  { id: 'midnight', label: 'Midnight sky' },
  { id: 'sandstorm', label: 'Sandstorm' },
  { id: 'cherrylime', label: 'Cherry lime' },
  { id: 'terminal', label: 'Terminal' },
  { id: 'disco', label: 'Disco' },
  { id: 'ocean', label: 'Ocean depths' },
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
