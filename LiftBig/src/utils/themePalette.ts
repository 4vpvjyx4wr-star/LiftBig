/** Editable color tokens for a LiftBig theme (maps to CSS custom properties). */
export type ThemePalette = {
  background: string
  card: string
  cardInner: string
  border: string
  primary: string
  blue: string
  blueSoft: string
  foreground: string
  muted: string
  success: string
  successText: string
  successSoft: string
}

export type ThemePaletteKey = keyof ThemePalette

export type CustomTheme = {
  id: string
  name: string
  colors: ThemePalette
}

export const CUSTOM_THEME_PREFIX = 'custom:' as const

export type CustomThemeRef = `${typeof CUSTOM_THEME_PREFIX}${string}`

export type ActiveTheme = string

export const THEME_PALETTE_FIELDS: { key: ThemePaletteKey; label: string; hint?: string }[] = [
  { key: 'background', label: 'Background' },
  { key: 'card', label: 'Card' },
  { key: 'cardInner', label: 'Card inner', hint: 'Nested panels & inputs' },
  { key: 'border', label: 'Border' },
  { key: 'primary', label: 'Primary', hint: 'Logo, active tabs, main buttons' },
  { key: 'blue', label: 'Secondary', hint: 'Alternate action buttons' },
  { key: 'blueSoft', label: 'Secondary soft' },
  { key: 'foreground', label: 'Text' },
  { key: 'muted', label: 'Muted text' },
  { key: 'success', label: 'Success' },
  { key: 'successText', label: 'Success text' },
  { key: 'successSoft', label: 'Success background' },
]

export const DEFAULT_THEME_PALETTE: ThemePalette = {
  background: '#0a0f1e',
  card: '#111827',
  cardInner: '#0d1526',
  border: '#1e2a45',
  primary: '#f4501e',
  blue: '#1d4ed8',
  blueSoft: '#1e3a5f',
  foreground: '#f0f4ff',
  muted: '#4a5a7a',
  success: '#16a34a',
  successText: '#4ade80',
  successSoft: '#0d2010',
}

const CSS_VAR_BY_KEY: Record<ThemePaletteKey, string> = {
  background: '--color-background',
  card: '--color-card',
  cardInner: '--color-card-inner',
  border: '--color-border',
  primary: '--color-primary',
  blue: '--color-blue',
  blueSoft: '--color-blue-soft',
  foreground: '--color-foreground',
  muted: '--color-muted',
  success: '--color-success',
  successText: '--color-success-text',
  successSoft: '--color-success-soft',
}

export const THEME_CSS_VARS = Object.values(CSS_VAR_BY_KEY)

export function isCustomThemeRef(theme: string): theme is CustomThemeRef {
  return theme.startsWith(CUSTOM_THEME_PREFIX)
}

export function customThemeRef(id: string): CustomThemeRef {
  return `${CUSTOM_THEME_PREFIX}${id}`
}

export function parseCustomThemeId(ref: string): string | null {
  if (!isCustomThemeRef(ref)) return null
  const id = ref.slice(CUSTOM_THEME_PREFIX.length)
  return id.length > 0 ? id : null
}

export function newCustomThemeId(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`
}

export function normalizeHexColor(input: string): string | null {
  const raw = input.trim().replace(/^#/, '')
  if (/^[0-9a-fA-F]{6}$/.test(raw)) return `#${raw.toLowerCase()}`
  if (/^[0-9a-fA-F]{3}$/.test(raw)) {
    return `#${raw[0]}${raw[0]}${raw[1]}${raw[1]}${raw[2]}${raw[2]}`.toLowerCase()
  }
  return null
}

export function paletteCssVariables(colors: ThemePalette): Record<string, string> {
  const out: Record<string, string> = {}
  for (const field of THEME_PALETTE_FIELDS) {
    out[CSS_VAR_BY_KEY[field.key]] = colors[field.key]
  }
  return out
}

export function applyThemePaletteToElement(el: HTMLElement, colors: ThemePalette) {
  for (const [cssVar, value] of Object.entries(paletteCssVariables(colors))) {
    el.style.setProperty(cssVar, value)
  }
}

export function clearThemeInlineVars(el: HTMLElement) {
  for (const cssVar of THEME_CSS_VARS) {
    el.style.removeProperty(cssVar)
  }
}

export function applyActiveTheme(activeTheme: string, customThemes: CustomTheme[]) {
  if (typeof document === 'undefined') return
  const el = document.documentElement
  clearThemeInlineVars(el)

  if (activeTheme === 'default') {
    delete el.dataset.theme
    return
  }

  if (isCustomThemeRef(activeTheme)) {
    const customId = parseCustomThemeId(activeTheme)
    const custom = customThemes.find((t) => t.id === customId)
    if (custom) {
      el.dataset.theme = 'custom'
      applyThemePaletteToElement(el, custom.colors)
    } else {
      delete el.dataset.theme
    }
    return
  }

  el.dataset.theme = activeTheme
}

export function sanitizeThemePalette(raw: unknown): ThemePalette | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  const out = { ...DEFAULT_THEME_PALETTE }
  for (const field of THEME_PALETTE_FIELDS) {
    const v = o[field.key]
    if (typeof v !== 'string') continue
    const hex = normalizeHexColor(v)
    if (hex) out[field.key] = hex
  }
  return out
}

export function sanitizeCustomTheme(raw: unknown): CustomTheme | null {
  if (!raw || typeof raw !== 'object') return null
  const o = raw as Record<string, unknown>
  if (typeof o.id !== 'string' || !o.id.trim()) return null
  if (typeof o.name !== 'string' || !o.name.trim()) return null
  const colors = sanitizeThemePalette(o.colors)
  if (!colors) return null
  return { id: o.id.trim(), name: o.name.trim().slice(0, 48), colors }
}

export function sanitizeCustomThemes(raw: unknown): CustomTheme[] {
  if (!Array.isArray(raw)) return []
  const out: CustomTheme[] = []
  const seen = new Set<string>()
  for (const item of raw) {
    const theme = sanitizeCustomTheme(item)
    if (!theme || seen.has(theme.id)) continue
    seen.add(theme.id)
    out.push(theme)
  }
  return out
}

export function clonePalette(palette: ThemePalette): ThemePalette {
  return { ...palette }
}

export function randomHexColor(): string {
  const hex = Math.floor(Math.random() * 0xffffff)
    .toString(16)
    .padStart(6, '0')
  return `#${hex}`
}

export function randomThemePalette(): ThemePalette {
  const out = { ...DEFAULT_THEME_PALETTE }
  for (const field of THEME_PALETTE_FIELDS) {
    out[field.key] = randomHexColor()
  }
  return out
}
