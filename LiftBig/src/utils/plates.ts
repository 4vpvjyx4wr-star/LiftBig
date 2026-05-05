export const PLATE_SIZES = [45, 35, 25, 10, 5, 2.5] as const

export const PLATE_COLORS: Record<number, string> = {
  45: '#E63946',
  35: '#457B9D',
  25: '#F4A261',
  10: '#2A9D8F',
  5: '#E9C46A',
  2.5: '#A8DADC',
}

export function calculatePlates(
  targetWeight: number,
  barWeight: number,
): { plates: number[]; remainder: number } {
  const weightPerSide = (targetWeight - barWeight) / 2
  if (weightPerSide < 0) return { plates: [], remainder: targetWeight }

  const plates: number[] = []
  let remaining = weightPerSide

  for (const plate of PLATE_SIZES) {
    while (remaining >= plate - 0.001) {
      plates.push(plate)
      remaining -= plate
    }
  }

  return { plates, remainder: Math.round(remaining * 10) / 10 }
}
