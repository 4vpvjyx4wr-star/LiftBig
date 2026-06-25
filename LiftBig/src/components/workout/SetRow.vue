<script setup lang="ts">
import { computed, inject, nextTick, ref, watch } from 'vue'
import { settingsInjectionKey } from '@/composables/injectionKeys'
import { useWorkoutSetLoggingFocusConsumer } from '@/composables/useWorkoutSetLoggingFocus'
import type { SetLog } from '@/types/workout'
import { finiteGoalRepMaxForScroll, REP_QUICK_PICK_DESCENDING } from '@/utils/progressiveOverload'
import { haptic } from '@/utils/haptics'
import CoreDurationInput from '@/components/workout/CoreDurationInput.vue'
import {
  displayInputToStoredLbsString,
  parseStoredLbs,
  storedLbsStringToDisplay,
} from '@/utils/units'

/** Goal max rep as 3rd visible row in the picker (0-based index 2), ~5 rows in max-h-40. */
const REPS_MENU_TARGET_VISIBLE_INDEX = 2

const props = defineProps<{
  set: SetLog
  index: number
  /** Id of the next set in the same exercise (for auto-advance focus). */
  nextSetId?: string
  targetReps?: string
  /** First set: goal weight (stored lb string) — scroll picker to this row. */
  targetWeightStored?: string
  /** Sets after the first: prior row’s stored weight (lb string). */
  priorSetWeightStored?: string
  /** Sets after the first: prior row’s reps — reps picker scroll centers on this when opening. */
  priorSetReps?: string
  /** Core exercises: show optional time column. */
  showDuration?: boolean
  /** Goal time in seconds for the duration input placeholder. */
  targetDurationSeconds?: string
  /** Sets after the first: prior row’s logged duration (seconds). */
  priorSetDurationSeconds?: string
}>()

const emit = defineEmits<{
  update: [field: 'reps' | 'weight' | 'durationSeconds', value: string]
  toggleWarmup: []
  delete: []
  advanceToNextWeight: []
}>()

const isWarmup = computed(() => props.set.isWarmup === true)

function isWorkingSetComplete(set: SetLog): boolean {
  return set.reps.trim() !== '' && set.weight.trim() !== ''
}

watch(
  () => [props.set.reps, props.set.weight, props.set.isWarmup] as const,
  ([reps, weight, warmup], prev) => {
    if (warmup === true) return
    const wasComplete = prev ? prev[0].trim() !== '' && prev[1].trim() !== '' : false
    if (isWorkingSetComplete({ ...props.set, reps, weight }) && !wasComplete) {
      haptic('success')
    }
  },
)

const settings = inject(settingsInjectionKey)!
const setLoggingFocus = useWorkoutSetLoggingFocusConsumer()
const weightUnit = computed(() => settings.weightUnit.value)
const showWeightMenu = ref(false)
const showRepsMenu = ref(false)

let weightMenuHideTimer: ReturnType<typeof setTimeout> | null = null
let repsMenuHideTimer: ReturnType<typeof setTimeout> | null = null

/** Long enough for iOS to fire the synthetic click after the input blurs. */
const MENU_HIDE_AFTER_BLUR_MS = 380

const repsScrollTargetMax = computed(() => finiteGoalRepMaxForScroll(props.targetReps))

const repsMenuRef = ref<HTMLElement | null>(null)

/** Integers min…max alternating outward from anchor (higher, lower, …). */
function expandIntsFromAnchor(anchor: number, min: number, max: number): number[] {
  const c = Math.max(min, Math.min(max, Math.round(anchor)))
  const out: number[] = []
  const used = new Set<number>()
  const push = (n: number) => {
    const v = Math.max(min, Math.min(max, Math.round(n)))
    if (!used.has(v)) {
      used.add(v)
      out.push(v)
    }
  }
  push(c)
  for (let d = 1; out.length < max - min + 1; d++) {
    push(c + d)
    push(c - d)
  }
  return out
}

