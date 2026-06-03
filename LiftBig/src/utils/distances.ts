export type DistanceUnit = 'mi' | 'km'

export function distanceUnitLabel(unit: DistanceUnit): string {
  return unit === 'mi' ? 'mi' : 'km'
}

/** Normalize user distance input to a plain decimal string (unit comes from settings). */
export function normalizeDistanceInput(raw: string): string {
  const t = String(raw).trim().replace(/,/g, '.')
  if (!t) return ''
  const stripped = t.replace(/\s*(mi|km|miles|kilometers?)\s*$/i, '').trim()
  const n = parseFloat(stripped)
  if (Number.isNaN(n) || n < 0) return stripped
  return String(Math.round(n * 100) / 100).replace(/\.?0+$/, '').replace(/\.$/, '')
}

export function formatDistanceWithUnit(value: string, unit: DistanceUnit): string {
  const t = normalizeDistanceInput(value)
  if (!t) return ''
  return `${t} ${distanceUnitLabel(unit)}`
}

export function isDistanceUnit(value: unknown): value is DistanceUnit {
  return value === 'mi' || value === 'km'
}
