<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import CardioProgressChart from '@/components/progress/CardioProgressChart.vue'
import ProgressChart from '@/components/progress/ProgressChart.vue'
import WeeklyVolumeSummary from '@/components/progress/WeeklyVolumeSummary.vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import {
  collectCardioHistory,
  listCardioExerciseNamesFromLog,
} from '@/utils/cardioProgress'
import {
  collectExerciseHistory,
  listExerciseNamesFromLog,
  projectFutureStrength,
} from '@/utils/exerciseProgress'
import { formatWeightWithUnit } from '@/utils/units'

const workouts = inject(workoutsInjectionKey)!
const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)
const distanceUnit = computed(() => settings.distanceUnit.value)

const progressMode = ref<'strength' | 'cardio'>('strength')

const exerciseNames = computed(() => listExerciseNamesFromLog(workouts.log.value))
const cardioNames = computed(() => listCardioExerciseNamesFromLog(workouts.log.value))

const exerciseQuery = ref('')
const selectedExercise = ref('')
const showSuggestions = ref(false)

const cardioQuery = ref('')
const selectedCardio = ref('')
const showCardioSuggestions = ref(false)

const activeNames = computed(() =>
  progressMode.value === 'cardio' ? cardioNames.value : exerciseNames.value,
)

const filteredExerciseNames = computed(() => {
  const q = exerciseQuery.value.trim().toLowerCase()
  // Show every option when the box is empty or still holds the current selection,
  // so focusing the field reveals the full list rather than just the picked name.
  if (!q || exerciseQuery.value === selectedExercise.value) return exerciseNames.value
  return exerciseNames.value.filter((name) => name.toLowerCase().includes(q))
})

