<script setup lang="ts">
import { computed, inject } from 'vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import { formatWeightWithUnit } from '@/utils/units'
import {
  computeWeeklyVolume,
  formatWeekLabel,
  getPreviousWeekRange,
  getWeekRangeForDate,
  volumeDelta,
  type VolumeDelta,
} from '@/utils/weeklyVolume'

const workouts = inject(workoutsInjectionKey)!
const settings = inject(settingsInjectionKey)!

const weightUnit = computed(() => settings.weightUnit.value)

const thisWeekRange = computed(() => getWeekRangeForDate())
const prevWeekRange = computed(() => getPreviousWeekRange(thisWeekRange.value))

const thisWeek = computed(() => computeWeeklyVolume(workouts.log.value, thisWeekRange.value))
const prevWeek = computed(() => computeWeeklyVolume(workouts.log.value, prevWeekRange.value))
const delta = computed(() => volumeDelta(thisWeek.value, prevWeek.value))

const weekLabel = computed(() => formatWeekLabel(thisWeekRange.value))

function fmtTonnage(lbs: number): string {
  if (lbs <= 0) return '—'
  return formatWeightWithUnit(lbs, weightUnit.value, 0)
}

function fmtDeltaCount(n: number): string {
  if (n === 0) return '—'
  return n > 0 ? `↑${n}` : `↓${Math.abs(n)}`
}

function fmtTonnageDelta(d: VolumeDelta): string {
  const n = d.tonnageLbs
  if (n === 0) return '—'
  const sign = n > 0 ? '↑' : '↓'
  return `${sign}${formatWeightWithUnit(Math.abs(n), weightUnit.value, 0)}`
}

function deltaClass(n: number): string {
  if (n > 0) return 'text-success-text'
  if (n < 0) return 'text-muted'
  return 'text-muted'
}
</script>

<template>
  <section class="mb-5 rounded-2xl border border-border bg-card-inner p-4">
    <div class="mb-3 flex items-baseline justify-between gap-2">
      <h2 class="text-[11px] font-extrabold uppercase tracking-wider text-foreground/80">
        This week
      </h2>
      <span class="text-[11px] font-semibold text-muted">{{ weekLabel }}</span>
    </div>
    <div class="grid grid-cols-2 gap-2 sm:grid-cols-4">
      <div class="rounded-xl border border-border bg-card px-3 py-3 text-center">
        <div class="text-[10px] font-bold uppercase text-muted">Sets</div>
        <div class="mt-1 text-lg font-black text-foreground">{{ thisWeek.totalSets }}</div>
        <div class="mt-0.5 text-[10px] font-bold" :class="deltaClass(delta.sets)">
          vs last {{ fmtDeltaCount(delta.sets) }}
        </div>
      </div>
      <div class="rounded-xl border border-border bg-card px-3 py-3 text-center">
        <div class="text-[10px] font-bold uppercase text-muted">Reps</div>
        <div class="mt-1 text-lg font-black text-foreground">{{ thisWeek.totalReps }}</div>
        <div class="mt-0.5 text-[10px] font-bold" :class="deltaClass(delta.reps)">
          vs last {{ fmtDeltaCount(delta.reps) }}
        </div>
      </div>
      <div class="rounded-xl border border-border bg-card px-3 py-3 text-center">
        <div class="text-[10px] font-bold uppercase text-muted">Tonnage</div>
        <div class="mt-1 text-base font-black leading-tight text-foreground">
          {{ fmtTonnage(thisWeek.tonnageLbs) }}
        </div>
        <div class="mt-0.5 text-[10px] font-bold" :class="deltaClass(delta.tonnageLbs)">
          vs last {{ fmtTonnageDelta(delta) }}
        </div>
      </div>
      <div class="rounded-xl border border-border bg-card px-3 py-3 text-center">
        <div class="text-[10px] font-bold uppercase text-muted">Days</div>
        <div class="mt-1 text-lg font-black text-foreground">{{ thisWeek.trainedDays }}</div>
        <div class="mt-0.5 text-[10px] font-bold" :class="deltaClass(delta.days)">
          vs last {{ fmtDeltaCount(delta.days) }}
        </div>
      </div>
    </div>
    <p class="mt-3 text-[10px] leading-snug text-muted">
      Sun–Sat totals from logged working sets. Warmups, cardio, and circuit checkboxes without
      weight are excluded from tonnage.
    </p>
  </section>
</template>
