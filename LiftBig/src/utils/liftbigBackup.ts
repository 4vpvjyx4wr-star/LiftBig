import { DEFAULT_SETTINGS, sanitizeActiveTheme, type AppSettings } from '@/composables/useSettings'
import { type WorkoutDay, type WorkoutLog, type WorkoutTemplate } from '@/types/workout'
import { isDistanceUnit } from '@/utils/distances'
import { sanitizeCustomThemes, type CustomTheme } from '@/utils/themePalette'
import type { WeightUnit } from '@/utils/units'
import {
  applyLiftbigRawStorageSnapshot,
  clearLiftbigPrefixedStorage,
  collectLiftbigRawStorageSnapshot,
  LIFTBIG_KEY_PREFIX,
  LIFTBIG_STORAGE_KEYS,
  warnUnknownLiftbigKeysInSnapshot,
} from '@/utils/liftbigStorageKeys'

/** Re-export registry for callers that branch on persisted keys */
export {
  LIFTBIG_KEY_PREFIX,
  LIFTBIG_STORAGE_KEYS,
  REGISTERED_LIFTBIG_STORAGE_KEYS,
} from '@/utils/liftbigStorageKeys'

/** Bump when backup JSON shape changes in a breaking way */
export const LIFTBIG_BACKUP_FORMAT_VERSION = 2

export type LiftBigBackupFile = {
  formatVersion: number
  exportedAt: string
  app: string
  /**
   * Authoritative mirror: every localStorage key starting with `liftbig_` and its raw string value.
   * Ensures forward compatibility for keys not yet listed in `LIFTBIG_STORAGE_KEYS`.
   */
  liftbig_local_storage: Record<string, string>
  /** Parsed views of registered keys — for UI and legacy consumers */
  liftbig_workouts: WorkoutLog
  liftbig_templates: WorkoutTemplate[]
  liftbig_settings: AppSettings
  liftbig_custom_themes: CustomTheme[]
}


function isWeightUnit(v: unknown): v is WeightUnit {
  return v === 'lb' || v === 'kg'
}

function normalizeAverageSeconds(v: unknown, fallback: number): number {
  if (typeof v !== 'number' || !Number.isFinite(v)) return fallback
  return Math.min(600, Math.max(5, Math.round(v)))
}

function normalizeSettings(raw: unknown, customThemes: CustomTheme[] = []): AppSettings {
  if (!raw || typeof raw !== 'object') return { ...DEFAULT_SETTINGS }
  const o = raw as Record<string, unknown>
  const theme = sanitizeActiveTheme(o.theme, customThemes)
  const weightUnit = isWeightUnit(o.weightUnit) ? o.weightUnit : DEFAULT_SETTINGS.weightUnit
  const distanceUnit = isDistanceUnit(o.distanceUnit) ? o.distanceUnit : DEFAULT_SETTINGS.distanceUnit
  const averageRestSeconds = normalizeAverageSeconds(
    o.averageRestSeconds,
    DEFAULT_SETTINGS.averageRestSeconds,
  )
  const averageLiftSeconds = normalizeAverageSeconds(
    o.averageLiftSeconds,
    DEFAULT_SETTINGS.averageLiftSeconds,
  )
  const rawBody = o.bodyWeightLbs
  const bodyWeightLbs =
    typeof rawBody === 'number' && Number.isFinite(rawBody) && rawBody > 0 ? rawBody : 0
  return { theme, weightUnit, distanceUnit, averageRestSeconds, averageLiftSeconds, bodyWeightLbs }
}

function normalizeTemplates(raw: unknown): WorkoutTemplate[] {
  const rawTemplates =
    Array.isArray(raw)
      ? raw
      : raw && typeof raw === 'object' && Array.isArray((raw as { templates?: unknown }).templates)
        ? ((raw as { templates: unknown[] }).templates ?? [])
        : []

  return rawTemplates.filter(
    (t): t is WorkoutTemplate =>
      t != null &&
      typeof t === 'object' &&
      typeof (t as WorkoutTemplate).id === 'string' &&
      typeof (t as WorkoutTemplate).name === 'string' &&
      Array.isArray((t as WorkoutTemplate).exercises),
  )
}

