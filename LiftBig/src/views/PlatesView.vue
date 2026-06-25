<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import {
  barChoicesForUnit,
  calculatePlates,
  defaultBarForUnit,
  plateColorsForUnit,
  plateLabel,
  plateSizesForUnit,
  quickPresetsForUnit,
} from '@/utils/plates'
import { haptic } from '@/utils/haptics'
import { settingsInjectionKey } from '@/composables/injectionKeys'

const settings = inject(settingsInjectionKey)!

const targetInput = ref('')
const barWeight = ref(defaultBarForUnit(settings.weightUnit.value))
const result = ref<{ plates: number[]; remainder: number } | null>(null)

const unit = computed(() => settings.weightUnit.value)
const sizes = computed(() => [...plateSizesForUnit(unit.value)])
const colors = computed(() => plateColorsForUnit(unit.value))
const barChoices = computed(() => [...barChoicesForUnit(unit.value)])
const quickRows = computed(() => quickPresetsForUnit(unit.value))

watch(unit, (u) => {
  barWeight.value = defaultBarForUnit(u)
  result.value = null
  targetInput.value = ''
})

function runCalc() {
  const target = parseFloat(targetInput.value.replace(',', '.'))
  if (Number.isNaN(target) || target <= 0) return
  result.value = calculatePlates(target, barWeight.value, sizes.value)
  haptic('tap')
}

const totalWeight = computed(() => {
  if (!result.value) return 0
  return barWeight.value + result.value.plates.reduce((a, b) => a + b, 0) * 2
})

const isExact = computed(() => result.value && result.value.remainder < 0.001)

function setQuick(weight: number) {
  targetInput.value = String(weight)
  result.value = calculatePlates(weight, barWeight.value, sizes.value)
}

function setBar(w: number) {
  barWeight.value = w
  result.value = null
}

const displayedPlates = computed(() => {
  if (!result.value) return { list: [] as number[], overflow: 0 }
  const max = 8
  const p = result.value.plates
  return { list: p.slice(0, max), overflow: Math.max(0, p.length - max) }
})

const plateCounts = computed(() => {
  const counts: Record<number, number> = {}
  if (!result.value) return counts
  for (const p of result.value.plates) {
    counts[p] = (counts[p] ?? 0) + 1
  }
  return counts
})

function unitWord(plural: boolean) {
  const u = plateLabel(unit.value)
  return plural ? `${u}s` : u
}
</script>

