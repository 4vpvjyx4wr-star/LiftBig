<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import type { PlanCatalogEntry } from '@/types/planCatalog'
import type { WorkoutTemplate } from '@/types/workout'
import { isValidDateKey, todayKey } from '@/utils/dateKey'
import { getGeneratedTemplate } from '@/utils/guidedPlanGenerator'
import {
  estimatePlanDurationMinutes,
  formatPlanDurationEstimate,
} from '@/utils/planDuration'

const props = defineProps<{
  open: boolean
  entry: PlanCatalogEntry | null
  template: WorkoutTemplate | null
  daysPerWeek: number
}>()

const emit = defineEmits<{
  close: []
  apply: [payload: { startDateKey: string; restDaysPerWeek: number; restEveryWorkoutDays: number }]
}>()

const startDateInput = ref('')
const restDaysPerWeek = ref(0)
const restEveryWorkoutDays = ref(0)

const isFolderMode = computed(() => props.entry?.scheduleMode === 'folder')

const suggestedRestDays = computed(() => Math.max(0, 7 - props.daysPerWeek))

watch(
  () => props.open,
  (v) => {
    if (v) {
      startDateInput.value = todayKey()
      restDaysPerWeek.value = isFolderMode.value ? 0 : suggestedRestDays.value
      restEveryWorkoutDays.value = 0
    }
  },
)

const displayTemplate = computed(() => {
  if (props.template) return props.template
  if (props.entry) return getGeneratedTemplate(props.entry.id) ?? null
  return null
})

function durationLabel(): string {
  if (!displayTemplate.value) return ''
  return formatPlanDurationEstimate(estimatePlanDurationMinutes(displayTemplate.value))
}

function submit() {
  const key = startDateInput.value.trim()
  if (!isValidDateKey(key)) {
    window.alert('Pick a valid start date.')
    return
  }
  emit('apply', {
    startDateKey: key,
    restDaysPerWeek: restDaysPerWeek.value,
    restEveryWorkoutDays: restEveryWorkoutDays.value,
  })
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open && entry"
      class="fixed inset-0 z-50 flex flex-col justify-end bg-black/65"
      role="dialog"
      aria-modal="true"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[85vh] overflow-y-auto rounded-t-2xl border border-border border-b-0 bg-card px-4 pb-8 pt-2"
        @click.stop
      >
        <div class="mx-auto mb-3 h-1 w-10 rounded-full bg-border" />
        <h3 class="text-center text-lg font-extrabold text-foreground">Schedule your plan</h3>
        <p class="mt-1 text-center text-sm font-semibold text-foreground">{{ entry.title }}</p>
        <p v-if="displayTemplate" class="mt-1 text-center text-xs text-muted">
          <template v-if="isFolderMode">Multi-day split</template>
          <template v-else>{{ displayTemplate.exercises.length }} exercises · {{ durationLabel() }}</template>
        </p>

        <label class="mt-4 block text-[10px] font-bold uppercase tracking-wide text-muted">Start date</label>
        <input
          v-model="startDateInput"
          type="date"
          class="mt-1 w-full rounded-lg border border-border bg-card-inner px-3 py-2 text-foreground outline-none focus:border-primary"
        />

        <div v-if="!isFolderMode" class="mt-4 rounded-xl border border-border bg-card-inner px-3 py-3">
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
            Pre-filled from your {{ daysPerWeek }} days/week answer. Adjust if needed.
          </p>
        </div>

        <div v-else class="mt-4 rounded-xl border border-border bg-card-inner px-3 py-3">
          <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">
            Rest day every N workout days (optional)
          </label>
          <div class="mt-2 flex items-center gap-3">
            <input
              v-model.number="restEveryWorkoutDays"
              type="range"
              min="0"
              max="6"
              step="1"
              class="min-w-0 flex-1 accent-primary"
            />
            <span class="w-6 text-center text-sm font-black text-foreground">{{ restEveryWorkoutDays }}</span>
          </div>
          <p class="mt-2 text-[10px] leading-snug text-muted">
            0 = consecutive training days. Inserts a rest day between folder sessions when set.
          </p>
        </div>

        <div class="mt-4 flex gap-2">
          <button
            type="button"
            class="flex-1 rounded-lg border border-border py-3 text-sm font-bold text-foreground"
            @click="emit('close')"
          >
            Cancel
          </button>
          <button
            type="button"
            class="flex-1 rounded-lg bg-primary py-3 text-sm font-extrabold text-foreground"
            @click="submit"
          >
            Apply to calendar
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