function normalizeWorkouts(raw: unknown): WorkoutLog {
  if (!raw || typeof raw !== 'object') return {}
  const out: WorkoutLog = {}
  for (const [dateKey, dayEntry] of Object.entries(raw as Record<string, unknown>)) {
    const rawExercises = Array.isArray(dayEntry)
      ? dayEntry
      : dayEntry && typeof dayEntry === 'object'
        ? (dayEntry as { exercises?: unknown }).exercises
        : undefined
    if (!Array.isArray(rawExercises)) continue
    const exercises = rawExercises.filter(
      (ex) =>
        ex != null &&
        typeof ex === 'object' &&
        typeof (ex as { id?: unknown }).id === 'string' &&
        typeof (ex as { name?: unknown }).name === 'string' &&
        Array.isArray((ex as { sets?: unknown }).sets),
    ) as WorkoutDay['exercises']
    const notes =
      dayEntry && typeof dayEntry === 'object' && typeof (dayEntry as { notes?: unknown }).notes === 'string'
        ? (dayEntry as { notes: string }).notes
        : undefined
    out[dateKey] = { exercises, ...(notes !== undefined ? { notes } : {}) }
  }
  return out
}

function coerceBundleFromUnknown(raw: unknown): Record<string, string> | undefined {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return undefined
  const out: Record<string, string> = {}
  for (const [k, v] of Object.entries(raw as Record<string, unknown>)) {
    if (!k.startsWith(LIFTBIG_KEY_PREFIX)) continue
    if (typeof v === 'string') out[k] = v
    else if (v !== undefined) out[k] = JSON.stringify(v)
  }
  return Object.keys(out).length > 0 ? out : undefined
}

function legacyTypedFieldsToBundle(
  workoutsRaw: unknown,
  templatesRaw: unknown,
  settingsRaw: unknown,
  customThemesRaw: unknown,
): Record<string, string> {
  const k = LIFTBIG_STORAGE_KEYS
  const w = normalizeWorkouts(workoutsRaw ?? {})
  const t = normalizeTemplates(templatesRaw ?? [])
  const customs = sanitizeCustomThemes(customThemesRaw ?? [])
  const s = normalizeSettings(settingsRaw ?? DEFAULT_SETTINGS, customs)
  return {
    [k.workouts]: JSON.stringify(w),
    [k.templates]: JSON.stringify(t),
    [k.settings]: JSON.stringify(s),
    [k.customThemes]: JSON.stringify(customs),
  }
}

/** Fill registered keys missing from a partial snapshot using legacy typed JSON fields if present. */
function mergeBundleWithLegacyTypedCandidates(
  base: Record<string, string>,
  workoutsRaw: unknown,
  templatesRaw: unknown,
  settingsRaw: unknown,
  customThemesRaw: unknown,
): Record<string, string> {
  const k = LIFTBIG_STORAGE_KEYS
  const legacy = legacyTypedFieldsToBundle(workoutsRaw, templatesRaw, settingsRaw, customThemesRaw)
  const out = { ...base }
  if (workoutsRaw !== undefined && out[k.workouts] === undefined)
    out[k.workouts] = legacy[k.workouts]!
  if (templatesRaw !== undefined && out[k.templates] === undefined)
    out[k.templates] = legacy[k.templates]!
  if (settingsRaw !== undefined && out[k.settings] === undefined)
    out[k.settings] = legacy[k.settings]!
  if (customThemesRaw !== undefined && out[k.customThemes] === undefined)
    out[k.customThemes] = legacy[k.customThemes]!
  return out
}

function parseWorkoutsFromBundleString(raw: string | undefined): WorkoutLog {
  if (raw === undefined || raw === '') return {}
  try {
    return normalizeWorkouts(JSON.parse(raw))
  } catch {
    return {}
  }
}

function parseTemplatesFromBundleString(raw: string | undefined): WorkoutTemplate[] {
  if (raw === undefined || raw === '') return []
  try {
    return normalizeTemplates(JSON.parse(raw))
  } catch {
    return []
  }
}

function parseCustomThemesFromBundleString(raw: string | undefined): CustomTheme[] {
  if (raw === undefined || raw === '') return []
  try {
    return sanitizeCustomThemes(JSON.parse(raw))
  } catch {
    return []
  }
}

function parseSettingsFromBundleString(
  raw: string | undefined,
  customThemes: CustomTheme[] = [],
): AppSettings {
  if (raw === undefined || raw === '') return { ...DEFAULT_SETTINGS }
  try {
    return normalizeSettings(JSON.parse(raw), customThemes)
  } catch {
    return { ...DEFAULT_SETTINGS }
  }
}

function typedViewsFromBundle(bundle: Record<string, string>): Pick<
  LiftBigBackupFile,
  'liftbig_workouts' | 'liftbig_templates' | 'liftbig_settings' | 'liftbig_custom_themes'
> {
  const k = LIFTBIG_STORAGE_KEYS
  const liftbig_custom_themes = parseCustomThemesFromBundleString(bundle[k.customThemes])
  return {
    liftbig_workouts: parseWorkoutsFromBundleString(bundle[k.workouts]),
    liftbig_templates: parseTemplatesFromBundleString(bundle[k.templates]),
    liftbig_settings: parseSettingsFromBundleString(bundle[k.settings], liftbig_custom_themes),
    liftbig_custom_themes,
  }
}