function alignRepsMenuScroll() {
  const root = repsMenuRef.value
  if (!root) return
  if (repsExpandAnchor.value != null) {
    root.scrollTop = 0
    return
  }

  if (props.index > 0) {
    const prior = (props.priorSetReps ?? '').trim()
    const n = parseInt(prior, 10)
    if (!Number.isNaN(n) && n >= 1 && n <= 50) {
      const btn = root.querySelector(`button[data-rep="${n}"]`) as HTMLElement | null
      if (btn) {
        const viewH = root.clientHeight
        const mid = btn.offsetTop + btn.offsetHeight / 2
        const maxScroll = Math.max(0, root.scrollHeight - viewH)
        root.scrollTop = Math.max(0, Math.min(mid - viewH / 2, maxScroll))
        return
      }
    }
  }

  const targetRep = repsScrollTargetMax.value
  if (targetRep == null) return

  const btn = root.querySelector(`button[data-rep="${targetRep}"]`) as HTMLElement | null
  if (!btn) return

  const rowH = btn.offsetHeight || 40
  root.scrollTop = Math.max(0, btn.offsetTop - REPS_MENU_TARGET_VISIBLE_INDEX * rowH)
}

/** Nearest 5 lb step in 0–500 for picker rows (stored lb string). */
function snapToPickerStoredLbs(storedRaw: string): string | null {
  const lbs = parseStoredLbs(storedRaw.trim())
  if (Number.isNaN(lbs) || lbs < 0) return null
  const snapped = Math.round(lbs / 5) * 5
  const c = Math.max(0, Math.min(500, snapped))
  return String(c)
}

const weightScrollSnapStored = computed((): string | null => {
  if (props.index === 0) {
    const g = (props.targetWeightStored ?? '').trim()
    if (!g) return null
    return snapToPickerStoredLbs(g)
  }
  const p = (props.priorSetWeightStored ?? '').trim()
  if (!p) return null
  return snapToPickerStoredLbs(p)
})

const weightMenuRef = ref<HTMLElement | null>(null)

/** Logged weight (lb) snapped to 5 lb; when set, picker scroll pins this row at top. */
const weightExpandAnchorSnapped = computed((): number | null => {
  const w = props.set.weight.trim()
  if (!w) return null
  const lbs = parseStoredLbs(w)
  if (Number.isNaN(lbs) || lbs < 0) return null
  return Math.max(0, Math.min(500, Math.round(lbs / 5) * 5))
})

const repsExpandAnchor = computed((): number | null => {
  const t = props.set.reps.trim()
  if (!t) return null
  const n = parseInt(t, 10)
  if (Number.isNaN(n) || n < 1 || n > 50) return null
  return n
})

/** Row to pin at top: logged weight if valid, else goal (set 1) or prior set’s weight. */
const weightMenuScrollTargetStored = computed((): string | null => {
  const typed = weightExpandAnchorSnapped.value
  if (typed != null) return String(typed)
  return weightScrollSnapStored.value
})

function alignWeightMenuScroll() {
  const root = weightMenuRef.value
  if (!root) return

  const storedKey = weightMenuScrollTargetStored.value
  if (!storedKey) {
    root.scrollTop = 0
    return
  }

  const btn = root.querySelector(`button[data-w-stored="${storedKey}"]`) as HTMLElement | null
  if (!btn) return
  root.scrollTop = btn.offsetTop
}

const visibleRepsOptions = computed(() => {
  const anchor = repsExpandAnchor.value
  if (anchor == null) return [...REP_QUICK_PICK_DESCENDING]
  return expandIntsFromAnchor(anchor, 1, 50).map(String)
})

/** Shown when reps is empty — goal text only, not a logged value. */
const repsPlaceholder = computed(() => {
  const g = props.targetReps?.trim()
  return g ? g : 'Reps'
})

/** Goal weight pinned row (first set only): shown at the top of the picker. */
const goalWeightRow = computed(() => {
  if (props.index !== 0) return null
  const g = (props.targetWeightStored ?? '').trim()
  if (!g) return null
  const snapped = snapToPickerStoredLbs(g)
  if (!snapped) return null
  const unit = weightUnit.value
  return { storedKey: snapped, display: storedLbsStringToDisplay(snapped, unit) }
})

/** 500, 495, … 0 lb — same order for every set; scroll pins goal / prior / typed row at top. */
const visibleWeightRows = computed(() => {
  const unit = weightUnit.value
  const storedKeys = Array.from({ length: 101 }, (_, i) => String(500 - i * 5))
  return storedKeys.map((key) => ({
    storedKey: key,
    display: storedLbsStringToDisplay(key, unit),
  }))
})

function onWeightInput(raw: string) {
  emit('update', 'weight', displayInputToStoredLbsString(raw, weightUnit.value))
}

