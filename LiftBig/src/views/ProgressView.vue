<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import ProgressChart from '@/components/progress/ProgressChart.vue'
import WeeklyVolumeSummary from '@/components/progress/WeeklyVolumeSummary.vue'
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

const exerciseQuery = ref('')
const selectedExercise = ref('')
const showSuggestions = ref(false)

const filteredExerciseNames = computed(() => {
  const q = exerciseQuery.value.trim().toLowerCase()
  if (!q) return exerciseNames.value
  return exerciseNames.value.filter((name) => name.toLowerCase().includes(q))
})

watch(
  exerciseNames,
  (names) => {
    if (names.length === 0) {
      selectedExercise.value = ''
      exerciseQuery.value = ''
      return
    }
    if (!selectedExercise.value || !names.includes(selectedExercise.value)) {
      const first = names[0]!
      selectedExercise.value = first
      exerciseQuery.value = first
    }
  },
  { immediate: true },
)

function pickExercise(name: string) {
  selectedExercise.value = name
  exerciseQuery.value = name
  showSuggestions.value = false
}

function confirmExerciseQuery() {
  const q = exerciseQuery.value.trim()
  if (!q) return
  const exact = exerciseNames.value.find((name) => name.toLowerCase() === q.toLowerCase())
  if (exact) {
    pickExercise(exact)
    return
  }
  const matches = filteredExerciseNames.value
  if (matches.length === 1) {
    pickExercise(matches[0]!)
    return
  }
  selectedExercise.value = q
  showSuggestions.value = false
}

function hideSuggestionsSoon() {
  window.setTimeout(() => {
    showSuggestions.value = false
    const q = exerciseQuery.value.trim()
    if (!q) return
    const exact = exerciseNames.value.find((name) => name.toLowerCase() === q.toLowerCase())
    if (exact) pickExercise(exact)
  }, 120)
}

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
      Type or pick an exercise to see max weight and average reps over time. The dashed line projects future
      strength using your recent trend, capped each session by the same progressive overload jump used
      when suggesting weights (so projections stay grounded).
    </p>

    <WeeklyVolumeSummary />

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
        <div class="relative">
          <input
            v-model="exerciseQuery"
            type="search"
            autocomplete="off"
            class="w-full rounded-xl border border-border bg-card px-3 py-3 text-base font-bold text-foreground outline-none focus:border-primary"
            placeholder="Search logged exercises..."
            @focus="showSuggestions = true"
            @blur="hideSuggestionsSoon"
            @keydown.enter.prevent="confirmExerciseQuery"
          />
          <div
            v-if="showSuggestions && filteredExerciseNames.length > 0"
            class="absolute left-0 right-0 top-full z-20 mt-1 max-h-52 overflow-y-auto rounded-xl border border-border bg-card p-1 shadow-lg"
            @mousedown.prevent
          >
            <button
              v-for="name in filteredExerciseNames"
              :key="name"
              type="button"
              class="block w-full rounded-lg px-3 py-2.5 text-left text-sm font-semibold text-foreground hover:bg-card-inner"
              @click="pickExercise(name)"
            >
              {{ name }}
            </button>
          </div>
        </div>
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

      <div
        v-else-if="selectedExercise"
        class="mb-4 rounded-2xl border border-border bg-card-inner px-4 py-8 text-center"
      >
        <p class="text-sm font-semibold text-foreground">No progress data for this exercise</p>
        <p class="mt-2 text-xs text-muted">
          Log sets with weight and reps for “{{ selectedExercise }}” to see charts here.
        </p>
      </div>

      <ProgressChart
        :history="history"
        :future="futureProjection"
        :weight-unit="weightUnit"
      />
    </template>
  </div>
</template>
