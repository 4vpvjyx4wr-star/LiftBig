<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import ProgressStatGrid, { type StatTile } from '@/components/progress/ProgressStatGrid.vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import {
  computeTrainingStats,
  formatAllTimeLabel,
  formatMonthLabel,
  formatTodayLabel,
  formatWeekLabel,
  getAllTimeRange,
  getMonthRangeForDate,
  getPreviousMonthRange,
  getPreviousWeekRange,
  getTodayRange,
  getWeekRangeForDate,
  trainingStatsDelta,
} from '@/utils/trainingStats'
import { planDurationAssumptionsFromSeconds } from '@/utils/planDuration'
import { formatWeightWithUnit } from '@/utils/units'

const workouts = inject(workoutsInjectionKey)!
const settings = inject(settingsInjectionKey)!

const weightUnit = computed(() => settings.weightUnit.value)
const statsOptions = computed(() => ({
  bodyWeightLbs: settings.bodyWeightLbs.value,
  planAssumptions: planDurationAssumptionsFromSeconds(
    settings.averageLiftSeconds.value,
    settings.averageRestSeconds.value,
  ),
}))

const todayRange = computed(() => getTodayRange())
const thisWeekRange = computed(() => getWeekRangeForDate())
const lastWeekRange = computed(() => getPreviousWeekRange(thisWeekRange.value))
const thisMonthRange = computed(() => getMonthRangeForDate())
const lastMonthRange = computed(() => getPreviousMonthRange(thisMonthRange.value))
const allTimeRange = computed(() => getAllTimeRange(workouts.log.value))

const todayStats = computed(() =>
  computeTrainingStats(workouts.log.value, todayRange.value, statsOptions.value),
)
const thisWeekStats = computed(() =>
  computeTrainingStats(workouts.log.value, thisWeekRange.value, statsOptions.value),
)
const lastWeekStats = computed(() =>
  computeTrainingStats(workouts.log.value, lastWeekRange.value, statsOptions.value),
)
const thisMonthStats = computed(() =>
  computeTrainingStats(workouts.log.value, thisMonthRange.value, statsOptions.value),
)
const lastMonthStats = computed(() =>
  computeTrainingStats(workouts.log.value, lastMonthRange.value, statsOptions.value),
)
const allTimeStats = computed(() =>
  computeTrainingStats(workouts.log.value, allTimeRange.value, statsOptions.value),
)

const weekDelta = computed(() => trainingStatsDelta(thisWeekStats.value, lastWeekStats.value))
const monthDelta = computed(() => trainingStatsDelta(thisMonthStats.value, lastMonthStats.value))

type HistoricalTab = 'last-week' | 'last-month' | 'all-time'
const historicalTab = ref<HistoricalTab>('last-week')

const historicalStats = computed(() => {
  if (historicalTab.value === 'last-week') return lastWeekStats.value
  if (historicalTab.value === 'last-month') return lastMonthStats.value
  return allTimeStats.value
})

const historicalLabel = computed(() => {
  if (historicalTab.value === 'last-week') return formatWeekLabel(lastWeekRange.value)
  if (historicalTab.value === 'last-month') return formatMonthLabel(lastMonthRange.value)
  return formatAllTimeLabel(allTimeRange.value)
})

function fmtTonnage(lbs: number): string {
  if (lbs <= 0) return '—'
  return formatWeightWithUnit(lbs, weightUnit.value, 0)
}

function fmtWeight(lbs: number): string {
  if (lbs <= 0) return '—'
  return formatWeightWithUnit(lbs, weightUnit.value, 0)
}

function fmtDeltaCount(n: number, prefix = 'vs prior'): string {
  if (n === 0) return `${prefix} —`
  const sign = n > 0 ? '↑' : '↓'
  return `${prefix} ${sign}${Math.abs(n)}`
}

function fmtTonnageDelta(n: number, prefix = 'vs prior'): string {
  if (n === 0) return `${prefix} —`
  const sign = n > 0 ? '↑' : '↓'
  return `${prefix} ${sign}${formatWeightWithUnit(Math.abs(n), weightUnit.value, 0)}`
}

function deltaPositive(n: number): boolean | null {
  if (n === 0) return null
  return n > 0
}

function fmtCardio(minutes: number): string {
  if (minutes <= 0) return '—'
  if (minutes < 60) return `${minutes}m`
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return m > 0 ? `${h}h ${m}m` : `${h}h`
}

function fmtCalories(n: number | null): string {
  if (n == null || n <= 0) return '—'
  return `~${n.toLocaleString()}`
}

function fmtCore(seconds: number): string {
  if (seconds <= 0) return '—'
  if (seconds < 60) return `${seconds}s`
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return s > 0 ? `${m}m ${s}s` : `${m}m`
}

