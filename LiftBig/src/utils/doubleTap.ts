/** Max ms between taps to count as a double-tap (longer on touch screens). */
export function doubleTapMaxIntervalMs(): number {
  if (typeof window !== 'undefined' && window.matchMedia('(pointer: coarse)').matches) {
    return 600
  }
  return 450
}

/** Returns true when the second tap of a double-tap was detected. */
export function createDoubleTapDetector(onDoubleTap: () => void) {
  let lastTapAt = 0

  return {
    registerTap(): boolean {
      const now = Date.now()
      const maxGap = doubleTapMaxIntervalMs()
      if (lastTapAt > 0 && now - lastTapAt <= maxGap) {
        lastTapAt = 0
        onDoubleTap()
        return true
      }
      lastTapAt = now
      return false
    },
    reset() {
      lastTapAt = 0
    },
  }
}
