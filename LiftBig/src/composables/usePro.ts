import { onMounted, ref, type Ref } from 'vue'
import { Capacitor } from '@capacitor/core'
import { PRO_MONTHLY_PRODUCT_ID, PRO_YEARLY_PRODUCT_ID } from '@/config/listing'
import { LiftBigNative, type ProProduct } from '@/native/liftbigPlugin'

const active = ref(false)
const products = ref<ProProduct[]>([])
const statusMessage = ref('')
let loaded = false

async function refresh(): Promise<void> {
  if (!Capacitor.isNativePlatform()) {
    active.value = false
    return
  }
  try {
    const status = await LiftBigNative.getProStatus()
    active.value = status.active
    const listed = await LiftBigNative.loadProProducts()
    products.value = listed.products
  } catch {
    active.value = false
  }
}

export function usePro(): {
  isNative: boolean
  active: Ref<boolean>
  products: Ref<ProProduct[]>
  statusMessage: Ref<string>
  monthlyId: string
  yearlyId: string
  purchase: (productId: string) => Promise<void>
  restore: () => Promise<void>
} {
  onMounted(() => {
    if (loaded) return
    loaded = true
    void refresh()
  })

  return {
    isNative: Capacitor.isNativePlatform(),
    active,
    products,
    statusMessage,
    monthlyId: PRO_MONTHLY_PRODUCT_ID,
    yearlyId: PRO_YEARLY_PRODUCT_ID,
    async purchase(productId: string) {
      statusMessage.value = ''
      try {
        const result = await LiftBigNative.purchasePro({ productId })
        active.value = result.active
        statusMessage.value = result.active ? 'LiftBig Pro is unlocked.' : (result.message ?? 'Purchase was not completed.')
      } catch {
        statusMessage.value = 'Purchase could not be completed.'
      }
    },
    async restore() {
      statusMessage.value = ''
      try {
        const result = await LiftBigNative.restorePro()
        active.value = result.active
        statusMessage.value = result.active
          ? 'Pro purchases restored.'
          : 'No active Pro subscription was found for this Apple ID.'
      } catch {
        statusMessage.value = 'Restore could not be completed.'
      }
    },
  }
}
