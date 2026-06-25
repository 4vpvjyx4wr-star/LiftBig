<script setup lang="ts">
import { computed, onUnmounted } from 'vue'
import { useRestTimerState } from '@/composables/useRestTimerState'

const props = withDefaults(
  defineProps<{
    showLauncher?: boolean
    showActiveLauncher?: boolean
    showFloating?: boolean
    compact?: boolean
  }>(),
  {
    showLauncher: true,
    showActiveLauncher: false,
    showFloating: true,
    compact: false,
  },
)

const {
  TIMER_OPTIONS,
  MIN_SECONDS,
  MAX_SECONDS,
  duration,
  running,
  pickerOpen,
  customSecondsInput,
  mins,
  secs,
  isFinished,
  isPartial,
  isFloatingActive,
  bubbleClass,
  selectDur,
  applyCustomDuration,
  onPointerDown,
  onPointerUp,
  onClick,
  reset,
} = useRestTimerState()

const showInlineLauncher = computed(
  () => props.showLauncher || (props.showActiveLauncher && isFloatingActive.value),
)

const launcherClass = computed(() =>
  props.compact
    ? 'min-w-[5.75rem] rounded-xl border-[1.5px] px-3 py-1.5 text-center select-none transition-transform active:scale-[0.97]'
    : 'min-w-[130px] rounded-2xl border-[1.5px] px-5 py-3 text-center select-none transition-transform active:scale-[0.97]',
)

const timeClass = computed(() =>
  props.compact
    ? 'text-xl font-extrabold tracking-widest text-foreground'
    : 'text-3xl font-extrabold tracking-widest text-foreground',
)

const labelClass = computed(() =>
  props.compact
    ? 'mt-0.5 text-[9px] font-bold leading-none text-muted'
    : 'mt-0.5 text-[10px] font-bold text-muted',
)

function cancelCurrentTimer() {
  reset()
  pickerOpen.value = false
}

onUnmounted(() => {
  onPointerUp()
})
</script>

<template>
  <div v-if="showInlineLauncher">
    <button
      type="button"
      :class="[launcherClass, bubbleClass]"
      @pointerdown="onPointerDown"
      @pointerup="onPointerUp"
      @pointerleave="onPointerUp"
      @click="onClick"
    >
      <div :class="timeClass">
        {{ mins }}:{{ secs }}
      </div>
      <div :class="labelClass">
        <template v-if="isFinished">Done - tap to reset</template>
        <template v-else-if="running">Tap to pause</template>
        <template v-else-if="isPartial">Resume</template>
        <template v-else>Hold to set duration</template>
      </div>
    </button>
  </div>

  <Teleport to="body">
    <button
      v-if="showFloating && isFloatingActive"
      type="button"
      class="fixed left-1/2 top-3 z-40 min-w-[130px] -translate-x-1/2 rounded-2xl border-[1.5px] px-5 py-3 text-center select-none transition-transform active:scale-[0.97]"
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
        <template v-if="isFinished">Done - tap to reset</template>
        <template v-else-if="running">Tap to pause</template>
        <template v-else-if="isPartial">Resume</template>
        <template v-else>Hold to set duration</template>
      </div>
    </button>
  </Teleport>

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
        <div class="mt-3 border-t border-border pt-3">
          <p class="mb-1.5 text-[11px] font-bold text-muted">Custom</p>
          <p class="mb-2 text-[10px] leading-snug text-muted">
            Seconds (e.g. 45) or m:ss (e.g. 1:30). {{ MIN_SECONDS }}s–{{ MAX_SECONDS / 60 }} min.
          </p>
          <div class="flex gap-2">
            <input
              v-model="customSecondsInput"
              type="text"
              inputmode="decimal"
              autocomplete="off"
              class="min-w-0 flex-1 rounded-lg border border-border bg-card px-3 py-2.5 text-[15px] font-bold text-foreground outline-none focus:border-primary"
              placeholder="e.g. 45 or 2:00"
              @keydown.enter.prevent="applyCustomDuration"
            />
            <button
              type="button"
              class="shrink-0 rounded-lg bg-blue px-4 py-2.5 text-sm font-bold text-foreground"
              @click="applyCustomDuration"
            >
              Set
            </button>
          </div>
        </div>
        <button
          type="button"
          class="mt-3 w-full rounded-lg border border-red-900/50 bg-card px-3 py-2.5 text-sm font-bold text-red-400"
          @click="cancelCurrentTimer"
        >
          Cancel current timer
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
</template>
