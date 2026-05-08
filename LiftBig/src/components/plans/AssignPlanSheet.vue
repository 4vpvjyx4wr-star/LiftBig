<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import { settingsInjectionKey } from '@/composables/injectionKeys'
import type { WorkoutTemplate } from '@/types/workout'
import {
  estimatePlanDurationMinutes,
  formatPlanDurationEstimate,
  planDurationAssumptionsFromSeconds,
} from '@/utils/planDuration'

const props = defineProps<{
  open: boolean
  templates: WorkoutTemplate[]
}>()

const emit = defineEmits<{
  close: []
  pick: [template: WorkoutTemplate]
}>()
const settings = inject(settingsInjectionKey)!
const searchQuery = ref('')
const durationAssumptions = computed(() =>
  planDurationAssumptionsFromSeconds(settings.averageLiftSeconds.value, settings.averageRestSeconds.value),
)

const filteredTemplates = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return props.templates
  return props.templates.filter((template) => {
    if (template.name.toLowerCase().includes(q)) return true
    return template.exercises.some((ex) => ex.name.toLowerCase().includes(q))
  })
})

watch(
  () => props.open,
  (open) => {
    if (open) searchQuery.value = ''
  },
)

function planDurationLabel(t: WorkoutTemplate): string {
  return formatPlanDurationEstimate(estimatePlanDurationMinutes(t, durationAssumptions.value))
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
        <p class="mb-4 text-center text-xs text-muted">
          Exercises will be appended to this day.
          <span class="mt-1 block text-[10px] opacity-90">
            Times shown: ~{{ settings.averageLiftSeconds.value }}s per set + ~{{ settings.averageRestSeconds.value }}s rest.
          </span>
        </p>
        <input
          v-model="searchQuery"
          type="text"
          class="mb-3 w-full rounded-lg border border-border bg-card-inner px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
          placeholder="Search plans or exercises..."
        />
        <p v-if="filteredTemplates.length === 0" class="mb-3 text-center text-xs text-muted">
          No matching plans.
        </p>
        <ul class="space-y-2">
          <li v-for="t in filteredTemplates" :key="t.id">
            <button
              type="button"
              class="flex w-full items-center justify-between rounded-xl border border-border bg-card-inner px-4 py-3 text-left hover:border-primary"
              @click="emit('pick', t)"
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
