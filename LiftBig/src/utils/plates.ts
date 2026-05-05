import type { WeightUnit } from '@/utils/units'

export const PLATE_SIZES_LB = [45, 35, 25, 10, 5, 2.5] as const

export const PLATE_COLORS_LB: Record<number, string> = {
  45: '#E63946',
  35: '#457B9D',
  25: '#F4A261',
  10: '#2A9D8F',
  5: '#E9C46A',
  2.5: '#A8DADC',
}

/** Common gym kg denominations (IWF-style). */
export const PLATE_SIZES_KG = [25, 20, 15, 10, 5, 2.5, 1.25] as const

export const PLATE_COLORS_KG: Record<number, string> = {
  25: '#E63946',
  20: '#457B9D',
  15: '#F4A261',
  10: '#2A9D8F',
  5: '#E9C46A',
  2.5: '#A8DADC',
  1.25: '#9CA3AF',
}

export function plateSizesForUnit(unit: WeightUnit): readonly number[] {
  return unit === 'lb' ? PLATE_SIZES_LB : PLATE_SIZES_KG
}

export function plateColorsForUnit(unit: WeightUnit): Record<number, string> {
  return unit === 'lb' ? PLATE_COLORS_LB : PLATE_COLORS_KG
}

export function defaultBarForUnit(unit: WeightUnit): number {
  return unit === 'lb' ? 45 : 20
}

export function barChoicesForUnit(unit: WeightUnit): readonly number[] {
  return unit === 'lb' ? ([45, 35] as const) : ([20, 15] as const)
}

export type PlateQuickRow = { label: string; weight: number }

export function quickPresetsForUnit(unit: WeightUnit): PlateQuickRow[] {
  if (unit === 'lb') {
    return [
      { label: '1 plate', weight: 135 },
      { label: '2 plates', weight: 185 },
      { label: '3 plates', weight: 225 },
      { label: '4 plates', weight: 315 },
      { label: '5 plates', weight: 405 },
    ]
  }
  return [
    { label: '1 plate / side (20s)', weight: 60 },
    { label: '2 plates / side (20s)', weight: 100 },
    { label: '3 plates / side (20s)', weight: 140 },
    { label: 'Heavy triples', weight: 180 },
    { label: 'Five reds / side', weight: 220 },
  ]
}

export function plateLabel(unit: WeightUnit): string {
  return unit === 'lb' ? 'lb' : 'kg'
}

export function calculatePlates(
  targetWeight: number,
  barWeight: number,
  sizes: readonly number[],
): { plates: number[]; remainder: number } {
  const weightPerSide = (targetWeight - barWeight) / 2
  if (weightPerSide < 0) return { plates: [], remainder: targetWeight }

  const plates: number[] = []
  let remaining = weightPerSide

  for (const plate of sizes) {
    while (remaining >= plate - 0.001) {
      plates.push(plate)
      remaining -= plate
    }
  }

  return { plates, remainder: Math.round(remaining * 1000) / 1000 }
}
