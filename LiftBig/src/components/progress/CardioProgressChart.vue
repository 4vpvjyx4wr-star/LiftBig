<script setup lang="ts">
import { computed } from 'vue'
import type { CardioSessionPoint } from '@/utils/cardioProgress'
import type { DistanceUnit } from '@/utils/distances'
import { distanceUnitLabel } from '@/utils/distances'

const props = defineProps<{
  history: CardioSessionPoint[]
  distanceUnit: DistanceUnit
}>()

const VB_W = 320
const VB_H = 200
const PAD_L = 42
const PAD_R = 16
const PAD_T = 24
const PAD_B = 32

const inner = computed(() => ({
  w: VB_W - PAD_L - PAD_R,
  h: VB_H - PAD_T - PAD_B,
}))

const hasDistance = computed(() => props.history.some((p) => p.distance != null))

const timeRange = computed(() => {
  const t = props.history.map((p) => p.timeMs)
  if (t.length === 0) return { min: 0, max: 1 }
  const mn = Math.min(...t)
  const mx = Math.max(...t)
  const span = mx - mn || 86_400_000
  return { min: mn - span * 0.02, max: mx + span * 0.02 }
})

const durationRange = computed(() => {
  const vals = props.history.map((p) => p.durationMinutes)
  if (vals.length === 0) return { min: 0, max: 60 }
  let min = Math.min(...vals)
  let max = Math.max(...vals)
  const pad = Math.max(2, (max - min) * 0.12 || 5)
  min = Math.max(0, min - pad * 0.4)
  max += pad
  return { min, max }
})

const distanceRange = computed(() => {
  const vals = props.history.map((p) => p.distance).filter((d): d is number => d != null)
  if (vals.length === 0) return { min: 0, max: 5 }
  let min = Math.min(...vals)
  let max = Math.max(...vals)
  const pad = Math.max(0.2, (max - min) * 0.12 || 1)
  min = Math.max(0, min - pad * 0.4)
  max += pad
  return { min, max }
})

function xScale(t: number): number {
  const { min, max } = timeRange.value
  const span = max - min || 1
  return PAD_L + ((t - min) / span) * inner.value.w
}

function yScaleDuration(v: number): number {
  const { min, max } = durationRange.value
  const span = max - min || 1
  return PAD_T + inner.value.h - ((v - min) / span) * inner.value.h
}

function yScaleDistance(v: number): number {
  const { min, max } = distanceRange.value
  const span = max - min || 1
  return PAD_T + inner.value.h - ((v - min) / span) * inner.value.h
}

const durationPath = computed(() => {
  if (props.history.length === 0) return ''
  return props.history
    .map((p, i) => `${i === 0 ? 'M' : 'L'} ${xScale(p.timeMs)} ${yScaleDuration(p.durationMinutes)}`)
    .join(' ')
})

const distancePath = computed(() => {
  const pts = props.history.filter((p) => p.distance != null)
  if (pts.length === 0) return ''
  return pts
    .map((p, i) => `${i === 0 ? 'M' : 'L'} ${xScale(p.timeMs)} ${yScaleDistance(p.distance!)}`)
    .join(' ')
})

function formatDateLabel(dateKey: string): string {
  const parts = dateKey.split('-')
  if (parts.length !== 3) return dateKey
  return `${parts[1]}/${parts[2]}`
}
</script>

<template>
  <div v-if="history.length > 0" class="rounded-2xl border border-border bg-card-inner p-3">
    <svg
      :viewBox="`0 0 ${VB_W} ${VB_H}`"
      class="h-auto w-full"
      role="img"
      aria-label="Cardio progress chart"
    >
      <text :x="PAD_L" :y="14" class="fill-muted text-[9px] font-bold">Duration (min)</text>
      <text
        v-if="hasDistance"
        :x="VB_W - PAD_R"
        :y="14"
        text-anchor="end"
        class="fill-muted text-[9px] font-bold"
      >
        Distance ({{ distanceUnitLabel(distanceUnit) }})
      </text>
      <path
        :d="durationPath"
        fill="none"
        stroke="var(--color-primary)"
        stroke-width="2.5"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
      <path
        v-if="distancePath"
        :d="distancePath"
        fill="none"
        stroke="var(--color-blue, #3b82f6)"
        stroke-width="2"
        stroke-dasharray="4 3"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
      <g v-for="p in history" :key="p.dateKey">
        <circle
          :cx="xScale(p.timeMs)"
          :cy="yScaleDuration(p.durationMinutes)"
          r="3.5"
          fill="var(--color-primary)"
        />
        <circle
          v-if="p.distance != null"
          :cx="xScale(p.timeMs)"
          :cy="yScaleDistance(p.distance)"
          r="3"
          fill="var(--color-blue, #3b82f6)"
        />
      </g>
    </svg>
    <div class="mt-2 flex flex-wrap gap-3 text-[10px] text-muted">
      <span class="inline-flex items-center gap-1">
        <span class="inline-block h-0.5 w-4 rounded bg-primary" aria-hidden="true" />
        Duration
      </span>
      <span v-if="hasDistance" class="inline-flex items-center gap-1">
        <span class="inline-block h-0.5 w-4 rounded border-b border-dashed border-blue" aria-hidden="true" />
        Distance
      </span>
    </div>
    <ul class="mt-3 space-y-1 border-t border-border pt-2 text-xs">
      <li
        v-for="p in [...history].reverse().slice(0, 5)"
        :key="`row-${p.dateKey}`"
        class="flex justify-between gap-2 text-muted"
      >
        <span class="font-semibold text-foreground">{{ formatDateLabel(p.dateKey) }}</span>
        <span>
          {{ p.durationMinutes }} min
          <template v-if="p.distance != null">
            · {{ p.distance }} {{ distanceUnitLabel(distanceUnit) }}
            <template v-if="p.paceMinutesPerUnit != null">
              · {{ p.paceMinutesPerUnit }} min/{{ distanceUnitLabel(distanceUnit) }}
            </template>
          </template>
        </span>
      </li>
    </ul>
  </div>
</template>
