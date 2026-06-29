<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import CoreDurationInput from '@/components/workout/CoreDurationInput.vue'
import { settingsInjectionKey } from '@/composables/injectionKeys'
import type { Exercise } from '@/types/workout'
import { coreTargetTimeSeconds, parseSecondsFromGoalText } from '@/types/workout'
import { formatCircuitSetLine } from '@/utils/circuitExerciseDisplay'
import { haptic } from '@/utils/haptics'
import {
  displayInputToStoredLbsString,
  storedLbsStringToDisplay,
  type WeightUnit,
} from '@/utils/units'

const props = defineProps<{
  set: Exercise['sets'][number]
  index: number
  exercise: Exercise
  weightUnit: WeightUnit
}>()

const emit = defineEmits<{
  toggle: []
  update: [field: 'weight' | 'durationSeconds', value: string]
}>()

const settings = inject(settingsInjectionKey)!
const editing = ref(false)

const summaryLine = computed(() =>
  formatCircuitSetLine(props.set, props.exercise, props.weightUnit),
)

const durationGoalSeconds = computed(() => {
  const explicit = coreTargetTimeSeconds(props.exercise)
  if (explicit) return explicit
  const fromReps = parseSecondsFromGoalText(props.set.reps)
  if (fromReps != null) return String(fromReps)
  return parseSecondsFromGoalText(props.exercise.targetReps) != null
    ? String(parseSecondsFromGoalText(props.exercise.targetReps))
    : ''
})

function onWeightInput(raw: string) {
  emit('update', 'weight', displayInputToStoredLbsString(raw, settings.weightUnit.value))
}

function onToggleClick() {
  if (!props.set.checked) haptic('success')
  emit('toggle')
}
</script>

<template>
  <div class="mb-2 rounded-lg border border-border/60">
    <div class="flex w-full items-center gap-2 rounded-lg px-1 py-2">
      <button
        type="button"
        class="flex h-[26px] w-[26px] shrink-0 items-center justify-center rounded-md border-2 text-sm font-extrabold hover:bg-card-inner"
        :class="
          set.checked ? 'border-primary bg-primary text-foreground' : 'border-border text-muted'
        "
        :aria-pressed="set.checked"
        :aria-label="set.checked ? `Set ${index + 1} complete` : `Mark set ${index + 1} complete`"
        @click="onToggleClick"
      >
        {{ set.checked ? '✓' : '' }}
      </button>
      <span class="w-11 shrink-0 text-xs text-muted">Set {{ index + 1 }}</span>
      <span class="min-w-0 flex-1 text-[13px] text-foreground">{{ summaryLine }}</span>
      <button
        type="button"
        class="shrink-0 rounded px-2 py-1 text-muted hover:bg-card-inner hover:text-primary"
        :aria-expanded="editing"
        :aria-label="editing ? 'Close set editor' : 'Edit weight and duration'"
        @click="editing = !editing"
      >
        <i class="fa-solid fa-pen text-[11px]" aria-hidden="true" />
      </button>
    </div>

    <div
      v-if="editing"
      class="grid grid-cols-2 gap-2 border-t border-border/60 px-2 py-2.5"
      @click.stop
    >
      <div>
        <label class="mb-1 block text-[10px] font-bold uppercase tracking-wide text-muted">
          Weight
        </label>
        <input
          :value="storedLbsStringToDisplay(set.weight, weightUnit)"
          type="text"
          inputmode="decimal"
          data-touch-input
          data-workout-set-input
          class="w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-sm text-foreground outline-none focus:border-primary"
          :placeholder="weightUnit === 'lb' ? 'lb' : 'kg'"
          @input="onWeightInput(($event.target as HTMLInputElement).value)"
        />
      </div>
      <div>
        <label class="mb-1 block text-[10px] font-bold uppercase tracking-wide text-muted">
          Time (sec)
        </label>
        <CoreDurationInput
          :model-value="set.durationSeconds ?? ''"
          :target-duration-seconds="durationGoalSeconds || undefined"
          placeholder="Optional"
          @update:model-value="emit('update', 'durationSeconds', $event)"
        />
      </div>
    </div>
  </div>
</template>
