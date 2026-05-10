<script setup lang="ts">
import { ref, watch } from 'vue'
import type { WorkoutTemplate } from '@/types/workout'
import { estimatePlanDurationMinutes, formatPlanDurationEstimate } from '@/utils/planDuration'

const props = defineProps<{
  open: boolean
  templates: WorkoutTemplate[]
}>()

const emit = defineEmits<{
  close: []
  pick: [payload: { template: WorkoutTemplate; restDaysPerWeek: number }]
}>()

const restDaysPerWeek = ref(0)

watch(
  () => props.open,
  (v) => {
    if (v) restDaysPerWeek.value = 0
  },
)

function planDurationLabel(t: WorkoutTemplate): string {
  return formatPlanDurationEstimate(estimatePlanDurationMinutes(t))
}

function choose(t: WorkoutTemplate) {
  emit('pick', { template: t, restDaysPerWeek: restDaysPerWeek.value })
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex flex-col justify-end bg-black/65"
      role="dialog"
      aria-modal="true"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[70vh] overflow-y-auto rounded-t-2xl border border-border border-b-0 bg-card px-4 pb-8 pt-2"
        @click.stop
      >
        <div class="mx-auto mb-3 h-1 w-10 rounded-full bg-border" />
        <h3 class="text-center text-lg font-extrabold text-foreground">Choose a Plan</h3>
        <p class="mb-3 text-center text-xs text-muted">
          <template v-if="restDaysPerWeek === 0">
            Exercises will be appended to this day only.
          </template>
          <template v-else>
            Through the end of this month, each 7-day block from this day gets the plan on training days and logged rest
            days on the others (only empty days are filled).
          </template>
          <span class="mt-1 block text-[10px] opacity-90">
            Times shown: ~1 min per set + ~1 min rest between sets.
          </span>
        </p>

        <div class="mb-4 rounded-xl border border-border bg-card-inner px-3 py-3">
          <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">
            Rest days per 7-day block
          </label>
          <div class="mt-2 flex items-center gap-3">
            <input
              v-model.number="restDaysPerWeek"
              type="range"
              min="0"
              max="6"
              step="1"
              class="min-w-0 flex-1 accent-primary"
            />
            <span class="w-6 text-center text-sm font-black text-foreground">{{ restDaysPerWeek }}</span>
          </div>
          <p class="mt-2 text-[10px] leading-snug text-muted">
            0 = this day only. 1–6 = spread across each week: earlier days in the block are training days (plan applied),
            remaining days are rest days for consistency.
          </p>
        </div>

        <ul class="space-y-2">
          <li v-for="t in templates" :key="t.id">
            <button
              type="button"
              class="flex w-full items-center justify-between rounded-xl border border-border bg-card-inner px-4 py-3 text-left hover:border-primary"
              @click="choose(t)"
            >
              <div>
                <div class="font-bold text-foreground">{{ t.name }}</div>
                <div class="text-xs text-muted">
                  {{ t.exercises.length }} exercise{{ t.exercises.length !== 1 ? 's' : '' }}
                  · {{ planDurationLabel(t) }}
                </div>
              </div>
              <span class="text-xl text-primary">›</span>
            </button>
          </li>
        </ul>
      </div>
    </div>
  </Teleport>
</template>
