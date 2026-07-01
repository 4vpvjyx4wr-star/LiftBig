/**
 * LiftBig browser persistence — single source of truth for keys and backup coverage.
 *
 * **Adding new persisted state**
 * 1. Add a field to `LIFTBIG_STORAGE_KEYS` (must stay prefixed with `LIFTBIG_KEY_PREFIX`).
 * 2. Read/write that key only via `loadJson`/`saveJson` or `localStorage` using the constant.
 * 3. Backup/import automatically includes **every** `liftbig_*` key via snapshot scan — no backup-file edit needed.
 * 4. Dev warnings remind you to register the key here so it stays documented.
 */

/** Every LiftBig-owned localStorage key must start with this prefix (scan-based backup relies on it). */
export const LIFTBIG_KEY_PREFIX = 'liftbig_' as const

/**
 * Canonical registry of keys this app intentionally persists.
 * Extend when introducing new liftbig_* storage so the checklist above stays accurate.
 */
export const LIFTBIG_STORAGE_KEYS = {
  workouts: 'liftbig_workouts',
  templates: 'liftbig_templates',
  settings: 'liftbig_settings',
  customThemes: 'liftbig_custom_themes',
  libraryFavorites: 'liftbig_library_favorites',
  planFavorites: 'liftbig_plan_favorites',
  pickAPlan: 'liftbig_pick_a_plan',
} as const

/**
 * Legacy key aliases from earlier app builds/platforms.
 * When found, data is migrated into the canonical key on next load.
 */
export const LIFTBIG_LEGACY_STORAGE_KEY_ALIASES: Partial<
  Record<LiftBigStorageSlot, readonly string[]>
> = {
  workouts: Object.freeze(['workouts']),
  templates: Object.freeze(['templates', 'liftbig_plans']),
  settings: Object.freeze(['settings']),
  libraryFavorites: Object.freeze(['liftbig_favorites', 'favorites']),
  planFavorites: Object.freeze(['liftbig_plan_favs']),
  pickAPlan: Object.freeze(['liftbig_pick_plan']),
}

export type LiftBigStorageSlot = keyof typeof LIFTBIG_STORAGE_KEYS

export type LiftBigRegisteredStorageKey =
  (typeof LIFTBIG_STORAGE_KEYS)[LiftBigStorageSlot]

/** Same keys as `LIFTBIG_STORAGE_KEYS` — derived so the registry cannot drift from values. */
export const REGISTERED_LIFTBIG_STORAGE_KEYS: readonly LiftBigRegisteredStorageKey[] =
  Object.freeze(Object.values(LIFTBIG_STORAGE_KEYS))

const REGISTERED_SET = new Set<string>(REGISTERED_LIFTBIG_STORAGE_KEYS)

/** Raw string snapshot of each liftbig_* key currently in localStorage (values as stored). */
export function collectLiftbigRawStorageSnapshot(): Record<string, string> {
  const out: Record<string, string> = {}
  if (typeof localStorage === 'undefined') return out
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i)
    if (key != null && key.startsWith(LIFTBIG_KEY_PREFIX)) {
      const val = localStorage.getItem(key)
      if (val !== null) out[key] = val
    }
  }
  return out
}

/** Removes every liftbig_* entry before applying an imported snapshot (full restore). */
export function clearLiftbigPrefixedStorage(): void {
  if (typeof localStorage === 'undefined') return
  const keys: string[] = []
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i)
    if (key != null && key.startsWith(LIFTBIG_KEY_PREFIX)) keys.push(key)
  }
  for (const key of keys) localStorage.removeItem(key)
}

/** Writes snapshot strings verbatim (matches how values sit in localStorage). */
export function applyLiftbigRawStorageSnapshot(entries: Record<string, string>): void {
  if (typeof localStorage === 'undefined') return
  for (const [key, raw] of Object.entries(entries)) {
    if (!key.startsWith(LIFTBIG_KEY_PREFIX)) continue
    localStorage.setItem(key, raw)
  }
}

/** Dev-only: snapshot contains prefixed keys not listed in the registry (often harmless — scan picked up a legacy/experiment key). */
export function warnUnknownLiftbigKeysInSnapshot(snapshot: Record<string, string>): void {
  if (!import.meta.env.DEV) return
  for (const key of Object.keys(snapshot)) {
    if (!REGISTERED_SET.has(key)) {
      console.warn(
        `[LiftBig] Snapshot/local_storage backup contains "${key}", which is not in REGISTERED_LIFTBIG_STORAGE_KEYS. Register it in liftbigStorageKeys.ts when this persistence is intentional.`,
      )
    }
  }
}

/** Dev-only: browser has prefixed keys not listed in the registry. */
export function warnUnknownLiftbigKeysInBrowser(): void {
  if (!import.meta.env.DEV || typeof localStorage === 'undefined') return
  const snapshot = collectLiftbigRawStorageSnapshot()
  warnUnknownLiftbigKeysInSnapshot(snapshot)
}
