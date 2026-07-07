<script setup lang="ts">
import { computed, nextTick, ref, watch } from 'vue'
import type { DistanceUnit } from '@/utils/distances'
import { distanceUnitLabel } from '@/utils/distances'

const QUICK_PICKS_MI = [0.5, 1, 2, 3, 5, 10] as const
const QUICK_PICKS_KM = [1, 2, 3, 5, 10, 15] as const

const props = defineProps<{
  modelValue: string
  distanceUnit: DistanceUnit
  /** Goal distance shown as hint. */
  targetDistance?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const showMenu = ref(false)
const menuRef = ref<HTMLElement | null>(null)
let menuHideTimer: number | null = null
const MENU_HIDE_AFTER_BLUR_MS = 380

const unitLabel = computed(() => distanceUnitLabel(props.distanceUnit))

const quickPicks = computed(() =>
  props.distanceUnit === 'mi' ? QUICK_PICKS_MI : QUICK_PICKS_KM,
)

const distancePlaceholder = computed(() => {
  const g = props.targetDistance?.trim()
  if (g) return `${g} ${unitLabel.value} goal`
  return `Optional (${unitLabel.value})`
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
  const n = parseFloat(val)
  if (Number.isNaN(n)) {
    root.scrollTop = 0
    return
  }
  const btn = root.querySelector(`button[data-cardio-dist="${n}"]`) as HTMLElement | null
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

function selectDistance(raw: string) {
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
    <div class="relative">
      <input
        :value="modelValue"
        type="text"
        inputmode="decimal"
        data-touch-input
        data-workout-set-input
        class="min-w-0 w-full rounded-lg border border-border bg-card-inner px-3 py-2 pr-10 text-center text-base text-foreground outline-none focus:border-primary"
        :placeholder="distancePlaceholder"
        @focus="onFocus"
        @blur="hideMenuSoon"
        @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      />
      <span
        class="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-xs font-semibold text-muted"
        aria-hidden="true"
      >
        {{ unitLabel }}
      </span>
    </div>
    <div
      v-if="showMenu"
      ref="menuRef"
      class="absolute left-0 right-0 top-full z-30 mt-1 max-h-40 overflow-y-auto rounded-lg border border-border bg-card shadow-lg"
    >
      <button
        v-for="dist in quickPicks"
        :key="dist"
        type="button"
        :data-cardio-dist="dist"
        class="block w-full px-2 py-1.5 text-center text-sm text-foreground hover:bg-card-inner"
        @touchstart.passive="cancelMenuHide"
        @mousedown.prevent="cancelMenuHide"
        @click.prevent.stop="selectDistance(String(dist))"
      >
        {{ dist }} {{ unitLabel }}
      </button>
    </div>
  </div>
</template>
