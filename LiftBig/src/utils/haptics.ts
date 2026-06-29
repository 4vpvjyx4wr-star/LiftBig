/** Light tactile feedback via the Vibration API (mobile browsers). */

type HapticPattern = 'tap' | 'success' | 'timerStart' | 'timerDone' | 'celebrate'

const PATTERNS: Record<HapticPattern, number | number[]> = {
  tap: 12,
  success: [20, 40, 20],
  timerStart: 18,
  timerDone: [80, 50, 80],
  celebrate: [30, 40, 50, 40, 30],
}

function canVibrate(): boolean {
  return typeof navigator !== 'undefined' && typeof navigator.vibrate === 'function'
}

export function haptic(pattern: HapticPattern = 'tap'): void {
  if (!canVibrate()) return
  try {
    navigator.vibrate(PATTERNS[pattern])
  } catch {
    // Ignore unsupported or blocked vibration.
  }
}
