<script setup lang="ts">
import { computed } from 'vue'
import type { FuturePoint, SessionPoint } from '@/utils/exerciseProgress'
import type { WeightUnit } from '@/utils/units'
import { formatWeightFromLbs } from '@/utils/units'

const props = defineProps<{
  history: SessionPoint[]
  future: FuturePoint[]
  weightUnit: WeightUnit
}>()

const VB_W = 320
const VB_H = 220
const PAD_L = 42
const PAD_R = 36
const PAD_T = 28
const PAD_B = 36

const inner = computed(() => ({
  w: VB_W - PAD_L - PAD_R,
  h: VB_H - PAD_T - PAD_B,
}))

const allTimes = computed(() => {
  const h = props.history.map((p) => p.timeMs)
  const f = props.future.map((p) => p.timeMs)
  return [...h, ...f]
})

const weightRange = computed(() => {
  const ws = [
    ...props.history.map((p) => p.maxWeightLbs),
    ...props.future.map((p) => p.projectedMaxWeightLbs),
  ]
  if (ws.length === 0) return { min: 0, max: 100 }
  let min = Math.min(...ws)
  let max = Math.max(...ws)
  const pad = Math.max(2.5, (max - min) * 0.12 || 5)
  if (max - min < 1e-6) {
    min -= pad
    max += pad
  } else {
    min -= pad * 0.5
    max += pad * 0.5
  }
  return { min, max }
})

const repsRange = computed(() => {
  const rs = props.history.map((p) => p.avgReps)
  if (rs.length === 0) return { min: 0, max: 12 }
  let min = Math.min(...rs)
  let max = Math.max(...rs)
  const pad = Math.max(1, (max - min) * 0.15 || 2)
  if (max - min < 1e-6) {
    min = Math.max(0, min - 2)
    max += 2
  } else {
    min = Math.max(0, min - pad * 0.4)
    max += pad * 0.4
  }
  return { min, max }
})

const timeRange = computed(() => {
  const t = allTimes.value
  if (t.length === 0) return { min: 0, max: 1 }
  const mn = Math.min(...t)
  const mx = Math.max(...t)
  const span = mx - mn || 86_400_000
  return { min: mn - span * 0.02, max: mx + span * 0.02 }
})

function xScale(t: number): number {
  const { min, max } = timeRange.value
  const span = max - min || 1
  return PAD_L + ((t - min) / span) * inner.value.w
}

function yWeight(w: number): number {
  const { min, max } = weightRange.value
  const span = max - min || 1
  return PAD_T + inner.value.h - ((w - min) / span) * inner.value.h
}

function yReps(r: number): number {
  const { min, max } = repsRange.value
  const span = max - min || 1
  return PAD_T + inner.value.h - ((r - min) / span) * inner.value.h
}

const weightHistoryPath = computed(() => {
  if (props.history.length === 0) return ''
  const parts = props.history.map((p, i) => {
    const cmd = i === 0 ? 'M' : 'L'
    return `${cmd}${xScale(p.timeMs).toFixed(1)},${yWeight(p.maxWeightLbs).toFixed(1)}`
  })
  return parts.join(' ')
})

const weightFuturePath = computed(() => {
  if (props.history.length === 0 || props.future.length === 0) return ''
  const last = props.history[props.history.length - 1]!
  const firstF = props.future[0]!
  const seg = [
    `M${xScale(last.timeMs).toFixed(1)},${yWeight(last.maxWeightLbs).toFixed(1)}`,
    `L${xScale(firstF.timeMs).toFixed(1)},${yWeight(firstF.projectedMaxWeightLbs).toFixed(1)}`,
  ]
  for (let i = 1; i < props.future.length; i++) {
    const p = props.future[i]!
    seg.push(`L${xScale(p.timeMs).toFixed(1)},${yWeight(p.projectedMaxWeightLbs).toFixed(1)}`)
  }
  return seg.join('')
})

const repsPath = computed(() => {
  if (props.history.length === 0) return ''
  return props.history
    .map((p, i) => {
      const cmd = i === 0 ? 'M' : 'L'
      return `${cmd}${xScale(p.timeMs).toFixed(1)},${yReps(p.avgReps).toFixed(1)}`
    })
    .join(' ')
})

const weightYTicks = computed(() => {
  const { min, max } = weightRange.value
  const n = 3
  const ticks: { y: number; label: string }[] = []
  for (let i = 0; i <= n; i++) {
    const w = min + ((max - min) * i) / n
    ticks.push({
      y: yWeight(w),
      label: formatWeightFromLbs(w, props.weightUnit, 0),
    })
  }
  return ticks
})

const repsYTicks = computed(() => {
  const { min, max } = repsRange.value
  const ticks: { y: number; label: string }[] = []
  for (let i = 0; i <= 2; i++) {
    const r = min + ((max - min) * i) / 2
    ticks.push({
      y: yReps(r),
      label: r.toFixed(0),
    })
  }
  return ticks
})

