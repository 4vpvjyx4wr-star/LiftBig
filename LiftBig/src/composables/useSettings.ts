import { ref, watch } from 'vue'
import {
  LIFTBIG_LEGACY_STORAGE_KEY_ALIASES,
  LIFTBIG_STORAGE_KEYS,
} from '@/utils/liftbigStorageKeys'
import { loadJsonWithRecovery, saveJson } from '@/utils/storage'
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
  | 'voltage'
  | 'dragonfruit'
  | 'glacier'
  | 'lavaflow'
  | 'nebula'
  | 'toxic'
  | 'sapphire'
  | 'mango'
  | 'prism'
  | 'blacklight'
  | 'mintchip'
  | 'ember'
  | 'tidal'
  | 'royal'
  | 'cottoncandy'
  | 'bloodmoon'
  | 'solarflare'
  | 'retrowave'
  | 'jungle'
  | 'titanium'

export type AppSettings = {
  theme: ThemeId
  weightUnit: WeightUnit
  averageRestSeconds: number
  averageLiftSeconds: number
}

export const DEFAULT_SETTINGS: AppSettings = {
  theme: 'default',
  weightUnit: 'lb',
  averageRestSeconds: 60,
  averageLiftSeconds: 60,
}

const MIN_AVERAGE_SECONDS = 5
const MAX_AVERAGE_SECONDS = 600

function sanitizeAverageSeconds(value: number, fallback: number): number {
  if (!Number.isFinite(value)) return fallback
  return Math.min(MAX_AVERAGE_SECONDS, Math.max(MIN_AVERAGE_SECONDS, Math.round(value)))
}

export const THEME_OPTIONS: { id: ThemeId; label: string }[] = [
  { id: 'default', label: 'LiftBig (orange)' },
  { id: 'forest', label: 'Forest' },
  { id: 'violet', label: 'Violet' },
  { id: 'sunset', label: 'Sunset' },
  { id: 'loud', label: 'Loud' },
  { id: 'cyberpunk', label: 'Cyberpunk' },
  { id: 'iron', label: 'Iron & Steel' },
  { id: 'caffeine', label: 'Caffeine molecule' },
  { id: 'aurora', label: 'Aurora' },
  { id: 'bubblegum', label: 'Bubblegum' },
  { id: 'midnight', label: 'Midnight sky' },
  { id: 'sandstorm', label: 'Sandstorm' },
  { id: 'cherrylime', label: 'Cherry lime' },
  { id: 'terminal', label: 'Terminal' },
  { id: 'disco', label: 'Disco' },
  { id: 'ocean', label: 'Ocean depths' },
  { id: 'voltage', label: 'Voltage Surge' },
  { id: 'dragonfruit', label: 'Dragonfruit Punch' },
  { id: 'glacier', label: 'Glacier Glow' },
  { id: 'lavaflow', label: 'Lava Flow' },
  { id: 'nebula', label: 'Cosmic Nebula' },
  { id: 'toxic', label: 'Toxic Limeade' },
  { id: 'sapphire', label: 'Sapphire Storm' },
  { id: 'mango', label: 'Mango Tango' },
  { id: 'prism', label: 'Prism Pop' },
  { id: 'blacklight', label: 'Blacklight Blitz' },
  { id: 'mintchip', label: 'Mint Chip' },
  { id: 'ember', label: 'Ember Arcade' },
  { id: 'tidal', label: 'Tidal Wave' },
  { id: 'royal', label: 'Royal Crush' },
  { id: 'cottoncandy', label: 'Cotton Candy Sky' },
  { id: 'bloodmoon', label: 'Blood Moon' },
  { id: 'solarflare', label: 'Solar Flare' },
  { id: 'retrowave', label: 'Retrowave' },
  { id: 'jungle', label: 'Jungle Fever' },
  { id: 'titanium', label: 'Titanium' },
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
  const loaded = loadJsonWithRecovery<AppSettings>(STORAGE_KEY, DEFAULT_SETTINGS, {
    legacyKeys: LIFTBIG_LEGACY_STORAGE_KEY_ALIASES.settings,
  })
  const theme = ref<ThemeId>(loaded.theme ?? DEFAULT_SETTINGS.theme)
  const weightUnit = ref<WeightUnit>(loaded.weightUnit ?? DEFAULT_SETTINGS.weightUnit)
  const averageRestSeconds = ref<number>(
    sanitizeAverageSeconds(loaded.averageRestSeconds, DEFAULT_SETTINGS.averageRestSeconds),
  )
  const averageLiftSeconds = ref<number>(
    sanitizeAverageSeconds(loaded.averageLiftSeconds, DEFAULT_SETTINGS.averageLiftSeconds),
  )

  function persist() {
    saveJson(STORAGE_KEY, {
      theme: theme.value,
      weightUnit: weightUnit.value,
      averageRestSeconds: sanitizeAverageSeconds(
        averageRestSeconds.value,
        DEFAULT_SETTINGS.averageRestSeconds,
      ),
      averageLiftSeconds: sanitizeAverageSeconds(
        averageLiftSeconds.value,
        DEFAULT_SETTINGS.averageLiftSeconds,
      ),
    })
  }

  watch(
    [theme, weightUnit, averageRestSeconds, averageLiftSeconds],
    () => {
      averageRestSeconds.value = sanitizeAverageSeconds(
        averageRestSeconds.value,
        DEFAULT_SETTINGS.averageRestSeconds,
      )
      averageLiftSeconds.value = sanitizeAverageSeconds(
        averageLiftSeconds.value,
        DEFAULT_SETTINGS.averageLiftSeconds,
      )
      persist()
      applyTheme(theme.value)
    },
    { flush: 'post' },
  )

  applyTheme(theme.value)

  return {
    theme,
    weightUnit,
    averageRestSeconds,
    averageLiftSeconds,
    setTheme(id: ThemeId) {
      theme.value = id
    },
    setWeightUnit(u: WeightUnit) {
      weightUnit.value = u
    },
    setAverageRestSeconds(value: number) {
      averageRestSeconds.value = sanitizeAverageSeconds(value, DEFAULT_SETTINGS.averageRestSeconds)
    },
    setAverageLiftSeconds(value: number) {
      averageLiftSeconds.value = sanitizeAverageSeconds(value, DEFAULT_SETTINGS.averageLiftSeconds)
    },
  }
}

export type SettingsApi = ReturnType<typeof useSettings>
