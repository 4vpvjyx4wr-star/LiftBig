/**
 * Browser localStorage: survives closing the tab/window and normal app redeploys on the same site.
 * Data is per-origin (scheme + host + port); clearing site data or using another browser/device starts fresh.
 */

const warnedQuota = { value: false }
const SHADOW_SUFFIX = '__shadow'

export function loadJson<T>(key: string, fallback: T): T {
  if (typeof localStorage === 'undefined') return fallback
  try {
    const raw = localStorage.getItem(key)
    if (raw == null) return fallback
    return JSON.parse(raw) as T
  } catch {
    return fallback
  }
}

export function loadJsonWithRecovery<T>(
  key: string,
  fallback: T,
  options?: { legacyKeys?: readonly string[] },
): T {
  if (typeof localStorage === 'undefined') return fallback

  const candidates = [key, ...(options?.legacyKeys ?? [])]

  for (const candidate of candidates) {
    try {
      const raw = localStorage.getItem(candidate)
      if (raw == null) continue
      const parsed = JSON.parse(raw) as T
      if (candidate !== key) {
        // Migrate legacy payload into canonical key as soon as it's seen.
        saveJson(key, parsed)
        localStorage.removeItem(candidate)
      }
      return parsed
    } catch {
      // Keep searching: a bad value in one key should not block recovery.
    }
  }

  // Final fallback: shadow copy, used when main payload is partially/corruptly written.
  try {
    const shadowRaw = localStorage.getItem(`${key}${SHADOW_SUFFIX}`)
    if (shadowRaw == null) return fallback
    const parsed = JSON.parse(shadowRaw) as T
    saveJson(key, parsed)
    return parsed
  } catch {
    return fallback
  }
}

export function saveJson(key: string, value: unknown): void {
  if (typeof localStorage === 'undefined') return
  try {
    const raw = JSON.stringify(value)
    localStorage.setItem(key, raw)
    // Shadow copy helps recover from rare interrupted/corrupted writes across refreshes/updates.
    localStorage.setItem(`${key}${SHADOW_SUFFIX}`, raw)
  } catch (e) {
    if (!warnedQuota.value && e instanceof DOMException && e.name === 'QuotaExceededError') {
      warnedQuota.value = true
      window.alert('Storage is full. Export or delete old data before saving again.')
    }
  }
}
