import { Capacitor } from '@capacitor/core'
import { Keyboard, KeyboardResize } from '@capacitor/keyboard'
import { SplashScreen } from '@capacitor/splash-screen'
import { StatusBar, Style } from '@capacitor/status-bar'
import { hydrateNativeStore } from '@/native/nativeFileStore'

export async function bootstrapNativeApp(): Promise<void> {
  await hydrateNativeStore()
  if (!Capacitor.isNativePlatform()) return
  try {
    await StatusBar.setOverlaysWebView({ overlay: true })
    await StatusBar.setStyle({ style: Style.Dark })
    await StatusBar.setBackgroundColor({ color: '#0A0F1E' })
  } catch {
    // Status bar is already usable.
  }
  try {
    await Keyboard.setResizeMode({ mode: KeyboardResize.Body })
    await Keyboard.setAccessoryBarVisible({ isVisible: true })
  } catch {
    // Keyboard resize is a refinement.
  }
  try {
    await SplashScreen.hide()
  } catch {
    // No splash plugin on web.
  }
}
