<script setup lang="ts">
import { computed, nextTick, ref, watch } from 'vue'

const CARDIO_DURATION_QUICK_PICKS = [5, 10, 15, 20, 25, 30, 45, 60, 75, 90] as const

const props = defineProps<{
  modelValue: string
  placeholder?: string
  /** Goal duration shown as hint (minutes). */
  targetDuration?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const showMenu = ref(false)
const menuRef = ref<HTMLElement | null>(null)
let menuHideTimer: ReturnType<typeof setTimeout> | null = null
const MENU_HIDE_AFTER_BLUR_MS = 380

const durationPlaceholder = computed(() => {
  const g = props.targetDuration?.trim()
  return g ? `${g} min goal` : (props.placeholder ?? 'Minutes')
})

function cancelMenuHide() {
  if (menuHideTimer) {
    clearTimeout(menuHideTimer)
    menuHideTimer = null
  }
}

function hideMenuSoon() {
  if (menuHideTimer) clearTimeout(menuHideTimer)
  menuHideTimer = window.setTimeout(() => {
    menuHideTimer = null
    showMenu.value = false
  }, MENU_HIDE_AFTER_BLUR_MS)
}

function alignMenuScroll() {
  const root = menuRef.value
  if (!root) return
  const val = props.modelValue.trim()
  const n = parseInt(val, 10)
  if (Number.isNaN(n)) {
    root.scrollTop = 0
    return
  }
  const btn = root.querySelector(`button[data-cardio-min="${n}"]`) as HTMLElement | null
  if (!btn) {
    root.scrollTop = 0
    return
  }
  const viewH = root.clientHeight
  const mid = btn.offsetTop + btn.offsetHeight / 2
  const maxScroll = Math.max(0, root.scrollHeight - viewH)
  root.scrollTop = Math.max(0, Math.min(mid - viewH / 2, maxScroll))
}

async function onFocus() {
  cancelMenuHide()
  showMenu.value = true
  await nextTick()
  requestAnimationFrame(() => alignMenuScroll())
}

function selectMinutes(raw: string) {
  cancelMenuHide()
  emit('update:modelValue', raw)
  showMenu.value = false
}

watch([() => props.modelValue, showMenu], async () => {
  if (!showMenu.value) return
  await nextTick()
  requestAnimationFrame(() => alignMenuScroll())
})
</script>

<template>
  <div class="relative min-w-0">
    <input
      :value="modelValue"
      type="text"
      inputmode="numeric"
      data-touch-input
      data-workout-set-input
      class="min-w-0 w-full rounded-lg border border-border bg-card-inner px-3 py-2 text-center text-base text-foreground outline-none focus:border-primary"
      :placeholder="durationPlaceholder"
      @focus="onFocus"
      @blur="hideMenuSoon"
      @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    />
    <div
      v-if="showMenu"
      ref="menuRef"
      class="absolute left-0 right-0 top-full z-30 mt-1 max-h-40 overflow-y-auto rounded-lg border border-border bg-card shadow-lg"
    >
      <button
        v-for="min in CARDIO_DURATION_QUICK_PICKS"
        :key="min"
        type="button"
        :data-cardio-min="min"
        class="block w-full px-2 py-1.5 text-center text-sm text-foreground hover:bg-card-inner"
        @touchstart.passive="cancelMenuHide"
        @mousedown.prevent="cancelMenuHide"
        @click.prevent.stop="selectMinutes(String(min))"
      >
        {{ min }} min
      </button>
    </div>
  </div>
</template>
