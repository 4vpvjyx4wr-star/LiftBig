<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import type { Exercise, WorkoutLog } from '@/types/workout'
import { getSuggestedWeight } from '@/utils/progressiveOverload'
import SetRow from '@/components/workout/SetRow.vue'

const props = defineProps<{
  exercise: Exercise
  workoutLog: WorkoutLog
}>()

const emit = defineEmits<{
  addSet: []
  updateSet: [setId: string, field: 'reps' | 'weight', value: string]
  toggleCircuitSet: [setId: string]
  deleteSet: [setId: string]
  deleteExercise: []
}>()

const suggestion = ref<{ suggestedWeight: number; reason: string } | null>(null)

watch(
  () => [props.exercise.name, props.exercise.targetReps, props.exercise.sets, props.workoutLog] as const,
  () => {
    if (props.exercise.isCircuit || !props.exercise.targetReps) {
      suggestion.value = null
      return
    }
    const base = parseFloat(
      props.exercise.sets[0]?.weight || props.exercise.targetWeight || '0',
    )
    suggestion.value = getSuggestedWeight(
      props.exercise.name,
      props.exercise.targetReps,
      base,
      props.workoutLog,
    )
  },
  { deep: true, immediate: true },
)

const completedSets = computed(() =>
  props.exercise.sets.filter((s) =>
    props.exercise.isCircuit ? s.checked : s.reps !== '' && s.weight !== '',
  ).length,
)

const allDone = computed(
  () =>
    completedSets.value === props.exercise.sets.length && props.exercise.sets.length > 0,
)
</script>

<template>
  <div
    class="mb-3.5 rounded-xl border border-border bg-card p-3.5"
    :class="allDone ? 'border-[#16a34a]' : ''"
  >
    <div class="mb-2 flex justify-between gap-2">
      <div class="min-w-0 flex-1">
        <h4 class="text-base font-bold text-foreground">{{ exercise.name }}</h4>
        <p
          v-if="exercise.targetReps && !exercise.isCircuit"
          class="mt-0.5 text-[11px] text-muted"
        >
          Goal: {{ exercise.sets.length }} × {{ exercise.targetReps }}
          <template v-if="exercise.targetWeight"> @ {{ exercise.targetWeight }} lbs</template>
        </p>
      </div>
      <div class="flex shrink-0 flex-col items-end gap-1">
        <span
          class="text-[11px] font-bold"
          :class="allDone ? 'text-[#4ade80]' : 'text-muted'"
        >
          {{ allDone ? 'Complete' : `${completedSets}/${exercise.sets.length} sets` }}
        </span>
        <button
          type="button"
          class="text-xs font-semibold text-red-400"
          @click="emit('deleteExercise')"
        >
          Remove
        </button>
      </div>
    </div>

    <div
      v-if="suggestion && !exercise.isCircuit && suggestion.reason !== 'No history yet'"
      class="mb-2.5 rounded-lg border border-[#16a34a] bg-[#0d2010] p-2"
    >
      <div class="text-[13px] font-bold text-[#4ade80]">
        Suggested: {{ suggestion.suggestedWeight }} lbs
      </div>
      <div class="mt-0.5 text-[11px] text-[#86efac]">{{ suggestion.reason }}</div>
    </div>

    <template v-if="exercise.isCircuit">
      <button
        v-for="(set, index) in exercise.sets"
        :key="set.id"
        type="button"
        class="mb-2 flex w-full items-center gap-3 rounded-lg py-2 text-left hover:bg-card-inner"
        @click="emit('toggleCircuitSet', set.id)"
      >
        <span
          class="flex h-[26px] w-[26px] items-center justify-center rounded-md border-2 text-sm font-extrabold"
          :class="
            set.checked ? 'border-primary bg-primary text-foreground' : 'border-border text-muted'
          "
        >
          {{ set.checked ? '✓' : '' }}
        </span>
        <span class="w-11 text-xs text-muted">Set {{ index + 1 }}</span>
        <span class="flex-1 text-[13px] text-foreground">
          {{ set.reps || 'AMRAP' }} reps @ {{ set.weight || '20' }} lbs
        </span>
      </button>
    </template>

    <template v-else>
      <div class="mb-1 flex">
        <span class="w-16" />
        <span class="flex-1 text-center text-[10px] font-bold uppercase text-muted">Reps</span>
        <span class="flex-1 text-center text-[10px] font-bold uppercase text-muted">Weight</span>
        <span class="w-8" />
      </div>
      <SetRow
        v-for="(set, index) in exercise.sets"
        :key="set.id"
        :set="set"
        :index="index"
        :target-reps="exercise.targetReps"
        @update="(f, v) => emit('updateSet', set.id, f, v)"
        @delete="emit('deleteSet', set.id)"
      />
      <button
        type="button"
        class="mt-1 text-sm font-semibold text-primary"
        @click="emit('addSet')"
      >
        + Add Set
      </button>
    </template>
  </div>
</template>
