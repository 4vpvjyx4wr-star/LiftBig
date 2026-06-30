const MONTH_NAMES = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/** Format `YYYY-MM-DD` as `Month D, YYYY` (production `formatDateKey`). */
export function formatDateKey(dateKey: string): string {
  const [year, month, day] = dateKey.split('-').map(Number);
  return `${MONTH_NAMES[month - 1]} ${day}, ${year}`;
}
