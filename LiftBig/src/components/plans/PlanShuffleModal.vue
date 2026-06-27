<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import type { WorkoutTemplate } from '@/types/workout'
import {
  LIBRARY_EQUIPMENT_TYPES,
  MOVEMENT_PATTERNS,
  MOVEMENT_PATTERN_LABELS,
  allMuscleGroups,
  buildShuffledPlan,
  exerciseMovementPatterns,
  filterLibraryForShuffle,
  formatFocusLabel,
  type ShuffleFocus,
  type ShuffleMode,
} from '@/utils/planShuffle'
import {
  estimatePlanDurationMinutes,
  formatPlanDurationEstimate,
  planDurationAssumptionsFromSeconds,
} from '@/utils/planDuration'
import { getLibraryExercise } from '@/utils/exerciseLibrary'
import { settingsInjectionKey } from '@/composables/injectionKeys'

const props = defineProps<{
  show: boolean
}>()

const emit = defineEmits<{
  close: []
  save: [
    payload: {
      id: string | null
      name: string
      exercises: import('@/types/workout').TemplateExercise[]
      prepend?: boolean
    },
  ]
}>()

const settings = inject(settingsInjectionKey)!

const MIN_PACE_SECONDS = 5
const MAX_PACE_SECONDS = 600

function clampPace(value: number, fallback: number): number {
  if (!Number.isFinite(value)) return fallback
  return Math.min(MAX_PACE_SECONDS, Math.max(MIN_PACE_SECONDS, Math.round(value)))
}

const selectedEquipment = ref<string[]>([])
const includeCardio = ref(false)
const selectedFocus = ref<ShuffleFocus[]>([])
const mode = ref<ShuffleMode>('duration')
const targetMinutes = ref(45)
const exerciseCount = ref(6)
const secondsPerSet = ref(settings.averageLiftSeconds.value)
const secondsPerRest = ref(settings.averageRestSeconds.value)
const previewPlan = ref<WorkoutTemplate | null>(null)
const saveName = ref('')
const matchWarning = ref<string | null>(null)

const muscleGroups = allMuscleGroups()

const poolSize = computed(() => {
  return filterLibraryForShuffle(
    selectedEquipment.value,
    selectedFocus.value,
    includeCardio.value,
  ).length
})

const durationAssumptions = computed(() =>
  planDurationAssumptionsFromSeconds(
    clampPace(secondsPerSet.value, settings.averageLiftSeconds.value),
    clampPace(secondsPerRest.value, settings.averageRestSeconds.value),
  ),
)

const previewDurationLabel = computed(() => {
  if (!previewPlan.value) return ''
  return formatPlanDurationEstimate(
    estimatePlanDurationMinutes(previewPlan.value, durationAssumptions.value),
  )
})

function resetForm() {
  selectedEquipment.value = []
  includeCardio.value = false
  selectedFocus.value = []
  mode.value = 'duration'
  targetMinutes.value = 45
  exerciseCount.value = 6
  secondsPerSet.value = settings.averageLiftSeconds.value
  secondsPerRest.value = settings.averageRestSeconds.value
  previewPlan.value = null
  saveName.value = ''
  matchWarning.value = null
}

watch(
  () => props.show,
  (v) => {
    if (v) resetForm()
  },
)

function toggleEquipment(eq: string) {
  const set = new Set(selectedEquipment.value)
  if (set.has(eq)) set.delete(eq)
  else set.add(eq)
  selectedEquipment.value = [...set].sort((a, b) => a.localeCompare(b))
}

function selectAllEquipment() {
  selectedEquipment.value = [...LIBRARY_EQUIPMENT_TYPES]
}

function toggleFocus(f: ShuffleFocus) {
  const arr = selectedFocus.value.filter((x) => x !== f)
  if (arr.length === selectedFocus.value.length) {
    selectedFocus.value = [...selectedFocus.value, f]
  } else {
    selectedFocus.value = arr
  }
}

function focusActive(f: ShuffleFocus): boolean {
  return selectedFocus.value.includes(f)
}

function equipmentActive(eq: string): boolean {
  return selectedEquipment.value.includes(eq)
}

function runShuffle() {
  matchWarning.value = null
  secondsPerSet.value = clampPace(secondsPerSet.value, settings.averageLiftSeconds.value)
  secondsPerRest.value = clampPace(secondsPerRest.value, settings.averageRestSeconds.value)
  const plan = buildShuffledPlan({
    selectedEquipment: selectedEquipment.value,
    selectedFocus: selectedFocus.value,
    includeCardio: includeCardio.value,
    mode: mode.value,
    targetMinutes: targetMinutes.value,
    exerciseCount: exerciseCount.value,
    durationAssumptions: durationAssumptions.value,
  })
  if (plan.exercises.length === 0) {
    matchWarning.value =
      'No exercises match your filters. Select at least one equipment type, turn on cardio if you want it, or loosen your focus filters.'
    previewPlan.value = null
    return
  }
  previewPlan.value = plan
}

function reshuffle() {
  if (!previewPlan.value) return
  runShuffle()
}

function discardPreview() {
  previewPlan.value = null
  matchWarning.value = null
}

