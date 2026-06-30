export function parseWeightLbs(value: string): number {
  return parseFloat(String(value).replace(',', '.'));
}

export function formatWeight(
  weightLbs: number,
  unit: 'lb' | 'kg',
  decimals = 1
): string {
  const KG_PER_LB = 2.2046226218;
  const display = unit === 'lb' ? weightLbs : weightLbs / KG_PER_LB;
  const factor = 10 ** decimals;
  const rounded = Math.round(display * factor) / factor;
  const text = String(rounded);
  return text.includes('.') ? text.replace(/\.?0+$/, '').replace(/\.$/, '') : text;
}

export function formatWeightWithUnit(
  weightLbs: number,
  unit: 'lb' | 'kg',
  decimals = 1
): string {
  const value = formatWeight(weightLbs, unit, decimals);
  return unit === 'lb' ? `${value} lb` : `${value} kg`;
}
