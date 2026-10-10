import { Capacitor } from '@capacitor/core'
import { Haptics, ImpactStyle, NotificationType } from '@capacitor/haptics'

/** Tactile feedback. iPhone uses the Haptics plugin; mobile browsers use Vibration API. */

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

function playNativeHaptic(pattern: HapticPattern): void {
  const play = async () => {
    if (pattern === 'timerDone') {
      await Haptics.notification({ type: NotificationType.Warning })
      await Haptics.vibrate({ duration: 400 })
      return
    }
    if (pattern === 'success' || pattern === 'celebrate') {
      await Haptics.notification({ type: NotificationType.Success })
      return
    }
    await Haptics.impact({ style: pattern === 'timerStart' ? ImpactStyle.Medium : ImpactStyle.Light })
  }
  void play().catch(() => {
    // Ignore unsupported or blocked vibration.
  })
}

export function haptic(pattern: HapticPattern = 'tap'): void {
  if (Capacitor.isNativePlatform()) {
    playNativeHaptic(pattern)
    return
  }
  if (!canVibrate()) return
  try {
    navigator.vibrate(PATTERNS[pattern])
  } catch {
    // Ignore unsupported or blocked vibration.
  }
}
