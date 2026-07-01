<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import ExerciseDetailSheet from '@/components/library/ExerciseDetailSheet.vue'
import { settingsInjectionKey, templatesInjectionKey } from '@/composables/injectionKeys'
import type { PlanCatalogEntry } from '@/types/planCatalog'
import type { WorkoutTemplate } from '@/types/workout'
import {
  findLibraryExerciseByName,
  getLibraryExercise,
  type LibraryExercise,
} from '@/utils/exerciseLibrary'
import { getGeneratedTemplate } from '@/utils/guidedPlanGenerator'
import {
  estimatePlanDurationMinutes,
  formatPlanDurationEstimate,
  planDurationAssumptionsFromSeconds,
} from '@/utils/planDuration'
import { templatesForCatalogEntry } from '@/utils/schedulePlanProgram'
import { supersetBadgeLabel } from '@/utils/supersetUtils'
import { formatWeightWithUnit, parseStoredLbs } from '@/utils/units'

const props = defineProps<{
  open: boolean
  entry: PlanCatalogEntry | null
}>()

const emit = defineEmits<{
  close: []
}>()

const templatesApi = inject(templatesInjectionKey)!
const settings = inject(settingsInjectionKey)!

const detailOpen = ref(false)
const detailExercise = ref<LibraryExercise | null>(null)

const durationAssumptions = computed(() =>
  planDurationAssumptionsFromSeconds(settings.averageLiftSeconds.value, settings.averageRestSeconds.value),
)

const weightUnit = computed(() => settings.weightUnit.value)

const previewTemplates = computed((): WorkoutTemplate[] => {
  const entry = props.entry
  if (!entry) return []

  const resolved = templatesForCatalogEntry(entry, templatesApi.templates.value)
  if (resolved.length > 0) return resolved

  if (entry.scheduleMode === 'repeat' && entry.templateId) {
    const generated = getGeneratedTemplate(entry.id)
    return generated ? [generated] : []
  }

  return []
})

const isMultiSession = computed(() => previewTemplates.value.length > 1)

const durationLabel = computed(() => {
  const templates = previewTemplates.value
  if (templates.length === 0) return ''

  const minutes = templates.map((t) => estimatePlanDurationMinutes(t, durationAssumptions.value))
  const first = formatPlanDurationEstimate(minutes[0]!)
  if (minutes.length === 1) return first

  const min = Math.min(...minutes)
  const max = Math.max(...minutes)
  if (min === max) return `${first} each`
  return `${formatPlanDurationEstimate(min)}–${formatPlanDurationEstimate(max)} each`
})

watch(
  () => props.open,
  (v) => {
    if (!v) closeLibraryDetail()
  },
)

function planDurationLabel(template: WorkoutTemplate): string {
  return formatPlanDurationEstimate(estimatePlanDurationMinutes(template, durationAssumptions.value))
}

function formatTemplateWeight(s: string | undefined): string {
  if (!s?.trim()) return ''
  const lbs = parseStoredLbs(s)
  if (Number.isNaN(lbs)) return s
  return formatWeightWithUnit(lbs, weightUnit.value, 1)
}

function resolveLibraryEntry(ex: { libraryId?: string; name?: string }): LibraryExercise | null {
  if (ex.libraryId) {
    const byId = getLibraryExercise(ex.libraryId)
    if (byId) return byId
  }
  return findLibraryExerciseByName(ex.name) ?? null
}

function openLibraryDetail(ex: { libraryId?: string; name?: string }) {
  const entry = resolveLibraryEntry(ex)
  if (!entry) return
  detailExercise.value = entry
  detailOpen.value = true
}