/** Build backup payload from current browser storage (flush workouts before calling). */
export function collectLiftBigBackupPayload(): LiftBigBackupFile {
  const bundle = collectLiftbigRawStorageSnapshot()
  warnUnknownLiftbigKeysInSnapshot(bundle)

  const typed = typedViewsFromBundle(bundle)

  return {
    formatVersion: LIFTBIG_BACKUP_FORMAT_VERSION,
    exportedAt: new Date().toISOString(),
    app: 'liftbig',
    liftbig_local_storage: bundle,
    ...typed,
  }
}

export function serializeLiftBigBackup(payload: LiftBigBackupFile): string {
  return JSON.stringify(payload, null, 2)
}

export function downloadLiftBigBackupJson(payload: LiftBigBackupFile): void {
  const json = serializeLiftBigBackup(payload)
  const stamp = new Date().toISOString().slice(0, 10)
  const filename = `liftbig-backup-${stamp}.json`
  const blob = new Blob([json], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.rel = 'noopener'
  a.click()
  URL.revokeObjectURL(url)
}

export type ParseBackupResult =
  | { ok: true; data: LiftBigBackupFile }
  | { ok: false; error: string }

export function parseLiftBigBackupJson(text: string): ParseBackupResult {
  let parsed: unknown
  try {
    parsed = JSON.parse(text) as unknown
  } catch {
    return { ok: false, error: 'File is not valid JSON.' }
  }

  if (!parsed || typeof parsed !== 'object') {
    return { ok: false, error: 'Backup must be a JSON object.' }
  }

  const o = parsed as Record<string, unknown>

  const k = LIFTBIG_STORAGE_KEYS

  let bundle = coerceBundleFromUnknown(o.liftbig_local_storage)

  let workoutsRaw = o[k.workouts]
  let templatesRaw = o[k.templates]
  let settingsRaw = o[k.settings]
  let customThemesRaw = o[k.customThemes] ?? o.liftbig_custom_themes

  if (
    workoutsRaw === undefined &&
    templatesRaw === undefined &&
    settingsRaw === undefined &&
    customThemesRaw === undefined &&
    typeof o.data === 'object' &&
    o.data !== null
  ) {
    const inner = o.data as Record<string, unknown>
    if (!bundle) bundle = coerceBundleFromUnknown(inner.liftbig_local_storage)
    workoutsRaw = inner[k.workouts]
    templatesRaw = inner[k.templates]
    settingsRaw = inner[k.settings]
    customThemesRaw = inner[k.customThemes] ?? inner.liftbig_custom_themes
  }

  const hasTypedLegacy =
    workoutsRaw !== undefined ||
    templatesRaw !== undefined ||
    settingsRaw !== undefined ||
    customThemesRaw !== undefined

  const bundleEmpty = !bundle || Object.keys(bundle).length === 0

  if (bundleEmpty && !hasTypedLegacy) {
    return {
      ok: false,
      error:
        'Missing LiftBig backup data. Expected liftbig_local_storage and/or liftbig_workouts, liftbig_templates, liftbig_settings.',
    }
  }

  let mergedBundle: Record<string, string>
  if (bundleEmpty) {
    mergedBundle = legacyTypedFieldsToBundle(
      workoutsRaw,
      templatesRaw,
      settingsRaw,
      customThemesRaw,
    )
  } else {
    mergedBundle = mergeBundleWithLegacyTypedCandidates(
      bundle as Record<string, string>,
      workoutsRaw,
      templatesRaw,
      settingsRaw,
      customThemesRaw,
    )
  }

  const typed = typedViewsFromBundle(mergedBundle)

  const data: LiftBigBackupFile = {
    formatVersion:
      typeof o.formatVersion === 'number'
        ? o.formatVersion
        : typeof o.version === 'number'
          ? o.version
          : LIFTBIG_BACKUP_FORMAT_VERSION,
    exportedAt: typeof o.exportedAt === 'string' ? o.exportedAt : new Date().toISOString(),
    app: typeof o.app === 'string' ? o.app : 'liftbig',
    liftbig_local_storage: mergedBundle,
    ...typed,
  }

  return { ok: true, data }
}

/** Replace all liftbig_* storage with the imported snapshot (verbatim strings). */
export function applyLiftBigBackupToStorage(payload: LiftBigBackupFile): void {
  clearLiftbigPrefixedStorage()
  applyLiftbigRawStorageSnapshot(payload.liftbig_local_storage)
}
