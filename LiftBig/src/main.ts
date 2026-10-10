import { createApp } from 'vue'
import { registerSW } from 'virtual:pwa-register'
import App from './App.vue'
import router from './router'
import './assets/main.css'
import { bootstrapNativeApp } from '@/native/nativeBootstrap'
import { warnUnknownLiftbigKeysInBrowser } from '@/utils/liftbigStorageKeys'

warnUnknownLiftbigKeysInBrowser()

if (import.meta.env.PROD && !__LIFTBIG_NATIVE__) {
  registerSW({ immediate: true })
}

await bootstrapNativeApp()

const app = createApp(App)

app.use(router)

app.mount('#app')
