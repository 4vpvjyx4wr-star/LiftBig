<script setup lang="ts">
import { computed, inject, onBeforeUnmount, ref, watch } from 'vue'
import ExerciseDetailSheet from '@/components/library/ExerciseDetailSheet.vue'
import SetRow from '@/components/workout/SetRow.vue'
import { settingsInjectionKey } from '@/composables/injectionKeys'
import type { Exercise, WorkoutLog } from '@/types/workout'
import { getLibraryExercise } from '@/utils/exerciseLibrary'
import { getSuggestedWeight } from '@/utils/progressiveOverload'
import {
  formatWeightWithUnit,
  parseStoredLbs,
  storedLbsStringToDisplay,
} from '@/utils/units'

const props = defineProps<{
  exercise: Exercise
  workoutLog: WorkoutLog
}>()

const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)

function formatStoredLbsForDisplay(s: string | undefined): string {
  if (!s?.trim()) return ''
  const lbs = parseStoredLbs(s)
  if (Number.isNaN(lbs)) return s
  return formatWeightWithUnit(lbs, weightUnit.value, 1)
}

/** Same wording as plan-assigned exercises: "Goal: N × reps" with optional "@ weight". */
const goalSummaryLine = computed(() => {
  if (props.exercise.isCircuit) return ''
  weightUnit.value
  const n = props.exercise.sets.length
  const reps = (props.exercise.targetReps ?? '').trim()
  const w = (props.exercise.targetWeight ?? '').trim()
  if (!reps && !w) return ''
  const mid = reps ? `${n} × ${reps}` : `${n} sets`
  const tail = w ? ` @ ${formatStoredLbsForDisplay(props.exercise.targetWeight)}` : ''
  return `Goal: ${mid}${tail}`
})

const emit = defineEmits<{
  addSet: []
  updateSet: [setId: string, field: 'reps' | 'weight', value: string]
  toggleCircuitSet: [setId: string]
  deleteSet: [setId: string]
  swapExercise: []
  deleteExercise: []
  updateGoals: [patch: Partial<{ targetReps: string; targetWeight: string }>]
  updateNotes: [notes: string]
}>()

const NOTES_DEBOUNCE_MS = 550

type ExercisePanel = 'sets' | 'notes'
const activePanel = ref<ExercisePanel>('sets')

const notesDraft = ref(props.exercise.notes ?? '')
let notesDebounceTimer: ReturnType<typeof setTimeout> | null = null

watch(
  () => props.exercise.id,
  () => {
    if (notesDebounceTimer) {
      clearTimeout(notesDebounceTimer)
      notesDebounceTimer = null
    }
    notesDraft.value = props.exercise.notes ?? ''
    activePanel.value = 'sets'
  },
  { immediate: true },
)

function exerciseNotesEqual(stored: string | undefined, draft: string): boolean {
  return (stored ?? '') === draft
}

function commitNotesIfChanged() {
  if (exerciseNotesEqual(props.exercise.notes, notesDraft.value)) return
  emit('updateNotes', notesDraft.value)
}

function scheduleNotesCommit() {
  if (notesDebounceTimer) clearTimeout(notesDebounceTimer)
  notesDebounceTimer = setTimeout(() => {
    notesDebounceTimer = null
    commitNotesIfChanged()
  }, NOTES_DEBOUNCE_MS)
}

function flushNotesCommit() {
  if (notesDebounceTimer) {
    clearTimeout(notesDebounceTimer)
    notesDebounceTimer = null
  }
  commitNotesIfChanged()
}

onBeforeUnmount(() => {
  flushNotesCommit()
})

watch(activePanel, (next, prev) => {
  if (prev === 'notes' && next !== 'notes') {
    flushNotesCommit()
  }
})

const suggestion = ref<{ suggestedWeight: number; reason: string } | null>(null)

function onSetRowUpdate(setId: string, index: number, field: 'reps' | 'weight', value: string) {
  emit('updateSet', setId, field, value)
}

watch(
  () =>
    [
      props.exercise.name,
      props.exercise.targetReps,
      props.exercise.targetWeight,
      props.exercise.sets,
      props.workoutLog,
      weightUnit.value,
    ] as const,
  () => {
    if (props.exercise.isCircuit) {
      suggestion.value = null
      return
    }
    const reps = (props.exercise.targetReps ?? '').trim()
    const tw = (props.exercise.targetWeight ?? '').trim()
    if (!reps && !tw) {
      suggestion.value = null
      return
    }
    const base = parseFloat(
      props.exercise.sets[0]?.weight || props.exercise.targetWeight || '0',
    )
    if (reps) {
      suggestion.value = getSuggestedWeight(
        props.exercise.name,
        reps,
        base,
        props.workoutLog,
        weightUnit.value,
      )
    } else {
      suggestion.value =
        Number.isFinite(base) && base > 0
          ? { suggestedWeight: base, reason: 'No history yet' }
          : null
    }
  },
  { deep: true, immediate: true },
)