<template>
  <div class="pb-8">
    <header class="mb-4 border-b border-border pb-3">
      <p class="text-[10px] font-bold tracking-[0.2em] text-muted">Plate Calculator</p>
    </header>

    <div class="rounded-xl border border-border bg-card p-4">
      <label class="text-xs font-bold uppercase tracking-wide text-muted">
        Target Weight ({{ plateLabel(unit) }})
      </label>
      <input
        v-model="targetInput"
        type="text"
        inputmode="decimal"
        class="mt-2 w-full rounded-lg border border-border bg-card-inner py-3 text-center text-3xl font-extrabold text-foreground outline-none focus:border-primary"
        :placeholder="unit === 'lb' ? '225' : '100'"
        @keydown.enter="runCalc"
      />

      <label class="mt-4 block text-xs font-bold uppercase tracking-wide text-muted">Bar Weight</label>
      <div class="mt-2 flex gap-2">
        <button
          v-for="w in barChoices"
          :key="w"
          type="button"
          class="flex-1 rounded-lg border border-border py-3 text-sm font-bold transition-colors"
          :class="barWeight === w ? 'border-blue bg-blue text-foreground' : 'bg-card-inner text-muted'"
          @click="setBar(w)"
        >
          {{ w }} {{ plateLabel(unit) }}
          <span class="block text-[10px] font-normal opacity-80">{{
            w === barChoices[0] ? 'Standard' : "Women's"
          }}</span>
        </button>
      </div>

      <button
        type="button"
        class="btn-press mt-4 w-full rounded-xl bg-primary py-3 text-base font-extrabold text-foreground"
        @click="runCalc"
      >
        Calculate Plates
      </button>
    </div>

    <template v-if="result">
      <div class="mt-4 rounded-xl border border-success bg-success-soft p-4 text-center">
        <div class="text-4xl font-black text-success-text">
          {{ totalWeight }} {{ unitWord(true) }}
        </div>
        <p v-if="!isExact" class="mt-2 text-xs text-amber-400">
          Closest achievable — {{ result.remainder }} {{ unitWord(true) }} cannot be loaded
        </p>
        <p v-else class="mt-2 text-xs text-success-text">Exact weight achievable</p>
      </div>

      <div
        v-if="result.plates.length > 0"
        class="mt-4 flex flex-wrap items-center justify-center gap-1 rounded-xl border border-border bg-card p-4"
      >
        <div class="h-10 w-2.5 rounded-sm bg-gray-400" />
        <div class="flex flex-row items-center">
          <template v-for="(p, i) in [...displayedPlates.list].reverse()" :key="'L' + i">
            <div
              class="mx-px flex w-3.5 items-center justify-center rounded-sm text-[7px] font-black text-white [writing-mode:vertical-rl]"
              :style="{
                height: `${24 + p * (unit === 'lb' ? 0.6 : 0.35)}px`,
                backgroundColor: colors[p] ?? '#666',
              }"
            >
              {{ p }}
            </div>
          </template>
        </div>
        <div
          class="flex h-3.5 w-[60px] items-center justify-center rounded bg-gray-500 text-[8px] font-bold text-gray-200"
        >
          BAR
        </div>
        <div class="flex flex-row items-center">
          <template v-for="(p, i) in displayedPlates.list" :key="'R' + i">
            <div
              class="mx-px flex w-3.5 items-center justify-center rounded-sm text-[7px] font-black text-white [writing-mode:vertical-rl]"
              :style="{
                height: `${24 + p * (unit === 'lb' ? 0.6 : 0.35)}px`,
                backgroundColor: colors[p] ?? '#666',
              }"
            >
              {{ p }}
            </div>
          </template>
        </div>
        <div class="h-10 w-2.5 rounded-sm bg-gray-400" />
        <p v-if="displayedPlates.overflow > 0" class="w-full text-center text-[10px] text-muted">
          +{{ displayedPlates.overflow }} more
        </p>
      </div>

      <div v-else class="mt-4 rounded-xl border border-border bg-card p-5 text-center text-sm text-muted">
        Just the bar — no plates needed
      </div>

      <div v-if="result.plates.length > 0" class="mt-4 rounded-xl border border-border bg-card p-4">
        <h4 class="mb-3 text-sm font-extrabold text-foreground">Each Side</h4>
        <div
          v-for="p in sizes.filter((x) => plateCounts[x])"
          :key="p"
          class="mb-2 flex items-center gap-2"
        >
          <div
            class="flex h-9 w-9 items-center justify-center rounded-md text-xs font-black text-white"
            :style="{ backgroundColor: colors[p] ?? '#666' }"
          >
            {{ p }}
          </div>
          <span class="flex-1 text-sm text-foreground">{{ p }} {{ plateLabel(unit) }} plate</span>
          <span class="text-sm font-extrabold text-primary">× {{ plateCounts[p] }}</span>
          <span class="text-xs text-muted"
            >({{ p * (plateCounts[p] ?? 0) }} {{ unitWord(true) }})</span
          >
        </div>
      </div>
    </template>

    <div class="mt-4 rounded-xl border border-border bg-card p-4">
      <h4 class="mb-2 text-xs font-bold uppercase tracking-wide text-muted">Quick Reference</h4>
      <button
        v-for="row in quickRows"
        :key="row.weight"
        type="button"
        class="flex w-full items-center border-b border-border py-3 text-left last:border-0"
        @click="setQuick(row.weight)"
      >
        <span class="flex-1 font-semibold text-foreground">{{ row.label }}</span>
        <span class="text-sm text-muted">{{ row.weight }} {{ unitWord(true) }}</span>
        <span class="ml-2 text-xl text-primary">›</span>
      </button>
    </div>
  </div>
</template>
