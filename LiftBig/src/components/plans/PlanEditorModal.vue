<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import LibraryPickerModal from '@/components/library/LibraryPickerModal.vue'
import { settingsInjectionKey } from '@/composables/injectionKeys'
import type { TemplateExercise, WorkoutTemplate } from '@/types/workout'
import { cardioTargetDurationMinutes, cardioTargetDistance } from '@/types/workout'
import { cardioExerciseSupportsDistance } from '@/utils/cardioDistance'
import { distanceUnitLabel, formatDistanceWithUnit, normalizeDistanceInput } from '@/utils/distances'
import type { LibraryExercise } from '@/utils/exerciseLibrary'
import { libraryExerciseIsCardio } from '@/utils/exerciseLibrary'
import {
  estimatePlanDurationMinutes,
  formatPlanDurationEstimate,
  planDurationAssumptionsFromSeconds,
} from '@/utils/planDuration'
import type { WeightUnit } from '@/utils/units'
import { displayInputToStoredLbsString, storedLbsStringToDisplay } from '@/utils/units'

const settings = inject(settingsInjectionKey)!
const distanceUnit = computed(() => settings.distanceUnit.value)

const props = defineProps<{
  show: boolean
  initial: WorkoutTemplate | null
  weightUnit: WeightUnit
}>()

const emit = defineEmits<{
  close: []
  save: [payload: { id: string | null; name: string; exercises: TemplateExercise[] }]
}>()

const planName = ref('')
const exercises = ref<TemplateExercise[]>([])
const libraryOpen = ref(false)
const goalsEditorOpen = ref<Record<string, boolean>>({})

/** Draft minutes for this modal’s time estimate only (initialized from settings when opened). */
const draftLiftMinutes = ref(1)
const draftRestMinutes = ref(1)

const durationAssumptions = computed(() => {
  const lift = Number(draftLiftMinutes.value)
  const rest = Number(draftRestMinutes.value)
  return {
    minutesPerSet: Math.max(1 / 120, Number.isFinite(lift) && lift > 0 ? lift : 1),
    minutesRestBetweenSets: Math.max(1 / 120, Number.isFinite(rest) && rest > 0 ? rest : 1),
  }
})

const estimatedDurationLabel = computed(() =>
  formatPlanDurationEstimate(
    estimatePlanDurationMinutes(
      {
        id: 'draft',
        name: '',
        exercises: exercises.value,
      },
      durationAssumptions.value,
    ),
  ),
)

function resetDurationDraftFromSettings() {
  const a = planDurationAssumptionsFromSeconds(
    settings.averageLiftSeconds.value,
    settings.averageRestSeconds.value,
  )
  draftLiftMinutes.value = Math.round(a.minutesPerSet * 100) / 100
  draftRestMinutes.value = Math.round(a.minutesRestBetweenSets * 100) / 100
}

function blankExercise(): TemplateExercise {
  return {
    id: `new-ex-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
    name: '',
    sets: [{ targetReps: '', targetWeight: '' }],
    targetReps: '',
    targetWeight: '',
  }
}

function blankCardioExercise(): TemplateExercise {
  return {
    id: `new-ex-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
    name: '',
    isCardio: true,
    targetDuration: '',
    targetDistance: '',
    sets: [{ targetReps: '', targetWeight: '' }],
  }
}

function resetFromProps() {
  goalsEditorOpen.value = {}
  resetDurationDraftFromSettings()
  if (props.initial) {
    planName.value = props.initial.name
    exercises.value = JSON.parse(JSON.stringify(props.initial.exercises)) as TemplateExercise[]
  } else {
    planName.value = ''
    exercises.value = [blankExercise()]
  }
}

watch(
  () => props.show,
  (v) => {
    if (v) resetFromProps()
    else libraryOpen.value = false
  },
)

function updateExercise(index: number, updated: TemplateExercise) {
  exercises.value = exercises.value.map((e, i) => (i === index ? updated : e))
}

function addSet(exIndex: number) {
  const ex = exercises.value[exIndex]
  if (!ex) return
  updateExercise(exIndex, {
    ...ex,
    sets: [...ex.sets, { targetReps: '', targetWeight: '' }],
  })
}

