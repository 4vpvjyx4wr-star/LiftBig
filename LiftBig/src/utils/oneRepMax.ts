/** Estimates one-rep max from a submaximal set (same mass unit in → same unit out). */

export type OneRmFormulaId = 'epley' | 'brzycki' | 'lander'

export interface OneRmFormulaMeta {
  id: OneRmFormulaId
  label: string
}

export const ONE_RM_FORMULAS: OneRmFormulaMeta[] = [
  { id: 'epley', label: 'Epley' },
  { id: 'brzycki', label: 'Brzycki' },
  { id: 'lander', label: 'Lander' },
]

function epley(weight: number, reps: number): number | null {
  if (reps <= 0 || weight <= 0) return null
  if (reps === 1) return weight
  return weight * (1 + reps / 30)
}

function brzycki(weight: number, reps: number): number | null {
  if (reps <= 0 || weight <= 0) return null
  if (reps === 1) return weight
  if (reps >= 37) return null
  return weight * (36 / (37 - reps))
}

function lander(weight: number, reps: number): number | null {
  if (reps <= 0 || weight <= 0) return null
  if (reps === 1) return weight
  const d = 101.3 - 2.67123 * reps
  if (d <= 0) return null
  return (100 * weight) / d
}

export function estimateOneRepMax(
  weight: number,
  reps: number,
  formula: OneRmFormulaId,
): number | null {
  switch (formula) {
    case 'epley':
      return epley(weight, reps)
    case 'brzycki':
      return brzycki(weight, reps)
    case 'lander':
      return lander(weight, reps)
    default:
      return null
  }
}