function closeLibraryDetail() {
  detailOpen.value = false
  detailExercise.value = null
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
        class="max-h-[90vh] overflow-y-auto rounded-t-2xl border border-border border-b-0 bg-card px-4 pb-8 pt-2"
        @click.stop
      >
        <div class="mx-auto mb-3 h-1 w-10 rounded-full bg-border" />
        <h3 class="text-center text-lg font-extrabold text-foreground">Plan preview</h3>
        <p class="mt-1 text-center text-sm font-semibold text-foreground">{{ entry.title }}</p>
        <p v-if="previewTemplates.length" class="mt-1 text-center text-xs text-muted">
          <template v-if="isMultiSession">
            {{ previewTemplates.length }} workouts · {{ durationLabel }}
          </template>
          <template v-else>
            {{ durationLabel }}
          </template>
        </p>

        <div v-if="previewTemplates.length === 0" class="mt-4 text-center text-sm text-muted">
          No workout templates found for this plan.
        </div>

        <div v-else class="mt-4 space-y-3">
          <section
            v-for="(template, index) in previewTemplates"
            :key="template.id"
            class="rounded-xl border border-border bg-card-inner px-3 py-3"
          >
            <div v-if="isMultiSession" class="mb-2">
              <p class="text-xs font-bold uppercase tracking-wide text-primary">
                Day {{ index + 1 }}
              </p>
              <div class="font-bold text-foreground">{{ template.name }}</div>
              <div class="text-xs text-muted">
                {{ template.exercises.length }} exercise{{ template.exercises.length !== 1 ? 's' : '' }}
                · {{ planDurationLabel(template) }}
              </div>
            </div>

            <p
              v-if="template.notes?.trim()"
              class="mb-2 whitespace-pre-line rounded-lg border border-border bg-card px-2 py-1.5 text-xs leading-relaxed text-foreground"
            >
              {{ template.notes }}
            </p>

            <ul class="space-y-1" :class="isMultiSession ? 'border-t border-border pt-2' : 'space-y-2'">
              <li
                v-for="ex in template.exercises"
                :key="ex.id"
                :class="
                  isMultiSession
                    ? 'flex flex-wrap items-center gap-2 text-sm text-foreground'
                    : 'rounded-lg border border-border bg-card px-3 py-2'
                "
              >
                <template v-if="isMultiSession">
                  <span class="text-muted">·</span>
                  <button
                    type="button"
                    class="font-semibold text-left"
                    :class="resolveLibraryEntry(ex) ? 'hover:text-primary' : 'cursor-default'"
                    :disabled="!resolveLibraryEntry(ex)"
                    @click="openLibraryDetail(ex)"
                  >
                    {{ ex.name }}
                  </button>
                  <span
                    v-if="supersetBadgeLabel(ex)"
                    class="rounded bg-primary/15 px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-primary"
                  >
                    {{ supersetBadgeLabel(ex) }}
                  </span>
                  <button
                    v-if="ex.libraryId && getLibraryExercise(ex.libraryId)"
                    type="button"
                    class="text-primary hover:text-foreground"
                    aria-label="How to perform this exercise"
                    @click.stop="openLibraryDetail(ex)"
                  >
                    <i class="fa-solid fa-circle-info text-xs" aria-hidden="true" />
                  </button>
                  <span class="text-xs text-muted">
                    {{ ex.sets.length }} × {{ ex.sets[0]?.targetReps || '?' }}
                    <template v-if="formatTemplateWeight(ex.sets[0]?.targetWeight)">
                      @ {{ formatTemplateWeight(ex.sets[0]?.targetWeight) }}
                    </template>
                  </span>
                </template>
                <button
                  v-else
                  type="button"
                  class="flex w-full items-center justify-between gap-2 text-left"
                  :disabled="!resolveLibraryEntry(ex)"
                  :class="resolveLibraryEntry(ex) ? 'hover:text-primary' : 'cursor-default'"
                  @click="openLibraryDetail(ex)"
                >
                  <span class="min-w-0 flex-1">
                    <span class="block text-sm font-bold text-foreground">{{ ex.name }}</span>
                    <span class="text-xs text-muted">
                      {{ ex.sets.length }} sets
                      <template v-if="ex.sets[0]?.targetReps">
                        · {{ ex.sets[0].targetReps }} reps
                      </template>
                      <template v-if="formatTemplateWeight(ex.sets[0]?.targetWeight)">
                        · {{ formatTemplateWeight(ex.sets[0]?.targetWeight) }}
                      </template>
                    </span>
                  </span>
                  <span
                    v-if="supersetBadgeLabel(ex)"
                    class="shrink-0 rounded bg-primary/15 px-1.5 py-0.5 text-[10px] font-bold text-primary"
                  >
                    {{ supersetBadgeLabel(ex) }}
                  </span>
                </button>
              </li>
            </ul>
          </section>
        </div>

        <button
          type="button"
          class="mt-6 w-full rounded-lg border border-border py-3 text-sm font-bold text-foreground"
          @click="emit('close')"
        >
          Close
        </button>
      </div>
    </div>
  </Teleport>

  <ExerciseDetailSheet
    :open="detailOpen"
    :exercise="detailExercise"
    @close="closeLibraryDetail"
  />
</template>