const filteredCardioNames = computed(() => {
  const q = cardioQuery.value.trim().toLowerCase()
  if (!q || cardioQuery.value === selectedCardio.value) return cardioNames.value
  return cardioNames.value.filter((name) => name.toLowerCase().includes(q))
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

watch(
  cardioNames,
  (names) => {
    if (names.length === 0) {
      selectedCardio.value = ''
      cardioQuery.value = ''
      return
    }
    if (!selectedCardio.value || !names.includes(selectedCardio.value)) {
      const first = names[0]!
      selectedCardio.value = first
      cardioQuery.value = first
    }
  },
  { immediate: true },
)

watch(progressMode, (mode) => {
  if (mode === 'cardio' && cardioNames.value.length === 0) {
    progressMode.value = 'strength'
  }
})

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

function pickCardio(name: string) {
  selectedCardio.value = name
  cardioQuery.value = name
  showCardioSuggestions.value = false
}

function confirmCardioQuery() {
  const q = cardioQuery.value.trim()
  if (!q) return
  const exact = cardioNames.value.find((name) => name.toLowerCase() === q.toLowerCase())
  if (exact) {
    pickCardio(exact)
    return
  }
  const matches = filteredCardioNames.value
  if (matches.length === 1) {
    pickCardio(matches[0]!)
    return
  }
  selectedCardio.value = q
  showCardioSuggestions.value = false
}

function hideCardioSuggestionsSoon() {
  window.setTimeout(() => {
    showCardioSuggestions.value = false
    const q = cardioQuery.value.trim()
    if (!q) return
    const exact = cardioNames.value.find((name) => name.toLowerCase() === q.toLowerCase())
    if (exact) pickCardio(exact)
  }, 120)
}

const history = computed(() =>
  selectedExercise.value
    ? collectExerciseHistory(workouts.log.value, selectedExercise.value)
    : [],
)

const cardioHistory = computed(() =>
  selectedCardio.value
    ? collectCardioHistory(workouts.log.value, selectedCardio.value)
    : [],
)

const lastCardioSession = computed(() =>
  cardioHistory.value.length ? cardioHistory.value[cardioHistory.value.length - 1]! : null,
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
    <p class="mb-4 text-sm leading-relaxed text-muted">
      Track strength or cardio over time. Strength charts project future max using your recent trend.
    </p>

    <div
      v-if="exerciseNames.length > 0 || cardioNames.length > 0"
      class="mb-4 flex rounded-xl border border-border bg-card p-1"
    >
      <button
        type="button"
        class="flex-1 rounded-lg py-2.5 text-sm font-bold transition-colors"
        :class="progressMode === 'strength' ? 'bg-primary text-foreground' : 'text-muted'"
        :disabled="exerciseNames.length === 0"
        @click="progressMode = 'strength'"
      >
        Strength
      </button>
      <button
        type="button"
        class="flex-1 rounded-lg py-2.5 text-sm font-bold transition-colors"
        :class="progressMode === 'cardio' ? 'bg-primary text-foreground' : 'text-muted'"
        :disabled="cardioNames.length === 0"
        @click="progressMode = 'cardio'"
      >
        Cardio
      </button>
    </div>

    <template v-if="activeNames.length === 0">
      <div class="rounded-2xl border border-border bg-card-inner px-4 py-10 text-center">
        <p class="text-sm font-semibold text-foreground">No exercises logged yet</p>
        <p class="mt-2 text-xs text-muted">
          Complete workouts with named exercises to track strength and reps here.
        </p>
      </div>
    </template>

    <template v-else-if="progressMode === 'strength'">
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
            @focus="showSuggestions = true; ($event.target as HTMLInputElement).select()"
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

    <template v-else>
      <label class="mb-3 block">
        <span class="mb-1.5 block text-[11px] font-bold uppercase tracking-wide text-muted">
          Cardio activity
        </span>
        <div class="relative">
          <input
            v-model="cardioQuery"
            type="search"
            autocomplete="off"
            class="w-full rounded-xl border border-border bg-card px-3 py-3 text-base font-bold text-foreground outline-none focus:border-primary"
            placeholder="Search logged cardio..."
            @focus="showCardioSuggestions = true; ($event.target as HTMLInputElement).select()"
            @blur="hideCardioSuggestionsSoon"
            @keydown.enter.prevent="confirmCardioQuery"
          />
          <div
            v-if="showCardioSuggestions && filteredCardioNames.length > 0"
            class="absolute left-0 right-0 top-full z-20 mt-1 max-h-52 overflow-y-auto rounded-xl border border-border bg-card p-1 shadow-lg"
            @mousedown.prevent
          >
            <button
              v-for="name in filteredCardioNames"
              :key="name"
              type="button"
              class="block w-full rounded-lg px-3 py-2.5 text-left text-sm font-semibold text-foreground hover:bg-card-inner"
              @click="pickCardio(name)"
            >
              {{ name }}
            </button>
          </div>
        </div>
      </label>

      <div
        v-if="cardioHistory.length > 0"
        class="mb-4 grid grid-cols-2 gap-2 text-center sm:grid-cols-3"
      >
        <div class="rounded-xl border border-border bg-card-inner px-3 py-3">
          <div class="text-[10px] font-bold uppercase text-muted">Sessions</div>
          <div class="mt-1 text-lg font-black text-foreground">{{ cardioHistory.length }}</div>
        </div>
        <div class="rounded-xl border border-border bg-card-inner px-3 py-3">
          <div class="text-[10px] font-bold uppercase text-muted">Latest duration</div>
          <div class="mt-1 text-lg font-black text-foreground">
            {{ lastCardioSession ? `${lastCardioSession.durationMinutes} min` : '—' }}
          </div>
        </div>
        <div class="col-span-2 rounded-xl border border-border bg-card-inner px-3 py-3 sm:col-span-1">
          <div class="text-[10px] font-bold uppercase text-muted">Latest pace</div>
          <div class="mt-1 text-lg font-black text-primary">
            {{
              lastCardioSession?.paceMinutesPerUnit != null
                ? `${lastCardioSession.paceMinutesPerUnit} min/unit`
                : '—'
            }}
          </div>
        </div>
      </div>

      <div
        v-else-if="selectedCardio"
        class="mb-4 rounded-2xl border border-border bg-card-inner px-4 py-8 text-center"
      >
        <p class="text-sm font-semibold text-foreground">No cardio data for this activity</p>
        <p class="mt-2 text-xs text-muted">
          Log duration (and distance when available) for “{{ selectedCardio }}”.
        </p>
      </div>

      <CardioProgressChart :history="cardioHistory" :distance-unit="distanceUnit" />
    </template>

    <WeeklyVolumeSummary class="mt-5" />
  </div>
</template>
