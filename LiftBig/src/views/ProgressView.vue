<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import ProgressChart from '@/components/progress/ProgressChart.vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import {
  collectExerciseHistory,
  listExerciseNamesFromLog,
  projectFutureStrength,
} from '@/utils/exerciseProgress'
import { formatWeightWithUnit } from '@/utils/units'

const workouts = inject(workoutsInjectionKey)!
const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)

const exerciseNames = computed(() => listExerciseNamesFromLog(workouts.log.value))

const selectedExercise = ref('')

watch(
  exerciseNames,
  (names) => {
    if (names.length === 0) {
      selectedExercise.value = ''
      return
    }
    if (!selectedExercise.value || !names.includes(selectedExercise.value)) {
      selectedExercise.value = names[0]!
    }
  },
  { immediate: true },
)

const history = computed(() =>
  selectedExercise.value
    ? collectExerciseHistory(workouts.log.value, selectedExercise.value)
    : [],
)

const futureProjection = computed(() =>
  selectedExercise.value && history.value.length > 0
    ? projectFutureStrength(history.value, selectedExercise.value)
    : [],
)

const lastSession = computed(() =>
  history.value.length ? history.value[history.value.length - 1]! : null,
)

const projectedEnd = computed(() =>
  futureProjection.value.length
    ? futureProjection.value[futureProjection.value.length - 1]!.projectedMaxWeightLbs
    : null,
)

function fmtLbs(lbs: number): string {
  return formatWeightWithUnit(lbs, weightUnit.value, 1)
}
</script>

<template>
  <div class="pb-6">
    <h1 class="mb-1 text-2xl font-black tracking-tight text-foreground">Progress</h1>
    <p class="mb-5 text-sm leading-relaxed text-muted">
      Pick an exercise to see max weight and average reps over time. The dashed line projects future
      strength using your recent trend, capped each session by the same progressive overload jump used
      when suggesting weights (so projections stay grounded).
    </p>

    <template v-if="exerciseNames.length === 0">
      <div class="rounded-2xl border border-border bg-card-inner px-4 py-10 text-center">
        <p class="text-sm font-semibold text-foreground">No exercises logged yet</p>
        <p class="mt-2 text-xs text-muted">
          Complete workouts with named exercises to track strength and reps here.
        </p>
      </div>
    </template>

    <template v-else>
      <label class="mb-3 block">
        <span class="mb-1.5 block text-[11px] font-bold uppercase tracking-wide text-muted">
          Exercise
        </span>
        <select
          v-model="selectedExercise"
          class="w-full rounded-xl border border-border bg-card px-3 py-3 text-base font-bold text-foreground outline-none focus:border-primary"
        >
          <option v-for="name in exerciseNames" :key="name" :value="name">
            {{ name }}
          </option>
        </select>
      </label>

      <div
        v-if="history.length > 0"
        class="mb-4 grid grid-cols-2 gap-2 text-center sm:grid-cols-3"
      >
        <div class="rounded-xl border border-border bg-card-inner px-3 py-3">
          <div class="text-[10px] font-bold uppercase text-muted">Sessions</div>
          <div class="mt-1 text-lg font-black text-foreground">{{ history.length }}</div>
        </div>
        <div class="rounded-xl border border-border bg-card-inner px-3 py-3">
          <div class="text-[10px] font-bold uppercase text-muted">Latest max</div>
          <div class="mt-1 text-lg font-black text-foreground">
            {{ lastSession ? fmtLbs(lastSession.maxWeightLbs) : '—' }}
          </div>
        </div>
        <div
          class="col-span-2 rounded-xl border border-border bg-card-inner px-3 py-3 sm:col-span-1"
        >
          <div class="text-[10px] font-bold uppercase text-muted">Projected (10 sessions)</div>
          <div class="mt-1 text-lg font-black text-primary">
            {{ projectedEnd != null ? fmtLbs(projectedEnd) : '—' }}
          </div>
        </div>
      </div>

      <ProgressChart
        :history="history"
        :future="futureProjection"
        :weight-unit="weightUnit"
      />
    </template>
  </div>
</template>
