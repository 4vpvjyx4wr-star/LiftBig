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
  /** Daily "lift big" reminder at a chosen local time. */
  dailyLiftReminderEnabled: boolean
  /** Local time as HH:MM (24h). */
  dailyLiftReminderTime: string
  /** Double-tap reps or weight field to copy previous set's value. */
  doubleTapCopyWeight: boolean
  /** After logging reps, focus the next set's weight field. */
  autoAdvanceRepsToWeight: boolean
  /** Short sound when rest timer completes. */
  timerSoundEnabled: boolean
  /** Selected equipment filters for library/swap (empty = show all). */
  equipmentFilterPrefs: string[]
}

export const DEFAULT_SETTINGS: AppSettings = {
  theme: 'default',
  weightUnit: 'lb',
  distanceUnit: 'mi',
  averageRestSeconds: 60,
  averageLiftSeconds: 60,
  bodyWeightLbs: 0,
  dailyLiftReminderEnabled: false,
  dailyLiftReminderTime: '17:00',
  doubleTapCopyWeight: true,
  autoAdvanceRepsToWeight: true,
  timerSoundEnabled: true,
  equipmentFilterPrefs: [],
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

const REMINDER_TIME_RE = /^([01]?\d|2[0-3]):([0-5]\d)$/

function sanitizeReminderTime(value: unknown): string {
  if (typeof value !== 'string') return DEFAULT_SETTINGS.dailyLiftReminderTime
  const t = value.trim()
  if (!REMINDER_TIME_RE.test(t)) return DEFAULT_SETTINGS.dailyLiftReminderTime
  const [h, m] = t.split(':')
  return `${String(Number(h)).padStart(2, '0')}:${m}`
}

function sanitizeEquipmentFilterPrefs(value: unknown): string[] {
  if (!Array.isArray(value)) return []
  const out: string[] = []
  for (const item of value) {
    if (typeof item !== 'string') continue
    const t = item.trim()
    if (t && !out.includes(t)) out.push(t)
  }
  return out
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
  const dailyLiftReminderEnabled = ref<boolean>(
    loaded.dailyLiftReminderEnabled === true,
  )
  const dailyLiftReminderTime = ref<string>(
    sanitizeReminderTime(loaded.dailyLiftReminderTime),
  )
  const doubleTapCopyWeight = ref<boolean>(
    loaded.doubleTapCopyWeight !== false,
  )
  const autoAdvanceRepsToWeight = ref<boolean>(
    loaded.autoAdvanceRepsToWeight !== false,
  )
  const timerSoundEnabled = ref<boolean>(loaded.timerSoundEnabled !== false)
  const equipmentFilterPrefs = ref<string[]>(
    sanitizeEquipmentFilterPrefs(loaded.equipmentFilterPrefs),
  )

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
      dailyLiftReminderEnabled: dailyLiftReminderEnabled.value,
      dailyLiftReminderTime: sanitizeReminderTime(dailyLiftReminderTime.value),
      doubleTapCopyWeight: doubleTapCopyWeight.value,
      autoAdvanceRepsToWeight: autoAdvanceRepsToWeight.value,
      timerSoundEnabled: timerSoundEnabled.value,
      equipmentFilterPrefs: sanitizeEquipmentFilterPrefs(equipmentFilterPrefs.value),
    })
  }

  function persistCustomThemes() {
    saveJson(CUSTOM_THEMES_KEY, customThemes.value)
  }

  function syncActiveTheme() {
    applyActiveTheme(theme.value, customThemes.value)
  }

  watch(
    [
      theme,
      weightUnit,
      distanceUnit,
      averageRestSeconds,
      averageLiftSeconds,
      bodyWeightLbs,
      dailyLiftReminderEnabled,
      dailyLiftReminderTime,
      doubleTapCopyWeight,
      autoAdvanceRepsToWeight,
      timerSoundEnabled,
      equipmentFilterPrefs,
    ],
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
    dailyLiftReminderEnabled,
    dailyLiftReminderTime,
    doubleTapCopyWeight,
    autoAdvanceRepsToWeight,
    timerSoundEnabled,
    equipmentFilterPrefs,
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
    setDailyLiftReminderEnabled(enabled: boolean) {
      dailyLiftReminderEnabled.value = enabled
    },
    setDailyLiftReminderTime(time: string) {
      dailyLiftReminderTime.value = sanitizeReminderTime(time)
    },
    setDoubleTapCopyWeight(enabled: boolean) {
      doubleTapCopyWeight.value = enabled
    },
    setAutoAdvanceRepsToWeight(enabled: boolean) {
      autoAdvanceRepsToWeight.value = enabled
    },
    setTimerSoundEnabled(enabled: boolean) {
      timerSoundEnabled.value = enabled
    },
    toggleEquipmentFilter(equipment: string) {
      const key = equipment.trim()
      if (!key) return
      const cur = equipmentFilterPrefs.value
      equipmentFilterPrefs.value = cur.includes(key)
        ? cur.filter((e) => e !== key)
        : [...cur, key]
    },
    clearEquipmentFilters() {
      equipmentFilterPrefs.value = []
    },
  }
}

export type SettingsApi = ReturnType<typeof useSettings>
