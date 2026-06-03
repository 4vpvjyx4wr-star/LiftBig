import { ref, watch } from 'vue'
import {
  LIFTBIG_LEGACY_STORAGE_KEY_ALIASES,
  LIFTBIG_STORAGE_KEYS,
} from '@/utils/liftbigStorageKeys'
import { loadJsonWithRecovery, saveJson } from '@/utils/storage'
import type { DistanceUnit } from '@/utils/distances'
import { isDistanceUnit } from '@/utils/distances'
import type { WeightUnit } from '@/utils/units'
import {
  applyActiveTheme,
  clonePalette,
  customThemeRef,
  DEFAULT_THEME_PALETTE,
  isCustomThemeRef,
  newCustomThemeId,
  parseCustomThemeId,
  sanitizeCustomThemes,
  type CustomTheme,
  type ThemePalette,
} from '@/utils/themePalette'

const STORAGE_KEY = LIFTBIG_STORAGE_KEYS.settings
const CUSTOM_THEMES_KEY = LIFTBIG_STORAGE_KEYS.customThemes

export type ThemeId =
  | 'default'
  | 'forest'
  | 'violet'
  | 'sunset'
  | 'loud'
  | 'cyberpunk'
  | 'iron'
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
  | 'mintchip'
  | 'tidal'
  | 'cottoncandy'
  | 'bloodmoon'
  | 'retrowave'
  | 'titanium'

export type AppSettings = {
  /** Preset theme id or `custom:<uuid>` */
  theme: string
  weightUnit: WeightUnit
  distanceUnit: DistanceUnit
  averageRestSeconds: number
  averageLiftSeconds: number
  /** Body weight in pounds; used for calorie estimates. 0 = not set. */
  bodyWeightLbs: number
}

export const DEFAULT_SETTINGS: AppSettings = {
  theme: 'default',
  weightUnit: 'lb',
  distanceUnit: 'mi',
  averageRestSeconds: 60,
  averageLiftSeconds: 60,
  bodyWeightLbs: 0,
}

const MIN_AVERAGE_SECONDS = 5
const MAX_AVERAGE_SECONDS = 600

function sanitizeAverageSeconds(value: number, fallback: number): number {
  if (!Number.isFinite(value)) return fallback
  return Math.min(MAX_AVERAGE_SECONDS, Math.max(MIN_AVERAGE_SECONDS, Math.round(value)))
}

const MIN_BODY_WEIGHT_LBS = 50
const MAX_BODY_WEIGHT_LBS = 700

function sanitizeBodyWeightLbs(value: number): number {
  if (!Number.isFinite(value) || value <= 0) return 0
  return Math.min(MAX_BODY_WEIGHT_LBS, Math.max(MIN_BODY_WEIGHT_LBS, Math.round(value * 10) / 10))
}

export const THEME_OPTIONS: { id: ThemeId; label: string }[] = [
  { id: 'default', label: 'LiftBig (orange)' },
  { id: 'forest', label: 'Forest' },
  { id: 'violet', label: 'Violet' },
  { id: 'sunset', label: 'Sunset' },
  { id: 'loud', label: 'Loud' },
  { id: 'cyberpunk', label: 'Cyberpunk' },
  { id: 'iron', label: 'Iron & Steel' },
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
  { id: 'mintchip', label: 'Mint Chip' },
  { id: 'tidal', label: 'Tidal Wave' },
  { id: 'cottoncandy', label: 'Cotton Candy Sky' },
  { id: 'bloodmoon', label: 'Blood Moon' },
  { id: 'retrowave', label: 'Retrowave' },
  { id: 'titanium', label: 'Titanium' },
]

const VALID_PRESET_THEME_IDS = new Set<string>(THEME_OPTIONS.map((o) => o.id))

export function isPresetThemeId(value: string): value is ThemeId {
  return VALID_PRESET_THEME_IDS.has(value)
}

export function sanitizeActiveTheme(value: unknown, customThemes: CustomTheme[]): string {
  if (typeof value !== 'string') return DEFAULT_SETTINGS.theme
  if (isPresetThemeId(value)) return value
  if (isCustomThemeRef(value)) {
    const id = parseCustomThemeId(value)
    if (id && customThemes.some((t) => t.id === id)) return value
  }
  return DEFAULT_SETTINGS.theme
}

export type { CustomTheme, ThemePalette }
export { DEFAULT_THEME_PALETTE, clonePalette, customThemeRef, isCustomThemeRef }