function syncSetLoggingFocus() {
  const el = document.activeElement
  const inputFocused =
    el instanceof HTMLElement && el.matches('[data-workout-set-input]')
  if (showWeightMenu.value || showRepsMenu.value || inputFocused) {
    setLoggingFocus?.enter()
  } else {
    setLoggingFocus?.leave(0)
  }
}

async function onWeightFocus() {
  setLoggingFocus?.enter()
  cancelWeightMenuHide()
  showWeightMenu.value = true
  await nextTick()
  requestAnimationFrame(() => {
    alignWeightMenuScroll()
  })
}

async function onRepsFocus() {
  setLoggingFocus?.enter()
  cancelRepsMenuHide()
  showRepsMenu.value = true
  await nextTick()
  requestAnimationFrame(() => {
    alignRepsMenuScroll()
  })
}

watch([showWeightMenu, showRepsMenu], () => {
  syncSetLoggingFocus()
})

watch(
  () =>
    [
      props.set.weight,
      showWeightMenu.value,
      weightUnit.value,
      props.targetWeightStored,
      props.priorSetWeightStored,
      props.index,
    ] as const,
  async () => {
    if (!showWeightMenu.value) return
    await nextTick()
    requestAnimationFrame(() => {
      alignWeightMenuScroll()
    })
  },
)

watch(
  () =>
    [props.set.reps, showRepsMenu.value, props.priorSetReps, props.index] as const,
  async () => {
    if (!showRepsMenu.value) return
    await nextTick()
    requestAnimationFrame(() => {
      alignRepsMenuScroll()
    })
  },
)

function hideWeightMenuSoon() {
  if (weightMenuHideTimer) clearTimeout(weightMenuHideTimer)
  weightMenuHideTimer = window.setTimeout(() => {
    weightMenuHideTimer = null
    showWeightMenu.value = false
    syncSetLoggingFocus()
  }, MENU_HIDE_AFTER_BLUR_MS)
}

function hideRepsMenuSoon() {
  if (repsMenuHideTimer) clearTimeout(repsMenuHideTimer)
  repsMenuHideTimer = window.setTimeout(() => {
    repsMenuHideTimer = null
    showRepsMenu.value = false
    syncSetLoggingFocus()
  }, MENU_HIDE_AFTER_BLUR_MS)
}

function cancelWeightMenuHide() {
  if (weightMenuHideTimer) {
    clearTimeout(weightMenuHideTimer)
    weightMenuHideTimer = null
  }
}

function cancelRepsMenuHide() {
  if (repsMenuHideTimer) {
    clearTimeout(repsMenuHideTimer)
    repsMenuHideTimer = null
  }
}

function selectWeightOption(rawDisplay: string) {
  cancelWeightMenuHide()
  onWeightInput(rawDisplay)
  showWeightMenu.value = false
  syncSetLoggingFocus()
}

function selectRepsOption(raw: string) {
  cancelRepsMenuHide()
  emit('update', 'reps', raw)
  showRepsMenu.value = false
  syncSetLoggingFocus()
  maybeAdvanceAfterReps(raw)
}

function onRepsBlur() {
  hideRepsMenuSoon()
  maybeAdvanceAfterReps(props.set.reps)
}

function maybeAdvanceAfterReps(repsValue: string) {
  if (!settings.autoAdvanceRepsToWeight.value) return
  if (!props.nextSetId) return
  if (!repsValue.trim()) return
  window.setTimeout(() => emit('advanceToNextWeight'), MENU_HIDE_AFTER_BLUR_MS + 40)
}

function onWeightDoubleTap() {
  if (!settings.doubleTapCopyWeight.value) return
  if (props.index <= 0) return
  const prior = (props.priorSetWeightStored ?? '').trim()
  if (!prior) return
  haptic('tap')
  emit('update', 'weight', prior)
}

function onRepsDoubleTap() {
  if (!settings.doubleTapCopyWeight.value) return
  if (props.index <= 0) return
  const prior = (props.priorSetReps ?? '').trim()
  if (!prior) return
  haptic('tap')
  emit('update', 'reps', prior)
}
</script>

