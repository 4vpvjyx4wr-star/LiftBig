<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import { settingsInjectionKey } from '@/composables/injectionKeys'
import { formatWeightWithUnit, kgToLbs, type WeightUnit } from '@/utils/units'
import { ONE_RM_FORMULAS, estimateOneRepMax } from '@/utils/oneRepMax'

const settings = inject(settingsInjectionKey)!

const weightInput = ref('')
const repsInput = ref('5')

const unit = computed(() => settings.weightUnit.value)

watch(unit, () => {
  weightInput.value = ''
})

function formatEstimate(valueInDisplayUnit: number, u: WeightUnit): string {
  const lbs = u === 'lb' ? valueInDisplayUnit : kgToLbs(valueInDisplayUnit)
  return formatWeightWithUnit(lbs, u, 1)
}

const parsedWeight = computed(() => {
  const w = parseFloat(weightInput.value.replace(',', '.'))
  if (Number.isNaN(w) || w <= 0) return null
  return w
})

const parsedReps = computed(() => {
  const r = parseInt(String(repsInput.value).trim(), 10)
  if (Number.isNaN(r) || r < 1) return null
  return r
})

const estimates = computed(() => {
  const w = parsedWeight.value
  const r = parsedReps.value
  if (w == null || r == null) return []
  return ONE_RM_FORMULAS.map((f) => ({
    ...f,
    value: estimateOneRepMax(w, r, f.id),
  }))
})

const averageEstimate = computed(() => {
  const vals = estimates.value.map((e) => e.value).filter((v): v is number => v != null)
  if (vals.length === 0) return null
  return vals.reduce((a, b) => a + b, 0) / vals.length
})

const canShowResults = computed(
  () => parsedWeight.value != null && parsedReps.value != null && estimates.value.some((e) => e.value != null),
)
</script>

<template>
  <div class="pb-8">
    <header class="mb-4 border-b border-border pb-3">
      <p class="text-[10px] font-bold tracking-[0.2em] text-muted">One Rep Max</p>
    </header>

    <div class="rounded-xl border border-border bg-card p-4">
      <label class="text-xs font-bold uppercase tracking-wide text-muted">
        Weight lifted ({{ unit === 'lb' ? 'lb' : 'kg' }})
      </label>
      <input
        v-model="weightInput"
        type="text"
        inputmode="decimal"
        class="mt-2 w-full rounded-lg border border-border bg-card-inner py-3 text-center text-3xl font-extrabold text-foreground outline-none focus:border-primary"
        :placeholder="unit === 'lb' ? '225' : '100'"
        autocomplete="off"
      />

      <label class="mt-4 block text-xs font-bold uppercase tracking-wide text-muted">Reps (to failure)</label>
      <input
        v-model="repsInput"
        type="text"
        inputmode="numeric"
        class="mt-2 w-full rounded-lg border border-border bg-card-inner py-3 text-center text-3xl font-extrabold text-foreground outline-none focus:border-primary"
        placeholder="5"
        autocomplete="off"
      />

      <p class="mt-3 text-[11px] leading-relaxed text-muted">
        Enter the weight and reps for one hard set. Estimates use common formulas; treat them as guides, not
        guarantees.
      </p>
    </div>

    <div
      v-if="canShowResults && averageEstimate != null"
      class="mt-4 rounded-xl border border-[#16a34a] bg-[#0d2010] p-4 text-center"
    >
      <p class="text-[10px] font-bold uppercase tracking-wider text-success-text">Average of formulas</p>
      <div class="mt-1 text-4xl font-black text-success-text">
        {{ formatEstimate(averageEstimate, unit) }}
      </div>
    </div>

    <div v-if="canShowResults" class="mt-4 rounded-xl border border-border bg-card p-4">
      <h2 class="mb-3 text-xs font-bold uppercase tracking-wide text-muted">By formula</h2>
      <ul class="space-y-2">
        <li
          v-for="row in estimates"
          :key="row.id"
          class="flex items-baseline justify-between gap-3 border-b border-border py-2 last:border-0"
        >
          <span class="text-sm font-bold text-foreground">{{ row.label }}</span>
          <span v-if="row.value != null" class="text-lg font-extrabold text-primary">{{
            formatEstimate(row.value, unit)
          }}</span>
          <span v-else class="text-sm text-muted">—</span>
        </li>
      </ul>
    </div>

    <div
      v-else-if="weightInput.trim() !== '' || repsInput.trim() !== ''"
      class="mt-4 rounded-xl border border-amber-900/50 bg-card p-4 text-center text-sm text-amber-400"
    >
      Enter a positive weight and at least one rep to see estimates.
    </div>
  </div>
</template>