const todayTiles = computed((): StatTile[] => {
  const s = todayStats.value
  return [
    { key: 'sets', label: 'Sets', value: String(s.totalSets) },
    { key: 'reps', label: 'Reps', value: s.totalReps > 0 ? s.totalReps.toLocaleString() : '—' },
    { key: 'tonnage', label: 'Tonnage', value: fmtTonnage(s.tonnageLbs) },
    {
      key: 'exercises',
      label: 'Exercises',
      value: s.uniqueExercises > 0 ? String(s.uniqueExercises) : '—',
    },
    {
      key: 'heaviest',
      label: 'Heaviest',
      value: fmtWeight(s.heaviestSetLbs),
      hint: s.heaviestSetLabel ?? undefined,
    },
    { key: 'cardio', label: 'Cardio', value: fmtCardio(s.cardioMinutes) },
    { key: 'prs', label: 'PRs today', value: s.personalBests > 0 ? String(s.personalBests) : '—' },
    {
      key: 'muscles',
      label: 'Muscle groups',
      value: s.uniqueMuscleGroups > 0 ? String(s.uniqueMuscleGroups) : '—',
    },
  ]
})

const weekTiles = computed((): StatTile[] => {
  const s = thisWeekStats.value
  const d = weekDelta.value
  return [
    {
      key: 'sets',
      label: 'Sets',
      value: String(s.totalSets),
      delta: fmtDeltaCount(d.sets),
      deltaPositive: deltaPositive(d.sets),
    },
    {
      key: 'reps',
      label: 'Reps',
      value: s.totalReps > 0 ? s.totalReps.toLocaleString() : '—',
      delta: fmtDeltaCount(d.reps),
      deltaPositive: deltaPositive(d.reps),
    },
    {
      key: 'tonnage',
      label: 'Tonnage',
      value: fmtTonnage(s.tonnageLbs),
      delta: fmtTonnageDelta(d.tonnageLbs),
      deltaPositive: deltaPositive(d.tonnageLbs),
    },
    {
      key: 'days',
      label: 'Days',
      value: String(s.trainedDays),
      delta: fmtDeltaCount(d.days),
      deltaPositive: deltaPositive(d.days),
    },
    {
      key: 'exercises',
      label: 'Exercises',
      value: s.uniqueExercises > 0 ? String(s.uniqueExercises) : '—',
      delta: fmtDeltaCount(d.uniqueExercises),
      deltaPositive: deltaPositive(d.uniqueExercises),
    },
    {
      key: 'cardio',
      label: 'Cardio',
      value: fmtCardio(s.cardioMinutes),
      delta: fmtDeltaCount(d.cardioMinutes, 'vs prior'),
      deltaPositive: deltaPositive(d.cardioMinutes),
    },
    {
      key: 'prs',
      label: 'PRs',
      value: s.personalBests > 0 ? String(s.personalBests) : '—',
      delta: fmtDeltaCount(d.personalBests),
      deltaPositive: deltaPositive(d.personalBests),
    },
    {
      key: 'avg',
      label: 'Avg sets/day',
      value: s.avgSetsPerTrainingDay > 0 ? String(s.avgSetsPerTrainingDay) : '—',
    },
    {
      key: 'top',
      label: 'Top focus',
      value: s.topMuscleGroup ?? '—',
    },
    {
      key: 'calories',
      label: 'Est. burn',
      value: fmtCalories(s.estimatedCalories),
    },
  ]
})

const monthTiles = computed((): StatTile[] => {
  const s = thisMonthStats.value
  const d = monthDelta.value
  return [
    {
      key: 'sets',
      label: 'Sets',
      value: String(s.totalSets),
      delta: fmtDeltaCount(d.sets, 'vs last mo'),
      deltaPositive: deltaPositive(d.sets),
    },
    {
      key: 'reps',
      label: 'Reps',
      value: s.totalReps > 0 ? s.totalReps.toLocaleString() : '—',
      delta: fmtDeltaCount(d.reps, 'vs last mo'),
      deltaPositive: deltaPositive(d.reps),
    },
    {
      key: 'tonnage',
      label: 'Tonnage',
      value: fmtTonnage(s.tonnageLbs),
      delta: fmtTonnageDelta(d.tonnageLbs, 'vs last mo'),
      deltaPositive: deltaPositive(d.tonnageLbs),
    },
    {
      key: 'days',
      label: 'Days',
      value: String(s.trainedDays),
      delta: fmtDeltaCount(d.days, 'vs last mo'),
      deltaPositive: deltaPositive(d.days),
    },
    {
      key: 'consistency',
      label: 'Consistency',
      value: s.consistencyPct != null ? `${s.consistencyPct}%` : '—',
    },
    {
      key: 'exercises',
      label: 'Exercises',
      value: s.uniqueExercises > 0 ? String(s.uniqueExercises) : '—',
    },
    {
      key: 'prs',
      label: 'PRs',
      value: s.personalBests > 0 ? String(s.personalBests) : '—',
    },
    {
      key: 'cardio',
      label: 'Cardio',
      value: fmtCardio(s.cardioMinutes),
    },
    {
      key: 'core',
      label: 'Core time',
      value: fmtCore(s.coreHoldSeconds),
    },
    {
      key: 'calories',
      label: 'Est. burn',
      value: fmtCalories(s.estimatedCalories),
    },
  ]
})