const completedSets = computed(() =>
  props.exercise.sets.filter((s) =>
    props.exercise.isCircuit ? s.checked : s.reps !== '' && s.weight !== '',
  ).length,
)

const allDone = computed(
  () =>
    completedSets.value === props.exercise.sets.length && props.exercise.sets.length > 0,
)

const libraryEntry = computed(() => {
  const id = props.exercise.libraryId
  if (!id) return null
  return getLibraryExercise(id) ?? null
})

const detailOpen = ref(false)
const goalsEditorOpen = ref(false)

function openLibraryDetail() {
  if (libraryEntry.value) detailOpen.value = true
}

function closeLibraryDetail() {
  detailOpen.value = false
}
</script>

<template>
  <div
    class="mb-3.5 rounded-xl border border-border bg-card p-3.5"
    :class="allDone ? 'border-[#16a34a]' : ''"
  >
    <div class="mb-2 flex justify-between gap-2">
      <div class="min-w-0 flex-1">
        <div class="flex items-center gap-2">
          <h4
            class="exercise-reorder-handle cursor-grab select-none text-base font-bold text-foreground active:cursor-grabbing touch-manipulation"
            title="Hold, then drag to reorder"
          >
            {{ exercise.name }}
          </h4>
          <button
            v-if="libraryEntry"
            type="button"
            class="shrink-0 text-primary hover:text-foreground"
            aria-label="How to perform this exercise"
            @click="openLibraryDetail"
          >
            <i class="fa-solid fa-circle-info text-sm" aria-hidden="true" />
          </button>
        </div>
        <div
          v-if="!exercise.isCircuit"
          class="mt-1.5 flex min-w-0 flex-wrap items-center gap-x-2 gap-y-1"
        >
          <p v-if="goalSummaryLine" class="min-w-0 text-[11px] leading-snug text-muted">
            {{ goalSummaryLine }}
          </p>
          <span v-else class="text-[11px] text-muted">No goals set</span>
          <button
            type="button"
            class="shrink-0 text-muted hover:text-primary"
            :aria-expanded="goalsEditorOpen"
            :aria-controls="`exercise-goals-editor-${exercise.id}`"
            aria-label="Edit goals"
            @click="goalsEditorOpen = !goalsEditorOpen"
          >
            <i class="fa-solid fa-pen text-[10px]" aria-hidden="true" />
          </button>
        </div>
      </div>
      <div class="flex shrink-0 flex-col items-end gap-1">
        <span
          class="text-[11px] font-bold"
          :class="allDone ? 'text-[#4ade80]' : 'text-muted'"
        >
          {{ allDone ? 'Complete' : `${completedSets}/${exercise.sets.length} sets` }}
        </span>
        <button
          type="button"
          class="text-xs font-semibold text-primary hover:text-foreground"
          @click="emit('swapExercise')"
        >
          Swap
        </button>
        <button
          type="button"
          class="text-xs font-semibold text-red-400"
          @click="emit('deleteExercise')"
        >
          Remove
        </button>
      </div>
    </div>

    <div
      class="mb-2 flex gap-1 rounded-lg border border-border bg-card-inner p-0.5"
      role="tablist"
      aria-label="Exercise sections"
    >
      <button
        type="button"
        role="tab"
        :aria-selected="activePanel === 'sets'"
        class="min-h-[2.25rem] flex-1 rounded-md px-2 text-xs font-bold transition-colors"
        :class="
          activePanel === 'sets'
            ? 'bg-card text-foreground shadow-sm'
            : 'text-muted hover:text-foreground'
        "
        @click="activePanel = 'sets'"
      >
        Sets
      </button>
      <button
        type="button"
        role="tab"
        :aria-selected="activePanel === 'notes'"
        class="min-h-[2.25rem] flex-1 rounded-md px-2 text-xs font-bold transition-colors"
        :class="
          activePanel === 'notes'
            ? 'bg-card text-foreground shadow-sm'
            : 'text-muted hover:text-foreground'
        "
        @click="activePanel = 'notes'"
      >
        Notes
      </button>
    </div>

    <div v-show="activePanel === 'notes'" class="mb-2">
      <label class="sr-only" :for="`exercise-notes-${exercise.id}`">Notes for this exercise</label>
      <textarea
        :id="`exercise-notes-${exercise.id}`"
        v-model="notesDraft"
        rows="4"
        class="w-full resize-y rounded-lg border border-border bg-card-inner px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
        placeholder="Session notes for this exercise (saved automatically)…"
        @input="scheduleNotesCommit"
        @blur="flushNotesCommit"
      />
    </div>

    <div v-show="activePanel === 'sets'">
    <div
      v-if="goalsEditorOpen && !exercise.isCircuit"
      :id="`exercise-goals-editor-${exercise.id}`"
      class="mb-2 grid grid-cols-2 gap-2"
    >
      <div>
        <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal reps</label>
        <input
          :value="exercise.targetReps ?? ''"
          type="text"
          class="mt-0.5 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-[13px] text-foreground outline-none focus:border-primary"
          placeholder="e.g. 8–12"
          inputmode="text"
          @input="emit('updateGoals', { targetReps: ($event.target as HTMLInputElement).value })"
        />
      </div>
      <div>
        <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal weight</label>
        <input
          :value="storedLbsStringToDisplay(exercise.targetWeight ?? '', weightUnit)"
          type="text"
          inputmode="decimal"
          class="mt-0.5 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-[13px] text-foreground outline-none focus:border-primary"
          :placeholder="weightUnit === 'lb' ? 'lb' : 'kg'"
          @input="emit('updateGoals', { targetWeight: ($event.target as HTMLInputElement).value })"
        />
      </div>
    </div>

    <div
      v-if="suggestion && !exercise.isCircuit && suggestion.reason !== 'No history yet'"
      class="mb-2.5 rounded-lg border border-[#16a34a] bg-[#0d2010] p-2"
    >
      <div class="text-[13px] font-bold text-[#4ade80]">
        Suggested: {{ formatWeightWithUnit(suggestion.suggestedWeight, weightUnit, 1) }}
      </div>
      <div class="mt-0.5 text-[11px] text-[#86efac]">{{ suggestion.reason }}</div>
    </div>

    <template v-if="exercise.isCircuit">
      <button
        v-for="(set, index) in exercise.sets"
        :key="set.id"
        type="button"
        class="mb-2 flex w-full items-center gap-3 rounded-lg py-2 text-left hover:bg-card-inner"
        @click="emit('toggleCircuitSet', set.id)"
      >
        <span
          class="flex h-[26px] w-[26px] items-center justify-center rounded-md border-2 text-sm font-extrabold"
          :class="
            set.checked ? 'border-primary bg-primary text-foreground' : 'border-border text-muted'
          "
        >
          {{ set.checked ? '✓' : '' }}
        </span>
        <span class="w-11 text-xs text-muted">Set {{ index + 1 }}</span>
        <span class="flex-1 text-[13px] text-foreground">
          {{ set.reps || 'AMRAP' }} reps @ {{ formatStoredLbsForDisplay(set.weight || '20') }}
        </span>
      </button>
    </template>

    <template v-else>
      <div class="mb-1 flex min-w-0">
        <span class="w-16 shrink-0" />
        <span class="min-w-0 flex-1 basis-0 text-center text-[10px] font-bold uppercase text-muted">Weight</span>
        <span class="min-w-0 flex-1 basis-0 text-center text-[10px] font-bold uppercase text-muted">Reps</span>
        <span class="w-8 shrink-0" />
      </div>
      <SetRow
        v-for="(set, index) in exercise.sets"
        :key="set.id"
        :set="set"
        :index="index"
        :target-reps="exercise.targetReps"
        :target-weight-stored="index === 0 ? exercise.targetWeight : undefined"
        :prior-set-weight-stored="index > 0 ? exercise.sets[index - 1]?.weight : undefined"
        :prior-set-reps="index > 0 ? exercise.sets[index - 1]?.reps : undefined"
        @update="(f, v) => onSetRowUpdate(set.id, index, f, v)"
        @delete="emit('deleteSet', set.id)"
      />
      <button
        type="button"
        class="mt-1 text-sm font-semibold text-primary"
        @click="emit('addSet')"
      >
        + Add Set
      </button>
    </template>
    </div>

    <ExerciseDetailSheet
      :open="detailOpen"
      :exercise="libraryEntry"
      @close="closeLibraryDetail"
    />
  </div>
</template>