function removeSet(exIndex: number, setIndex: number) {
  const ex = exercises.value[exIndex]
  if (!ex || ex.sets.length <= 1) return
  updateExercise(exIndex, {
    ...ex,
    sets: ex.sets.filter((_, i) => i !== setIndex),
  })
}

function addExercise() {
  exercises.value = [...exercises.value, blankExercise()]
}

function addCardioExercise() {
  exercises.value = [...exercises.value, blankCardioExercise()]
}

function addFromLibrary(ex: LibraryExercise) {
  if (libraryExerciseIsCardio(ex)) {
    exercises.value = [
      ...exercises.value,
      {
        ...blankCardioExercise(),
        name: ex.name,
        libraryId: ex.id,
      },
    ]
    return
  }
  exercises.value = [
    ...exercises.value,
    {
      ...blankExercise(),
      name: ex.name,
      libraryId: ex.id,
    },
  ]
}

function removeExercise(index: number) {
  const removed = exercises.value[index]
  if (removed) {
    const { [removed.id]: _, ...rest } = goalsEditorOpen.value
    goalsEditorOpen.value = rest
  }
  exercises.value = exercises.value.filter((_, i) => i !== index)
}

function onTargetWeightInput(exIndex: number, setIndex: number, raw: string) {
  const ex = exercises.value[exIndex]
  if (!ex) return
  const next = displayInputToStoredLbsString(raw, props.weightUnit)
  const sets = ex.sets.map((s, i) => (i === setIndex ? { ...s, targetWeight: next } : s))
  updateExercise(exIndex, { ...ex, sets })
}

function toggleGoalsEditor(exId: string) {
  goalsEditorOpen.value = {
    ...goalsEditorOpen.value,
    [exId]: !goalsEditorOpen.value[exId],
  }
}

function goalSummaryLine(ex: TemplateExercise): string {
  if (ex.isCircuit) return ''
  if (ex.isCardio) {
    const parts: string[] = []
    const d = cardioTargetDurationMinutes(ex)
    if (d) parts.push(`${d} min`)
    if (cardioExerciseSupportsDistance(ex)) {
      const dist = cardioTargetDistance(ex)
      if (dist) parts.push(formatDistanceWithUnit(dist, distanceUnit.value))
    }
    return parts.length ? `Goal: ${parts.join(' · ')}` : ''
  }
  const n = ex.sets.length
  const reps = (ex.targetReps ?? '').trim()
  const w = (ex.targetWeight ?? '').trim()
  if (!reps && !w) return ''
  const mid = reps ? `${n} × ${reps}` : `${n} sets`
  const tail = w ? ` @ ${storedLbsStringToDisplay(w, props.weightUnit)}` : ''
  return `Goal: ${mid}${tail}`
}

function onCardioDurationInput(exIndex: number, raw: string) {
  const ex = exercises.value[exIndex]
  if (!ex) return
  const trimmed = raw.trim()
  updateExercise(exIndex, {
    ...ex,
    targetDuration: trimmed,
    sets: [{ targetReps: trimmed, targetWeight: '' }],
  })
}

function onCardioDistanceInput(exIndex: number, raw: string) {
  const ex = exercises.value[exIndex]
  if (!ex) return
  const trimmed = normalizeDistanceInput(raw)
  updateExercise(exIndex, {
    ...ex,
    targetDistance: trimmed,
  })
}

function onGoalWeightInput(exIndex: number, raw: string) {
  const ex = exercises.value[exIndex]
  if (!ex) return
  const next = displayInputToStoredLbsString(raw, props.weightUnit)
  updateExercise(exIndex, { ...ex, targetWeight: next })
}