function savePlan() {
  if (!previewPlan.value?.exercises.length) return
  const name = saveName.value.trim()
  if (!name) {
    window.alert('Please give your plan a name.')
    return
  }
  emit('save', {
    id: null,
    name,
    exercises: previewPlan.value.exercises,
    prepend: true,
  })
  emit('close')
}

function patternLabelsForLibraryId(libraryId: string | undefined): string {
  if (!libraryId) return ''
  const ex = getLibraryExercise(libraryId)
  if (!ex) return ''
  return exerciseMovementPatterns(ex)
    .map((p) => MOVEMENT_PATTERN_LABELS[p])
    .join(' · ')
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="show"
      class="fixed inset-0 z-50 flex items-end justify-center bg-black/65 sm:items-center"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[92vh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-card p-4 sm:max-h-[88vh] sm:rounded-2xl"
        @click.stop
      >
        <div class="flex items-start justify-between gap-2">
          <h3 class="text-lg font-extrabold text-foreground">Shuffle plan</h3>
          <button
            type="button"
            class="text-sm font-bold text-muted hover:text-foreground"
            @click="emit('close')"
          >
            Close
          </button>
        </div>

        <template v-if="!previewPlan">
          <p class="mt-2 text-xs leading-snug text-muted">
            Select the equipment you have available, then choose a target session length or number of lifts. Optionally
            narrow by muscle groups or push / pull / legs. Lifts are picked at random, then ordered compounds first with
            muscle-group variety.
          </p>

          <label class="mt-4 block text-xs font-bold uppercase tracking-wide text-muted">Equipment</label>
          <p class="mt-1 text-[11px] text-muted">
            Choose each type of gear you can use. Nothing is selected until you pick it.
          </p>
          <div class="mt-2 flex flex-wrap gap-2">
            <button
              type="button"
              class="rounded-full border px-3 py-1 text-xs font-bold transition-colors"
              :class="
                equipmentActive(eq)
                  ? 'border-primary bg-primary/15 text-primary'
                  : 'border-border text-muted hover:border-primary/50'
              "
              v-for="eq in LIBRARY_EQUIPMENT_TYPES"
              :key="eq"
              @click="toggleEquipment(eq)"
            >
              {{ eq }}
            </button>
          </div>
          <button
            type="button"
            class="mt-2 text-xs font-bold text-primary"
            @click="selectAllEquipment"
          >
            Select all equipment
          </button>
          <button
            type="button"
            class="mt-2 flex w-full items-center justify-between rounded-lg border border-border bg-card-inner px-3 py-2.5 text-left transition-colors hover:border-primary/40"
            :class="includeCardio ? 'border-primary/50' : ''"
            @click="includeCardio = !includeCardio"
          >
            <span class="text-xs font-bold text-foreground">Include cardio</span>
            <span
              class="rounded-full px-2 py-0.5 text-[10px] font-extrabold uppercase tracking-wide"
              :class="
                includeCardio
                  ? 'bg-primary/20 text-primary'
                  : 'bg-card text-muted'
              "
            >
              {{ includeCardio ? 'On' : 'Off' }}
            </span>
          </button>
          <p class="mt-1 text-[11px] text-muted">
            When on, cardio and sports from the library can appear if their equipment matches your selection.
          </p>

          <label class="mt-4 block text-xs font-bold uppercase tracking-wide text-muted">Session size</label>
          <div class="mt-2 flex gap-2">
            <button
              type="button"
              class="flex-1 rounded-lg border py-2 text-xs font-bold"
              :class="mode === 'duration' ? 'border-primary bg-primary/15 text-primary' : 'border-border text-muted'"
              @click="mode = 'duration'"
            >
              Target duration
            </button>
            <button
              type="button"
              class="flex-1 rounded-lg border py-2 text-xs font-bold"
              :class="mode === 'count' ? 'border-primary bg-primary/15 text-primary' : 'border-border text-muted'"
              @click="mode = 'count'"
            >
              Number of lifts
            </button>
          </div>

          <div v-if="mode === 'duration'" class="mt-3">
            <div class="flex flex-wrap items-end gap-3">
              <div class="min-w-[8rem] flex-1">
                <label class="text-xs font-bold text-muted">Minutes (~{{ targetMinutes }})</label>
                <input
                  v-model.number="targetMinutes"
                  type="range"
                  min="15"
                  max="120"
                  step="5"
                  class="mt-1 w-full accent-primary"
                />
              </div>
              <div class="flex shrink-0 items-end gap-2">
                <label class="block text-[11px] font-bold uppercase tracking-wide text-muted">
                  Sec / set
                  <input
                    v-model.number="secondsPerSet"
                    type="number"
                    :min="MIN_PACE_SECONDS"
                    :max="MAX_PACE_SECONDS"
                    step="5"
                    inputmode="numeric"
                    class="mt-1 w-20 rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-sm font-semibold text-foreground outline-none focus:border-primary"
                  />
                </label>
                <label class="block text-[11px] font-bold uppercase tracking-wide text-muted">
                  Sec / rest
                  <input
                    v-model.number="secondsPerRest"
                    type="number"
                    :min="MIN_PACE_SECONDS"
                    :max="MAX_PACE_SECONDS"
                    step="5"
                    inputmode="numeric"
                    class="mt-1 w-20 rounded-lg border border-border bg-card-inner px-2 py-1.5 text-center text-sm font-semibold text-foreground outline-none focus:border-primary"
                  />
                </label>
              </div>
            </div>
            <p class="mt-1 text-[11px] text-muted">
              Exercises are added until the estimated time (from sets + rest) reaches this target.
            </p>
          </div>

          <div v-else class="mt-3">
            <label class="block text-xs font-bold text-muted">Unique exercises</label>
            <input
              v-model.number="exerciseCount"
              type="number"
              min="1"
              max="40"
              class="mt-1 w-full rounded-lg border border-border bg-card-inner px-3 py-2 text-foreground outline-none focus:border-primary"
            />
          </div>

          <label class="mt-4 block text-xs font-bold uppercase tracking-wide text-muted">
            Focus <span class="font-normal normal-case text-muted">(optional)</span>
          </label>
          <p class="mt-1 text-[11px] text-muted">
            Leave empty to allow any muscle pattern. With selections, an exercise matches if it hits any selected muscle
            group or movement pattern.
          </p>
          <div class="mt-2 flex flex-wrap gap-2">
            <button
              type="button"
              class="rounded-full border px-3 py-1 text-xs font-bold transition-colors"
              :class="
                focusActive(p)
                  ? 'border-primary bg-primary/15 text-primary'
                  : 'border-border text-muted hover:border-primary/50'
              "
              v-for="p in MOVEMENT_PATTERNS"
              :key="p"
              @click="toggleFocus(p)"
            >
              {{ MOVEMENT_PATTERN_LABELS[p] }}
            </button>
          </div>
          <div class="mt-2 flex flex-wrap gap-2">
            <button
              type="button"
              class="rounded-full border px-3 py-1 text-xs font-bold transition-colors"
              :class="
                focusActive(g)
                  ? 'border-primary bg-primary/15 text-primary'
                  : 'border-border text-muted hover:border-primary/50'
              "
              v-for="g in muscleGroups"
              :key="g"
              @click="toggleFocus(g)"
            >
              {{ formatFocusLabel(g) }}
            </button>
          </div>

          <p class="mt-3 text-xs text-muted">
            <span class="font-bold text-foreground">{{ poolSize }}</span>
            exercise{{ poolSize !== 1 ? 's' : '' }} in pool with current filters.
          </p>

          <p v-if="matchWarning" class="mt-2 rounded-lg border border-amber-900/50 bg-amber-950/40 px-3 py-2 text-xs text-amber-200">
            {{ matchWarning }}
          </p>

          <button
            type="button"
            class="mt-4 w-full rounded-lg bg-primary py-3 text-sm font-extrabold text-foreground"
            @click="runShuffle"
          >
            Generate plan
          </button>
        </template>

        <template v-else>
          <label class="mt-3 block text-xs font-bold uppercase tracking-wide text-muted">Plan name</label>
          <input
            v-model="saveName"
            type="text"
            class="mt-1 w-full rounded-lg border border-border bg-card-inner px-3 py-2 text-foreground outline-none focus:border-primary"
            placeholder="e.g. Upper body shuffle"
            autofocus
          />
          <p class="mt-1 text-[11px] text-muted">Name your plan before saving.</p>

          <p class="mt-3 text-xs text-muted">
            {{ previewPlan.exercises.length }} lift{{ previewPlan.exercises.length !== 1 ? 's' : '' }}
            · {{ previewDurationLabel }}
          </p>

          <ul class="mt-3 max-h-[40vh] space-y-2 overflow-y-auto border-t border-border pt-3">
            <li
              v-for="(ex, idx) in previewPlan.exercises"
              :key="ex.id"
              class="rounded-lg border border-border bg-card-inner px-3 py-2 text-sm"
            >
              <div class="font-semibold text-foreground">{{ idx + 1 }}. {{ ex.name }}</div>
              <div class="mt-0.5 text-[11px] text-muted">
                3 × {{ ex.sets[0]?.targetReps || '8-12' }}
                <template v-if="patternLabelsForLibraryId(ex.libraryId)">
                  · {{ patternLabelsForLibraryId(ex.libraryId) }}
                </template>
              </div>
            </li>
          </ul>

          <div class="mt-4 flex flex-col gap-2 sm:flex-row">
            <button
              type="button"
              class="flex-1 rounded-lg border border-border py-2 text-sm font-bold text-foreground"
              @click="reshuffle"
            >
              Reshuffle
            </button>
            <button
              type="button"
              class="flex-1 rounded-lg border border-red-900/50 py-2 text-sm font-bold text-red-400"
              @click="discardPreview"
            >
              Delete draft
            </button>
            <button
              type="button"
              class="flex-1 rounded-lg bg-primary py-2 text-sm font-extrabold text-foreground"
              @click="savePlan"
            >
              Save plan
            </button>
          </div>
        </template>
      </div>
    </div>
  </Teleport>
</template>
