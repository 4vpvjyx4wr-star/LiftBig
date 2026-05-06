<script setup lang="ts">
import { computed, inject } from 'vue'
import { settingsInjectionKey } from '@/composables/injectionKeys'
import type { SetLog } from '@/types/workout'
import { displayInputToStoredLbsString, storedLbsStringToDisplay } from '@/utils/units'

defineProps<{
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
const repsOptions = Array.from({ length: 50 }, (_, i) => String(i + 1))
const weightOptions = computed(() => {
  const out: string[] = []
  for (let lbs = 0; lbs <= 500; lbs += 2.5) {
    const stored = String(lbs)
    out.push(storedLbsStringToDisplay(stored, weightUnit.value))
  }
  return out
})

function onWeightInput(raw: string) {
  emit('update', 'weight', displayInputToStoredLbsString(raw, weightUnit.value))
}
</script>

<template>
  <div class="mb-2 flex min-w-0 items-center gap-2">
    <div class="flex w-16 shrink-0 flex-col items-center">
      <span class="text-[11px] font-semibold text-muted">Set {{ index + 1 }}</span>
      <span v-if="targetReps" class="mt-0.5 text-[9px] font-bold text-primary">{{ targetReps }}</span>
    </div>
    <input
      :value="storedLbsStringToDisplay(set.weight, weightUnit)"
      type="text"
      inputmode="decimal"
      :list="`weight-options-${set.id}`"
      class="min-w-0 flex-1 basis-0 rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-[15px] text-foreground outline-none focus:border-primary"
      :placeholder="weightUnit === 'lb' ? 'lb' : 'kg'"
      @input="onWeightInput(($event.target as HTMLInputElement).value)"
    />
    <datalist :id="`weight-options-${set.id}`">
      <option v-for="opt in weightOptions" :key="`w-${set.id}-${opt}`" :value="opt" />
    </datalist>
    <input
      :value="set.reps"
      type="text"
      inputmode="numeric"
      :list="`reps-options-${set.id}`"
      class="min-w-0 flex-1 basis-0 rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-[15px] text-foreground outline-none focus:border-primary"
      placeholder="Reps"
      @input="emit('update', 'reps', ($event.target as HTMLInputElement).value)"
    />
    <datalist :id="`reps-options-${set.id}`">
      <option v-for="opt in repsOptions" :key="`r-${set.id}-${opt}`" :value="opt" />
    </datalist>
    <button
      type="button"
      class="w-8 shrink-0 py-1 text-center text-sm text-muted"
      @click="emit('delete')"
    >
      ✕
    </button>
  </div>
</template>