export function useSettings() {
  const loadedCustom = loadJsonWithRecovery<CustomTheme[]>(CUSTOM_THEMES_KEY, [], {
    legacyKeys: [],
  })
  const customThemes = ref<CustomTheme[]>(sanitizeCustomThemes(loadedCustom))

  const loaded = loadJsonWithRecovery<AppSettings>(STORAGE_KEY, DEFAULT_SETTINGS, {
    legacyKeys: LIFTBIG_LEGACY_STORAGE_KEY_ALIASES.settings,
  })
  const theme = ref<string>(sanitizeActiveTheme(loaded.theme, customThemes.value))
  const weightUnit = ref<WeightUnit>(loaded.weightUnit ?? DEFAULT_SETTINGS.weightUnit)
  const distanceUnit = ref<DistanceUnit>(
    isDistanceUnit(loaded.distanceUnit) ? loaded.distanceUnit : DEFAULT_SETTINGS.distanceUnit,
  )
  const averageRestSeconds = ref<number>(
    sanitizeAverageSeconds(loaded.averageRestSeconds, DEFAULT_SETTINGS.averageRestSeconds),
  )
  const averageLiftSeconds = ref<number>(
    sanitizeAverageSeconds(loaded.averageLiftSeconds, DEFAULT_SETTINGS.averageLiftSeconds),
  )
  const bodyWeightLbs = ref<number>(sanitizeBodyWeightLbs(loaded.bodyWeightLbs ?? 0))

  function persistSettings() {
    saveJson(STORAGE_KEY, {
      theme: theme.value,
      weightUnit: weightUnit.value,
      distanceUnit: distanceUnit.value,
      averageRestSeconds: sanitizeAverageSeconds(
        averageRestSeconds.value,
        DEFAULT_SETTINGS.averageRestSeconds,
      ),
      averageLiftSeconds: sanitizeAverageSeconds(
        averageLiftSeconds.value,
        DEFAULT_SETTINGS.averageLiftSeconds,
      ),
      bodyWeightLbs: sanitizeBodyWeightLbs(bodyWeightLbs.value),
    })
  }

  function persistCustomThemes() {
    saveJson(CUSTOM_THEMES_KEY, customThemes.value)
  }

  function syncActiveTheme() {
    applyActiveTheme(theme.value, customThemes.value)
  }

  watch(
    [theme, weightUnit, distanceUnit, averageRestSeconds, averageLiftSeconds, bodyWeightLbs],
    () => {
      averageRestSeconds.value = sanitizeAverageSeconds(
        averageRestSeconds.value,
        DEFAULT_SETTINGS.averageRestSeconds,
      )
      averageLiftSeconds.value = sanitizeAverageSeconds(
        averageLiftSeconds.value,
        DEFAULT_SETTINGS.averageLiftSeconds,
      )
      bodyWeightLbs.value = sanitizeBodyWeightLbs(bodyWeightLbs.value)
      persistSettings()
      syncActiveTheme()
    },
    { flush: 'post' },
  )

  watch(
    customThemes,
    () => {
      theme.value = sanitizeActiveTheme(theme.value, customThemes.value)
      persistCustomThemes()
      syncActiveTheme()
    },
    { deep: true, flush: 'post' },
  )

  syncActiveTheme()

  function setTheme(id: string) {
    theme.value = sanitizeActiveTheme(id, customThemes.value)
  }

  function addCustomTheme(name: string, colors: ThemePalette): CustomTheme {
    const trimmed = name.trim().slice(0, 48) || 'Custom theme'
    const created: CustomTheme = {
      id: newCustomThemeId(),
      name: trimmed,
      colors: clonePalette(colors),
    }
    customThemes.value = [...customThemes.value, created]
    theme.value = customThemeRef(created.id)
    return created
  }

  function updateCustomTheme(id: string, name: string, colors: ThemePalette) {
    const trimmed = name.trim().slice(0, 48) || 'Custom theme'
    customThemes.value = customThemes.value.map((t) =>
      t.id === id ? { ...t, name: trimmed, colors: clonePalette(colors) } : t,
    )
  }

  function deleteCustomTheme(id: string) {
    customThemes.value = customThemes.value.filter((t) => t.id !== id)
    if (theme.value === customThemeRef(id)) {
      theme.value = DEFAULT_SETTINGS.theme
    }
  }

  return {
    theme,
    customThemes,
    weightUnit,
    distanceUnit,
    averageRestSeconds,
    averageLiftSeconds,
    bodyWeightLbs,
    setTheme,
    addCustomTheme,
    updateCustomTheme,
    deleteCustomTheme,
    setWeightUnit(u: WeightUnit) {
      weightUnit.value = u
    },
    setDistanceUnit(u: DistanceUnit) {
      distanceUnit.value = u
    },
    setAverageRestSeconds(value: number) {
      averageRestSeconds.value = sanitizeAverageSeconds(value, DEFAULT_SETTINGS.averageRestSeconds)
    },
    setAverageLiftSeconds(value: number) {
      averageLiftSeconds.value = sanitizeAverageSeconds(value, DEFAULT_SETTINGS.averageLiftSeconds)
    },
    setBodyWeightLbs(value: number) {
      bodyWeightLbs.value = sanitizeBodyWeightLbs(value)
    },
  }
}

export type SettingsApi = ReturnType<typeof useSettings>
