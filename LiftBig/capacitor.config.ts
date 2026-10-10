import type { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId: 'com.liftbig.app',
  appName: 'LiftBig',
  webDir: 'dist',
  ios: {
    contentInset: 'never',
    backgroundColor: '#0A0F1E',
  },
  android: {
    backgroundColor: '#0A0F1E',
  },
  plugins: {
    SplashScreen: {
      launchAutoHide: false,
      backgroundColor: '#0A0F1E',
      showSpinner: false,
    },
    LocalNotifications: {
      presentationOptions: ['badge', 'sound', 'banner', 'list'],
    },
  },
}

export default config
