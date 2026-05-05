<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue'

const TIMER_OPTIONS = [30, 60, 90, 120] as const

const duration = ref(60)
const remaining = ref(60)
const running = ref(false)
const pickerOpen = ref(false)
let intervalId: ReturnType<typeof setInterval> | null = null
let longPressTimer: ReturnType<typeof setTimeout> | null = null
const longPressConsumed = ref(false)

function clearTick() {
  if (intervalId) {
    clearInterval(intervalId)
    intervalId = null
  }
}

watch(running, (r) => {
  clearTick()
  if (!r) return
  intervalId = setInterval(() => {
    remaining.value -= 1
    if (remaining.value <= 0) {
      remaining.value = 0
      running.value = false
      clearTick()
      if (typeof navigator !== 'undefined' && navigator.vibrate) {
        navigator.vibrate([80, 50, 80])
      }
    }
  }, 1000)
})

onUnmounted(() => {
  clearTick()
  if (longPressTimer) clearTimeout(longPressTimer)
})

function toggle() {
  if (remaining.value === 0) {
    remaining.value = duration.value
    running.value = true
    return
  }
  running.value = !running.value
}

function selectDur(d: number) {
  duration.value = d
  remaining.value = d
  running.value = false
  pickerOpen.value = false
}

function onPointerDown() {
  longPressConsumed.value = false
  longPressTimer = setTimeout(() => {
    longPressConsumed.value = true
    running.value = false
    pickerOpen.value = true
    longPressTimer = null
  }, 550)
}

function onPointerUp() {
  if (longPressTimer) {
    clearTimeout(longPressTimer)
    longPressTimer = null
  }
}

function onClick() {
  if (longPressConsumed.value) {
    longPressConsumed.value = false
    return
  }
  toggle()
}

const mins = computed(() => Math.floor(remaining.value / 60))
const secs = computed(() => String(remaining.value % 60).padStart(2, '0'))
const isFinished = computed(() => remaining.value === 0)
const isPartial = computed(
  () => remaining.value < duration.value && remaining.value > 0,
)

const bubbleClass = computed(() => {
  if (isFinished.value) return 'border-primary bg-[#2a1008]'
  if (running.value) return 'border-[#16a34a] bg-[#163020]'
  return 'border-border bg-card-inner'
})
</script>

<template>
  <div>
    <button
      type="button"
      class="min-w-[130px] rounded-2xl border-[1.5px] px-5 py-3 text-center select-none"
      :class="bubbleClass"
      @pointerdown="onPointerDown"
      @pointerup="onPointerUp"
      @pointerleave="onPointerUp"
      @click="onClick"
    >
      <div class="text-3xl font-extrabold tracking-widest text-foreground">
        {{ mins }}:{{ secs }}
      </div>
      <div class="mt-0.5 text-[10px] font-bold text-muted">
        <template v-if="isFinished">Done — tap to restart</template>
        <template v-else-if="running">Tap to pause</template>
        <template v-else-if="isPartial">Resume</template>
        <template v-else>Hold to set duration</template>
      </div>
    </button>

    <Teleport to="body">
      <div
        v-if="pickerOpen"
        class="fixed inset-0 z-[60] flex items-center justify-center bg-black/65"
        @click.self="pickerOpen = false"
      >
        <div class="w-[280px] rounded-2xl border border-border bg-card-inner p-5" @click.stop>
          <h4 class="text-center text-lg font-extrabold text-foreground">Rest Timer</h4>
          <p class="mb-3 text-center text-[11px] text-muted">Long-press the timer to reopen</p>
          <button
            v-for="d in TIMER_OPTIONS"
            :key="d"
            type="button"
            class="mb-1 flex w-full items-center justify-between rounded-lg px-3 py-3 text-left"
            :class="duration === d ? 'bg-card text-foreground' : 'text-muted'"
            @click="selectDur(d)"
          >
            <span class="text-[15px] font-bold">{{
              d < 60 ? `${d} seconds` : `${d / 60} minute${d > 60 ? 's' : ''}`
            }}</span>
            <span v-if="duration === d" class="font-extrabold text-primary">✓</span>
          </button>
          <button
            type="button"
            class="mt-2 w-full py-2 text-sm text-muted"
            @click="pickerOpen = false"
          >
            Close
          </button>
        </div>
      </div>
    </Teleport>
  </div>
</template>
