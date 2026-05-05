/**
 * Browser localStorage: survives closing the tab/window and normal app redeploys on the same site.
 * Data is per-origin (scheme + host + port); clearing site data or using another browser/device starts fresh.
 */

const warnedQuota = { value: false }

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

export function saveJson(key: string, value: unknown): void {
  if (typeof localStorage === 'undefined') return
  try {
    localStorage.setItem(key, JSON.stringify(value))
  } catch (e) {
    if (!warnedQuota.value && e instanceof DOMException && e.name === 'QuotaExceededError') {
      warnedQuota.value = true
      window.alert('Storage is full. Export or delete old data before saving again.')
    }
  }
}