<template>
  <div
    class="relative mb-2 flex min-w-0 items-center gap-2"
    :class="isWarmup ? 'rounded-lg bg-amber-500/10 px-1 -mx-1' : ''"
  >
    <div class="flex w-14 shrink-0 flex-col items-center">
      <button
        type="button"
        class="rounded px-1 py-0.5 text-[11px] font-semibold transition-colors hover:bg-card-inner"
        :class="isWarmup ? 'text-amber-400' : 'text-muted hover:text-foreground'"
        :aria-pressed="isWarmup"
        :title="
          isWarmup
            ? 'Warmup set — excluded from progress. Tap to mark as working set.'
            : 'Tap to mark as warmup (excluded from progress)'
        "
        @click="emit('toggleWarmup')"
      >
        {{ isWarmup ? 'Warmup' : `Set ${index + 1}` }}
      </button>
      <span
        v-if="targetReps && !isWarmup"
        class="mt-0.5 text-[9px] font-bold text-primary"
      >{{ targetReps }}</span>
    </div>
    <div class="relative min-w-0 flex-1 basis-0">
      <input
        :value="storedLbsStringToDisplay(set.weight, weightUnit)"
        type="text"
        inputmode="decimal"
        data-touch-input
        data-workout-set-input
        :data-set-weight="set.id"
        class="min-w-0 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-base text-foreground outline-none focus:border-primary"
        :placeholder="weightUnit === 'lb' ? 'lb' : 'kg'"
        @focus="onWeightFocus"
        @blur="hideWeightMenuSoon"
        @dblclick="onWeightDoubleTap"
        @input="onWeightInput(($event.target as HTMLInputElement).value)"
      />
      <div
        v-if="showWeightMenu"
        ref="weightMenuRef"
        class="absolute left-0 right-0 top-full z-30 mt-1 max-h-40 overflow-y-auto rounded-lg border border-border bg-card shadow-lg"
      >
        <button
          v-if="goalWeightRow"
          type="button"
          class="block w-full border-b border-border px-2 py-1.5 text-center text-sm font-bold text-primary hover:bg-card-inner"
          @touchstart.passive="cancelWeightMenuHide"
          @mousedown.prevent="cancelWeightMenuHide"
          @click.prevent.stop="selectWeightOption(goalWeightRow.display)"
        >
          {{ goalWeightRow.display }}
        </button>
        <button
          v-for="row in visibleWeightRows"
          :key="`w-${set.id}-${row.storedKey}`"
          type="button"
          :data-w-stored="row.storedKey"
          class="block w-full px-2 py-1.5 text-center text-sm text-foreground hover:bg-card-inner"
          @touchstart.passive="cancelWeightMenuHide"
          @mousedown.prevent="cancelWeightMenuHide"
          @click.prevent.stop="selectWeightOption(row.display)"
        >
          {{ row.display }}
        </button>
      </div>
    </div>
    <div class="relative min-w-0 flex-1 basis-0">
      <input
        :value="set.reps"
        type="text"
        inputmode="numeric"
        data-touch-input
        data-workout-set-input
        class="min-w-0 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-base text-foreground outline-none focus:border-primary"
        :placeholder="repsPlaceholder"
        @focus="onRepsFocus"
        @blur="onRepsBlur"
        @dblclick="onRepsDoubleTap"
        @input="emit('update', 'reps', ($event.target as HTMLInputElement).value)"
      />
      <div
        v-if="showRepsMenu"
        ref="repsMenuRef"
        class="absolute left-0 right-0 top-full z-30 mt-1 max-h-40 overflow-y-auto rounded-lg border border-border bg-card shadow-lg"
      >
        <button
          v-for="opt in visibleRepsOptions"
          :key="`r-${set.id}-${opt}`"
          type="button"
          :data-rep="opt"
          class="block w-full px-2 py-1.5 text-center text-sm text-foreground hover:bg-card-inner"
          @touchstart.passive="cancelRepsMenuHide"
          @mousedown.prevent="cancelRepsMenuHide"
          @click.prevent.stop="selectRepsOption(opt)"
        >
          {{ opt }}
        </button>
      </div>
    </div>
    <div v-if="showDuration" class="relative min-w-0 flex-1 basis-0">
      <CoreDurationInput
        :model-value="set.durationSeconds ?? ''"
        :target-duration-seconds="targetDurationSeconds"
        placeholder="Time"
        @update:model-value="emit('update', 'durationSeconds', $event)"
      />
    </div>
    <button
      type="button"
      class="w-8 shrink-0 py-1 text-center text-sm text-muted"
      @click="emit('delete')"
    >
      ✕
    </button>
  </div>
</template>
