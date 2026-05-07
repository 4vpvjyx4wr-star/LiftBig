<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import { settingsInjectionKey } from '@/composables/injectionKeys'
import type { SetLog } from '@/types/workout'
import { displayInputToStoredLbsString, storedLbsStringToDisplay } from '@/utils/units'

const props = defineProps<{
  set: SetLog
  index: number
  targetReps?: string
}>()

const emit = defineEmits<{
  update: [field: 'reps' | 'weight', value: string]
  delete: []
}>()

const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)
const showWeightMenu = ref(false)
const showRepsMenu = ref(false)
const repsOptions = Array.from({ length: 50 }, (_, i) => String(i + 1))
const weightOptions = computed(() => {
  const out: string[] = []
  for (let lbs = 0; lbs <= 500; lbs += 2.5) {
    const stored = String(lbs)
    out.push(storedLbsStringToDisplay(stored, weightUnit.value))
  }
  return out
})

const visibleRepsOptions = computed(() => {
  const q = props.set.reps.trim()
  if (!q) return repsOptions
  return repsOptions.filter((opt) => opt.includes(q))
})

const visibleWeightOptions = computed(() => {
  const currentDisplay = storedLbsStringToDisplay(props.set.weight, weightUnit.value).trim()
  if (!currentDisplay) return weightOptions.value
  return weightOptions.value.filter((opt) => opt.includes(currentDisplay))
})

function onWeightInput(raw: string) {
  emit('update', 'weight', displayInputToStoredLbsString(raw, weightUnit.value))
}

function onWeightFocus() {
  showWeightMenu.value = true
}

function onRepsFocus() {
  showRepsMenu.value = true
}

function hideWeightMenuSoon() {
  window.setTimeout(() => {
    showWeightMenu.value = false
  }, 120)
}

function hideRepsMenuSoon() {
  window.setTimeout(() => {
    showRepsMenu.value = false
  }, 120)
}

function selectWeightOption(rawDisplay: string) {
  onWeightInput(rawDisplay)
  showWeightMenu.value = false
}

function selectRepsOption(raw: string) {
  emit('update', 'reps', raw)
  showRepsMenu.value = false
}
</script>

<template>
  <div class="relative mb-2 flex min-w-0 items-center gap-2">
    <div class="flex w-16 shrink-0 flex-col items-center">
      <span class="text-[11px] font-semibold text-muted">Set {{ index + 1 }}</span>
      <span v-if="targetReps" class="mt-0.5 text-[9px] font-bold text-primary">{{ targetReps }}</span>
    </div>
    <div class="relative min-w-0 flex-1 basis-0">
      <input
        :value="storedLbsStringToDisplay(set.weight, weightUnit)"
        type="text"
        inputmode="decimal"
        class="min-w-0 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-[15px] text-foreground outline-none focus:border-primary"
        :placeholder="weightUnit === 'lb' ? 'lb' : 'kg'"
        @focus="onWeightFocus"
        @blur="hideWeightMenuSoon"
        @input="onWeightInput(($event.target as HTMLInputElement).value)"
      />
      <div
        v-if="showWeightMenu"
        class="absolute left-0 right-0 top-full z-30 mt-1 max-h-40 overflow-y-auto rounded-lg border border-border bg-card shadow-lg"
      >
        <button
          v-for="opt in visibleWeightOptions"
          :key="`w-${set.id}-${opt}`"
          type="button"
          class="block w-full px-2 py-1.5 text-center text-sm text-foreground hover:bg-card-inner"
          @mousedown.prevent="selectWeightOption(opt)"
        >
          {{ opt }}
        </button>
      </div>
    </div>
    <div class="relative min-w-0 flex-1 basis-0">
      <input
        :value="set.reps"
        type="text"
        inputmode="numeric"
        class="min-w-0 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-[15px] text-foreground outline-none focus:border-primary"
        placeholder="Reps"
        @focus="onRepsFocus"
        @blur="hideRepsMenuSoon"
        @input="emit('update', 'reps', ($event.target as HTMLInputElement).value)"
      />
      <div
        v-if="showRepsMenu"
        class="absolute left-0 right-0 top-full z-30 mt-1 max-h-40 overflow-y-auto rounded-lg border border-border bg-card shadow-lg"
      >
        <button
          v-for="opt in visibleRepsOptions"
          :key="`r-${set.id}-${opt}`"
          type="button"
          class="block w-full px-2 py-1.5 text-center text-sm text-foreground hover:bg-card-inner"
          @mousedown.prevent="selectRepsOption(opt)"
        >
          {{ opt }}
        </button>
      </div>
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
