import { createApp } from 'vue'
import { registerSW } from 'virtual:pwa-register'
import App from './App.vue'
import router from './router'
import './assets/main.css'
import { warnUnknownLiftbigKeysInBrowser } from '@/utils/liftbigStorageKeys'

warnUnknownLiftbigKeysInBrowser()

if (import.meta.env.PROD) {
  registerSW({ immediate: true })
}

const app = createApp(App)

app.use(router)

app.mount('#app')