const historicalTiles = computed((): StatTile[] => {
  const s = historicalStats.value
  return [
    { key: 'sets', label: 'Sets', value: String(s.totalSets) },
    {
      key: 'reps',
      label: 'Reps',
      value: s.totalReps > 0 ? s.totalReps.toLocaleString() : '—',
    },
    { key: 'tonnage', label: 'Tonnage', value: fmtTonnage(s.tonnageLbs) },
    { key: 'days', label: 'Training days', value: String(s.trainedDays) },
    {
      key: 'exercises',
      label: 'Exercises',
      value: s.uniqueExercises > 0 ? String(s.uniqueExercises) : '—',
    },
    { key: 'cardio', label: 'Cardio', value: fmtCardio(s.cardioMinutes) },
    {
      key: 'heaviest',
      label: 'Heaviest lift',
      value: fmtWeight(s.heaviestSetLbs),
      hint: s.heaviestSetLabel ?? undefined,
    },
    { key: 'prs', label: 'PRs', value: s.personalBests > 0 ? String(s.personalBests) : '—' },
    {
      key: 'circuits',
      label: 'Circuits',
      value: s.circuitSets > 0 ? String(s.circuitSets) : '—',
    },
    { key: 'calories', label: 'Est. burn', value: fmtCalories(s.estimatedCalories) },
  ]
})

const historicalTabs: { id: HistoricalTab; label: string }[] = [
  { id: 'last-week', label: 'Last week' },
  { id: 'last-month', label: 'Last month' },
  { id: 'all-time', label: 'All time' },
]
</script>

<template>
  <div class="pb-6">
    <h1 class="mb-1 text-2xl font-black tracking-tight text-foreground">Progress</h1>
    <p class="mb-4 text-sm leading-relaxed text-muted">
      Training snapshots from your journal — today, this week, and beyond. Open any logged exercise
      in the Library for strength and cardio charts.
    </p>

    <!-- Today -->
    <section class="mb-5 rounded-2xl border border-border bg-card-inner p-4">
      <div class="mb-3 flex items-baseline justify-between gap-2">
        <h2 class="flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">
          <i class="fa-solid fa-sun text-primary" aria-hidden="true" />
          Today
        </h2>
        <span class="text-[11px] font-semibold text-muted">{{ formatTodayLabel() }}</span>
      </div>
      <ProgressStatGrid :tiles="todayTiles" :columns="4" />
    </section>

    <!-- This week -->
    <section class="mb-5 rounded-2xl border border-border bg-card-inner p-4">
      <div class="mb-3 flex items-baseline justify-between gap-2">
        <h2 class="flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">
          <i class="fa-solid fa-calendar-week text-primary" aria-hidden="true" />
          This week
        </h2>
        <span class="text-[11px] font-semibold text-muted">{{ formatWeekLabel(thisWeekRange) }}</span>
      </div>
      <ProgressStatGrid :tiles="weekTiles" :columns="5" />
      <p class="mt-3 text-[10px] leading-snug text-muted">
        Sun–Sat totals. Deltas compare to last week. PRs are new all-time max weights logged this
        week.
      </p>
    </section>

    <!-- This month -->
    <section class="mb-5 rounded-2xl border border-border bg-card-inner p-4">
      <div class="mb-3 flex items-baseline justify-between gap-2">
        <h2 class="flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">
          <i class="fa-solid fa-calendar text-primary" aria-hidden="true" />
          This month
        </h2>
        <span class="text-[11px] font-semibold text-muted">{{ formatMonthLabel(thisMonthRange) }}</span>
      </div>
      <ProgressStatGrid :tiles="monthTiles" :columns="5" />
      <p class="mt-3 text-[10px] leading-snug text-muted">
        Consistency is training days divided by calendar days elapsed this month.
      </p>
    </section>

    <!-- Historical switcher -->
    <section class="mb-5 rounded-2xl border border-border bg-card-inner p-4">
      <div class="mb-3 flex flex-wrap items-center justify-between gap-2">
        <h2 class="flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">
          <i class="fa-solid fa-clock-rotate-left text-primary" aria-hidden="true" />
          Archive
        </h2>
        <span class="text-[11px] font-semibold text-muted">{{ historicalLabel }}</span>
      </div>

      <div
        class="mb-4 flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
      >
        <button
          v-for="tab in historicalTabs"
          :key="tab.id"
          type="button"
          class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide transition-colors"
          :class="
            historicalTab === tab.id
              ? 'border-primary bg-primary text-foreground'
              : 'border-border bg-card text-muted'
          "
          @click="historicalTab = tab.id"
        >
          {{ tab.label }}
        </button>
      </div>

      <ProgressStatGrid :tiles="historicalTiles" :columns="5" />
    </section>
  </div>
</template>