const xLabels = computed(() => {
  const pts = [
    ...props.history.map((p) => ({ t: p.timeMs, key: p.dateKey })),
    ...props.future.map((p) => ({
      t: p.timeMs,
      key: new Date(p.timeMs).toISOString().slice(0, 10),
    })),
  ]
  if (pts.length === 0) return []
  pts.sort((a, b) => a.t - b.t)
  const pick = [0, Math.floor(pts.length / 2), pts.length - 1]
  const uniq = [...new Set(pick)].filter((i) => i >= 0 && i < pts.length)
  return uniq.map((i) => ({
    x: xScale(pts[i]!.t),
    text: pts[i]!.key.slice(5).replace('-', '/'),
  }))
})

const hasData = computed(() => props.history.length > 0)
</script>

<template>
  <div v-if="hasData" class="w-full overflow-hidden rounded-xl border border-border bg-card-inner">
    <svg
      class="block h-auto w-full text-foreground"
      :viewBox="`0 0 ${VB_W} ${VB_H}`"
      preserveAspectRatio="xMidYMid meet"
      role="img"
      aria-label="Strength and reps over time"
    >
      <text x="8" y="16" fill="currentColor" font-size="10" font-weight="700">
        Max weight
      </text>
      <text
        :x="VB_W - 8"
        y="16"
        fill="#22c55e"
        font-size="10"
        font-weight="700"
        text-anchor="end"
      >
        Avg reps
      </text>

      <g class="text-muted" opacity="0.35">
        <line
          v-for="(tk, i) in weightYTicks"
          :key="'h' + i"
          :x1="PAD_L"
          :x2="PAD_L + inner.w"
          :y1="tk.y"
          :y2="tk.y"
          stroke="currentColor"
          stroke-width="0.5"
        />
      </g>

      <text
        v-for="(tk, i) in weightYTicks"
        :key="'wl' + i"
        x="4"
        :y="tk.y + 3"
        fill="currentColor"
        class="text-muted"
        font-size="8"
      >
        {{ tk.label }}
      </text>
      <text
        v-for="(tk, i) in repsYTicks"
        :key="'rl' + i"
        :x="VB_W - 4"
        :y="tk.y + 3"
        fill="#22c55e"
        font-size="8"
        text-anchor="end"
      >
        {{ tk.label }}
      </text>

      <path
        v-if="repsPath"
        :d="repsPath"
        fill="none"
        stroke="#22c55e"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
      />

      <path
        v-if="weightHistoryPath"
        :d="weightHistoryPath"
        fill="none"
        stroke="var(--color-primary)"
        stroke-width="2.5"
        stroke-linecap="round"
        stroke-linejoin="round"
      />

      <path
        v-if="weightFuturePath"
        :d="weightFuturePath"
        fill="none"
        stroke="var(--color-primary)"
        stroke-width="2.5"
        stroke-dasharray="5 4"
        stroke-linecap="round"
        stroke-linejoin="round"
        opacity="0.85"
      />

      <circle
        v-for="(p, i) in history"
        :key="'hw' + i"
        :cx="xScale(p.timeMs)"
        :cy="yWeight(p.maxWeightLbs)"
        r="4"
        fill="var(--color-primary)"
        stroke="var(--color-card-inner)"
        stroke-width="1"
      />
      <circle
        v-for="(p, i) in future"
        :key="'fw' + i"
        :cx="xScale(p.timeMs)"
        :cy="yWeight(p.projectedMaxWeightLbs)"
        r="3.5"
        fill="none"
        stroke="var(--color-primary)"
        stroke-width="1.8"
        opacity="0.9"
      />
      <circle
        v-for="(p, i) in history"
        :key="'hr' + i"
        :cx="xScale(p.timeMs)"
        :cy="yReps(p.avgReps)"
        r="3"
        fill="#22c55e"
        opacity="0.9"
      />

      <text
        v-for="(lb, i) in xLabels"
        :key="'xl' + i"
        :x="lb.x"
        :y="VB_H - 10"
        fill="currentColor"
        class="text-muted"
        font-size="8"
        text-anchor="middle"
      >
        {{ lb.text }}
      </text>
    </svg>
    <div
      class="flex flex-wrap gap-4 border-t border-border px-3 py-2 text-[10px] font-semibold text-muted"
    >
      <span class="inline-flex items-center gap-1.5">
        <span class="inline-block h-0.5 w-4 rounded bg-primary" />
        Max weight (logged)
      </span>
      <span class="inline-flex items-center gap-1.5">
        <span class="inline-block h-0.5 w-4 rounded border border-dashed border-primary bg-transparent" />
        Projected max (progressive overload)
      </span>
      <span class="inline-flex items-center gap-1.5 text-green-500">
        <span class="inline-block h-0.5 w-4 rounded bg-green-500" />
        Avg reps / session
      </span>
    </div>
  </div>
  <p v-else class="rounded-xl border border-border bg-card-inner px-4 py-8 text-center text-sm text-muted">
    No chart data for this exercise yet.
  </p>
</template>