function save() {
  const name = planName.value.trim()
  if (!name) {
    window.alert('Please give your plan a name.')
    return
  }
  const named = exercises.value.filter((e) => e.name.trim().length > 0)
  if (named.length === 0) {
    window.alert('Add at least one exercise with a name.')
    return
  }
  emit('save', {
    id: props.initial?.id ?? null,
    name,
    exercises: named,
  })
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
        class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-card p-4 sm:max-h-[85vh] sm:rounded-2xl"
        @click.stop
      >
        <h3 class="text-lg font-extrabold text-foreground">
          {{ initial ? 'Edit Plan' : 'New Plan' }}
        </h3>
        <label class="mt-3 block text-xs font-bold uppercase tracking-wide text-muted">Plan name</label>
        <input
          v-model="planName"
          type="text"
          class="mt-1 w-full rounded-lg border border-border bg-card-inner px-3 py-2 text-foreground outline-none focus:border-primary"
          placeholder="e.g. Push Day"
        />

        <div class="mt-4 space-y-3">
          <div
            v-for="(ex, ei) in exercises"
            :key="ex.id"
            class="rounded-xl border border-border bg-card-inner p-3"
          >
            <div class="mb-2 flex items-center justify-between">
              <span class="text-xs font-bold text-muted">Exercise {{ ei + 1 }}</span>
              <button
                type="button"
                class="text-xs font-semibold text-red-400"
                @click="removeExercise(ei)"
              >
                Remove
              </button>
            </div>
            <input
              v-model="ex.name"
              type="text"
              class="mb-2 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground"
              placeholder="Exercise name"
            />
            <template v-if="ex.isCardio">
              <div class="mb-2 flex min-w-0 flex-wrap items-center gap-x-3 gap-y-1">
                <p v-if="goalSummaryLine(ex)" class="min-w-0 flex-1 text-[11px] leading-snug text-muted">
                  {{ goalSummaryLine(ex) }}
                </p>
                <span v-else class="text-[11px] text-muted">Target duration (optional)</span>
              </div>
              <div
                class="grid gap-2"
                :class="cardioExerciseSupportsDistance(ex) ? 'grid-cols-2' : 'grid-cols-1'"
              >
                <div>
                  <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Duration (min)</label>
                  <input
                    :value="cardioTargetDurationMinutes(ex)"
                    type="text"
                    inputmode="numeric"
                    class="mt-0.5 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
                    placeholder="e.g. 30"
                    @input="onCardioDurationInput(ei, ($event.target as HTMLInputElement).value)"
                  />
                </div>
                <div v-if="cardioExerciseSupportsDistance(ex)">
                  <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">
                    Distance ({{ distanceUnitLabel(distanceUnit) }})
                  </label>
                  <input
                    :value="cardioTargetDistance(ex)"
                    type="text"
                    inputmode="decimal"
                    class="mt-0.5 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
                    placeholder="Optional"
                    @input="onCardioDistanceInput(ei, ($event.target as HTMLInputElement).value)"
                  />
                </div>
              </div>
            </template>
            <template v-else-if="!ex.isCircuit">
              <div class="mb-2 flex min-w-0 flex-wrap items-center gap-x-3 gap-y-1">
                <button
                  type="button"
                  class="shrink-0 text-xs font-semibold text-muted hover:text-primary"
                  :aria-expanded="!!goalsEditorOpen[ex.id]"
                  :aria-controls="`plan-editor-goals-${ex.id}`"
                  @click="toggleGoalsEditor(ex.id)"
                >
                  {{ goalsEditorOpen[ex.id] ? 'Hide goals' : 'Set goals' }}
                </button>
                <p v-if="goalSummaryLine(ex)" class="min-w-0 flex-1 text-[11px] leading-snug text-muted">
                  {{ goalSummaryLine(ex) }}
                </p>
              </div>
              <div
                v-if="goalsEditorOpen[ex.id]"
                :id="`plan-editor-goals-${ex.id}`"
                class="mb-3 grid grid-cols-2 gap-2"
              >
                <div>
                  <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal reps</label>
                  <input
                    :value="ex.targetReps ?? ''"
                    type="text"
                    class="mt-0.5 w-full rounded-lg border border-border bg-background px-2 py-1.5 text-[13px] text-foreground outline-none focus:border-primary"
                    placeholder="e.g. 8–12"
                    inputmode="text"
                    @input="updateExercise(ei, { ...ex, targetReps: ($event.target as HTMLInputElement).value })"
                  />
                </div>
                <div>
                  <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal weight</label>
                  <input
                    :value="storedLbsStringToDisplay(ex.targetWeight ?? '', weightUnit)"
                    type="text"
                    inputmode="decimal"
                    class="mt-0.5 w-full rounded-lg border border-border bg-background px-2 py-1.5 text-[13px] text-foreground outline-none focus:border-primary"
                    :placeholder="weightUnit === 'lb' ? 'lb' : 'kg'"
                    @input="onGoalWeightInput(ei, ($event.target as HTMLInputElement).value)"
                  />
                </div>
              </div>
            </template>
            <template v-if="!ex.isCardio">
            <div
              class="grid grid-cols-[2.25rem_1fr_1fr_1.75rem] items-center gap-x-1 text-[10px] font-bold uppercase text-muted"
            >
              <span class="text-center">Set</span>
              <span class="text-center">Reps</span>
              <span class="text-center">{{ weightUnit === 'lb' ? 'lb' : 'kg' }}</span>
              <span />
            </div>
            <div
              v-for="(set, si) in ex.sets"
              :key="si"
              class="mt-1 grid grid-cols-[2.25rem_1fr_1fr_1.75rem] items-center gap-x-1"
            >
              <span class="text-center text-xs tabular-nums text-muted">{{ si + 1 }}</span>
              <input
                v-model="set.targetReps"
                type="text"
                inputmode="numeric"
                class="min-w-0 w-full rounded border border-border bg-background px-1 py-1 text-center text-sm text-foreground"
              />
              <input
                :value="storedLbsStringToDisplay(set.targetWeight, weightUnit)"
                type="text"
                inputmode="decimal"
                class="min-w-0 w-full rounded border border-border bg-background px-1 py-1 text-center text-sm text-foreground"
                @input="onTargetWeightInput(ei, si, ($event.target as HTMLInputElement).value)"
              />
              <button
                type="button"
                class="flex justify-center text-muted"
                :disabled="ex.sets.length <= 1"
                @click="removeSet(ei, si)"
              >
                ✕
              </button>
            </div>
            <button
              type="button"
              class="mt-2 text-xs font-bold text-primary"
              @click="addSet(ei)"
            >
              + Add Set
            </button>
            </template>
          </div>
        </div>

        <div class="mt-3 flex flex-col gap-2 sm:flex-row">
          <button
            type="button"
            class="flex-1 rounded-lg border border-border py-2 text-sm font-bold text-foreground"
            @click="addExercise"
          >
            + Add exercise
          </button>
          <button
            type="button"
            class="flex-1 rounded-lg border border-border py-2 text-sm font-bold text-foreground"
            @click="addCardioExercise"
          >
            + Add cardio
          </button>
          <button
            type="button"
            class="flex-1 rounded-lg border border-primary/50 bg-card-inner py-2 text-sm font-bold text-primary"
            @click="libraryOpen = true"
          >
            + From library
          </button>
        </div>

        <p class="mt-3 text-center text-[11px] text-muted">
          Est. {{ estimatedDurationLabel }}
        </p>
        <p class="mt-1.5 flex flex-wrap items-center justify-center gap-x-1 gap-y-1 text-center text-[11px] text-muted">
          <input
            v-model.number="draftLiftMinutes"
            type="number"
            step="0.25"
            min="0.25"
            max="45"
            aria-label="Minutes per set for time estimate"
            class="w-[3.35rem] rounded border border-border bg-card-inner px-1 py-0.5 text-center text-[11px] font-bold tabular-nums text-foreground outline-none focus:border-primary"
          />
          <span>min per set ·</span>
          <input
            v-model.number="draftRestMinutes"
            type="number"
            step="0.25"
            min="0.25"
            max="45"
            aria-label="Minutes rest between sets for time estimate"
            class="w-[3.35rem] rounded border border-border bg-card-inner px-1 py-0.5 text-center text-[11px] font-bold tabular-nums text-foreground outline-none focus:border-primary"
          />
          <span>min rest between sets</span>
        </p>

        <div class="mt-4 flex gap-2">
          <button
            type="button"
            class="flex-1 rounded-lg bg-primary py-3 text-sm font-extrabold text-foreground"
            @click="save"
          >
            Save
          </button>
          <button
            type="button"
            class="flex-1 rounded-lg border border-border py-3 text-sm font-bold text-muted"
            @click="emit('close')"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>

    <LibraryPickerModal
      :show="libraryOpen"
      @close="libraryOpen = false"
      @pick="addFromLibrary"
    />
  </Teleport>
</template>
