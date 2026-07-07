<script setup lang="ts">
import { computed, inject, onBeforeUnmount, ref, watch, nextTick } from 'vue'
import ExerciseDetailSheet from '@/components/library/ExerciseDetailSheet.vue'
import CardioDistanceInput from '@/components/workout/CardioDistanceInput.vue'
import CardioDurationInput from '@/components/workout/CardioDurationInput.vue'
import CircuitSetRow from '@/components/workout/CircuitSetRow.vue'
import SetRow from '@/components/workout/SetRow.vue'
import { settingsInjectionKey } from '@/composables/injectionKeys'
import type { Exercise, WorkoutLog } from '@/types/workout'
import {
  cardioExerciseComplete,
  cardioLoggedCalories,
  cardioLoggedDistance,
  cardioLoggedDurationMinutes,
  cardioTargetDistance,
  cardioTargetDurationMinutes,
  coreSetLogged,
  coreTargetTimeSeconds,
  formatDurationSecondsDisplay,
  parseCardioLoggedCalories,
} from '@/types/workout'
import { cardioExerciseSupportsDistance } from '@/utils/cardioDistance'
import { getLibraryExercise, resolveExerciseIsCardio, resolveExerciseIsCore, coreExerciseSupportsTimeLogging } from '@/utils/exerciseLibrary'
import { predictWorkoutGoals } from '@/utils/progressiveOverload'
import { haptic } from '@/utils/haptics'
import { distanceUnitLabel, formatDistanceWithUnit, normalizeDistanceInput } from '@/utils/distances'
import {
  estimateCardioExerciseCalories,
  formatWorkoutCalories,
} from '@/utils/workoutCalories'
import {
  formatWeightWithUnit,
  parseStoredLbs,
  storedLbsStringToDisplay,
} from '@/utils/units'

const props = defineProps<{
  exercise: Exercise
  workoutLog: WorkoutLog
  /** Exclude this day from history when predicting (current session). */
  sessionDateKey?: string
  /** Render inside a superset block (shared border, no outer card chrome). */
  embeddedInSuperset?: boolean
  supersetPosition?: 'first' | 'last'
  /** Next exercise in the log can be linked as a superset. */
  canLinkWithNext?: boolean
  /** Other standalone exercises available to link with. */
  linkPartnerOptions?: { id: string; name: string }[]
}>()

const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)
const distanceUnit = computed(() => settings.distanceUnit.value)
const bodyWeightLbs = computed(() => settings.bodyWeightLbs.value)

function formatStoredLbsForDisplay(s: string | undefined): string {
  if (!s?.trim()) return ''
  const lbs = parseStoredLbs(s)
  if (Number.isNaN(lbs)) return s
  return formatWeightWithUnit(lbs, weightUnit.value, 1)
}

/** Same wording as plan-assigned exercises: "Goal: N × reps" with optional "@ weight". */
const goalSummaryLine = computed(() => {
  if (props.exercise.isCircuit) return ''
  void weightUnit.value
  const n = props.exercise.sets.length
  const reps = (props.exercise.targetReps ?? '').trim()
  const w = (props.exercise.targetWeight ?? '').trim()
  const timeSec = coreTargetTimeSeconds(props.exercise)
  if (isCore.value) {
    const parts: string[] = []
    if (reps && !/\d+\s*sec|\d+\s*min/i.test(reps)) {
      parts.push(`${n} × ${reps} reps`)
    } else if (timeSec) {
      const sec = parseInt(timeSec, 10)
      parts.push(
        `${n} × ${!Number.isNaN(sec) && sec > 0 ? formatDurationSecondsDisplay(sec) : timeSec}`,
      )
    } else if (reps) {
      parts.push(`${n} × ${reps}`)
    } else {
      parts.push(`${n} sets`)
    }
    if (w) {
      const tail = ` @ ${formatStoredLbsForDisplay(props.exercise.targetWeight)}`
      return `Goal: ${parts.join(' · ')}${tail}`
    }
    return parts.length ? `Goal: ${parts.join(' · ')}` : ''
  }
  if (!reps && !w) return ''
  const mid = reps ? `${n} × ${reps}` : `${n} sets`
  const tail = w ? ` @ ${formatStoredLbsForDisplay(props.exercise.targetWeight)}` : ''
  return `Goal: ${mid}${tail}`
})

const emit = defineEmits<{
  addSet: []
  updateSet: [setId: string, field: 'reps' | 'weight' | 'durationSeconds', value: string]
  toggleCircuitSet: [setId: string]
  deleteSet: [setId: string]
  toggleWarmupSet: [setId: string]
  swapExercise: []
  deleteExercise: []
  updateGoals: [
    patch: Partial<{
      targetReps: string
      targetWeight: string
      targetDuration: string
      targetDistance: string
      targetTimeSeconds: string
    }>,
  ]
  updateNotes: [notes: string]
  updateLoggedCalories: [value: string]
  linkWithNext: []
  linkWithPartner: [partnerId: string]
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

const suggestion = ref<{
  suggestedReps: string
  suggestedWeight: number
  reason: string
} | null>(null)

const libraryEntry = computed(() => {
  const id = props.exercise.libraryId
  if (!id) return null
  return getLibraryExercise(id) ?? null
})

const isCardio = computed(
  () =>
    props.exercise.isCardio === true ||
    resolveExerciseIsCardio(libraryEntry.value ?? undefined, props.exercise.libraryId),
)

const isCore = computed(
  () =>
    resolveExerciseIsCore({
      libraryId: props.exercise.libraryId,
      isCore: props.exercise.isCore,
      isCardio: isCardio.value,
      isCircuit: props.exercise.isCircuit,
      name: props.exercise.name,
    }),
)

const showCoreTime = computed(() =>
  coreExerciseSupportsTimeLogging({
    libraryId: props.exercise.libraryId,
    isCore: props.exercise.isCore,
    isCardio: isCardio.value,
    isCircuit: props.exercise.isCircuit,
    name: props.exercise.name,
  }),
)

const coreTimeGoalSeconds = computed(() => coreTargetTimeSeconds(props.exercise))

/** Rep goal for set rows — omit time-only goals like "45 sec" when a Time column is shown. */
const setRepGoal = computed(() => {
  const g = (props.exercise.targetReps ?? '').trim()
  if (!showCoreTime.value) return g || undefined
  if (!g || /\d+\s*sec|\d+\s*min/i.test(g)) return undefined
  return g
})

const supportsDistance = computed(() => cardioExerciseSupportsDistance(props.exercise))

const cardioGoalLine = computed(() => {
  const parts: string[] = []
  const d = cardioTargetDurationMinutes(props.exercise)
  if (d) parts.push(`${d} min`)
  const dist = cardioTargetDistance(props.exercise)
  if (dist && supportsDistance.value) {
    parts.push(formatDistanceWithUnit(dist, distanceUnit.value))
  }
  return parts.length ? `Goal: ${parts.join(' · ')}` : ''
})

const cardioStatusLine = computed(() => {
  const parts: string[] = []
  const d = cardioLoggedDurationMinutes(props.exercise)
  if (d) parts.push(`${d} min`)
  const dist = cardioLoggedDistance(props.exercise)
  if (dist && supportsDistance.value) {
    parts.push(formatDistanceWithUnit(dist, distanceUnit.value))
  }
  if (parts.length) return parts.join(' · ')
  return supportsDistance.value ? 'Duration / distance' : 'Duration'
})

const cardioDuration = computed({
  get: () => cardioLoggedDurationMinutes(props.exercise),
  set: (value: string) => {
    const setId = props.exercise.sets[0]?.id
    if (!setId) return
    emit('updateSet', setId, 'reps', value)
  },
})

const cardioDistance = computed({
  get: () => cardioLoggedDistance(props.exercise),
  set: (value: string) => {
    const setId = props.exercise.sets[0]?.id
    if (!setId) return
    emit('updateSet', setId, 'weight', normalizeDistanceInput(value))
  },
})

const cardioCalories = computed({
  get: () => cardioLoggedCalories(props.exercise),
  set: (value: string) => {
    emit('updateLoggedCalories', value.replace(/[^\d]/g, ''))
  },
})

const hasCustomCardioCalories = computed(() => parseCardioLoggedCalories(props.exercise) != null)

const cardioCalorieEstimate = computed(() => {
  if (hasCustomCardioCalories.value) return null
  return estimateCardioExerciseCalories(props.exercise, bodyWeightLbs.value)
})

function onCardioCaloriesInput(event: Event) {
  const raw = (event.target as HTMLInputElement).value.replace(/[^\d]/g, '')
  cardioCalories.value = raw
}

function onSetRowUpdate(
  setId: string,
  index: number,
  field: 'reps' | 'weight' | 'durationSeconds',
  value: string,
) {
  emit('updateSet', setId, field, value)
}

function onCircuitSetUpdate(
  setId: string,
  field: 'weight' | 'durationSeconds',
  value: string,
) {
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
      props.sessionDateKey,
      weightUnit.value,
      isCardio.value,
      isCore.value,
    ] as const,
  () => {
    if (props.exercise.isCircuit || isCardio.value || isCore.value) {
      suggestion.value = null
      return
    }
    const reps = (props.exercise.targetReps ?? '').trim()
    const tw = (props.exercise.targetWeight ?? '').trim()
    const storedW = tw ? parseStoredLbs(tw) : NaN
    const pred = predictWorkoutGoals(props.exercise.name, props.workoutLog, {
      currentTargetReps: reps || undefined,
      excludeDateKey: props.sessionDateKey,
      displayUnit: weightUnit.value,
      lockRepGoal: !!reps,
      ignoreStoredGoalWeight: true,
    })
    if (!pred.hasHistory) {
      suggestion.value =
        Number.isFinite(storedW) && storedW > 0
          ? {
              suggestedReps: reps || pred.suggestedReps,
              suggestedWeight: storedW,
              reason: pred.reason,
            }
          : null
      return
    }
    suggestion.value = {
      suggestedReps: pred.suggestedReps,
      suggestedWeight: pred.suggestedWeightLbs,
      reason: pred.reason,
    }
  },
  { deep: true, immediate: true },
)

const completedSets = computed(() => {
  if (isCardio.value) return cardioExerciseComplete(props.exercise) ? 1 : 0
  if (isCore.value) {
    return props.exercise.sets.filter((s) => coreSetLogged(s)).length
  }
  return props.exercise.sets.filter((s) =>
    props.exercise.isCircuit ? s.checked : s.reps !== '' && s.weight !== '',
  ).length
})

const allDone = computed(() => {
  if (isCardio.value) return cardioExerciseComplete(props.exercise)
  return completedSets.value === props.exercise.sets.length && props.exercise.sets.length > 0
})

watch(allDone, (done, wasDone) => {
  if (done && !wasDone) haptic('celebrate')
})

const detailOpen = ref(false)
const goalsEditorOpen = ref(false)

function openLibraryDetail() {
  if (libraryEntry.value) detailOpen.value = true
}

function closeLibraryDetail() {
  detailOpen.value = false
}

function focusSetWeightInput(setId: string) {
  void nextTick(() => {
    const el = document.querySelector(
      `[data-set-weight="${setId}"]`,
    ) as HTMLInputElement | null
    el?.focus()
    el?.select()
  })
}
const linkPickerOpen = ref(false)

watch(goalsEditorOpen, (open) => {
  if (!open) linkPickerOpen.value = false
})

function pickLinkPartner(partnerId: string) {
  linkPickerOpen.value = false
  emit('linkWithPartner', partnerId)
}
</script>

<template>
  <div>
  <div
    class="transition-colors duration-200"
    :class="
      embeddedInSuperset
        ? [
            'border-x-2 border-primary/45 bg-card p-3',
            supersetPosition === 'last' ? 'rounded-b-xl border-b-2' : 'mb-0 border-b-0',
          ]
        : [
            'mb-3.5 rounded-xl border border-border bg-card p-3.5',
            allDone ? 'border-success' : '',
          ]
    "
  >
    <div class="mb-2 flex justify-between gap-2">
      <div class="min-w-0 flex-1">
        <div class="flex items-center gap-2">
          <h4
            :class="
              embeddedInSuperset
                ? 'text-base font-bold text-foreground'
                : 'exercise-reorder-handle cursor-grab select-none text-base font-bold text-foreground active:cursor-grabbing touch-manipulation'
            "
            :title="embeddedInSuperset ? undefined : 'Hold, then drag to reorder'"
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
          v-if="isCardio"
          class="mt-1.5 flex min-w-0 flex-wrap items-center gap-x-2 gap-y-1"
        >
          <p v-if="cardioGoalLine" class="min-w-0 text-[11px] leading-snug text-muted">
            {{ cardioGoalLine }}
          </p>
          <span v-else class="text-[11px] text-muted">No duration goal</span>
          <button
            type="button"
            class="shrink-0 text-muted hover:text-primary"
            :aria-expanded="goalsEditorOpen"
            :aria-controls="`exercise-goals-editor-${exercise.id}`"
            aria-label="Edit duration goal"
            @click="goalsEditorOpen = !goalsEditorOpen"
          >
            <i class="fa-solid fa-pen text-[10px]" aria-hidden="true" />
          </button>
        </div>
    <div
      v-else-if="!exercise.isCircuit"
      class="mt-1.5 flex min-w-0 flex-wrap items-center gap-x-2 gap-y-1"
    >
      <p v-if="goalSummaryLine" class="min-w-0 text-[11px] leading-snug text-muted">
        {{ goalSummaryLine }}
      </p>
      <span v-else-if="isCore && showCoreTime" class="text-[11px] text-muted">Log reps and/or time per set</span>
      <span v-else-if="isCore" class="text-[11px] text-muted">Log reps per set</span>
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
          :class="allDone ? 'text-success-text' : 'text-muted'"
        >
          {{
            isCardio
              ? allDone
                ? 'Complete'
                : cardioStatusLine
              : allDone
                ? 'Complete'
                : `${completedSets}/${exercise.sets.length} sets`
          }}
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
        {{ isCardio ? 'Activity' : 'Sets' }}
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
      v-if="goalsEditorOpen && isCardio"
      :id="`exercise-goals-editor-${exercise.id}`"
      class="mb-2 grid gap-2"
      :class="supportsDistance ? 'grid-cols-2' : 'grid-cols-1'"
    >
      <div>
        <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal duration (min)</label>
        <input
          :value="exercise.targetDuration ?? ''"
          type="text"
          inputmode="numeric"
          class="mt-0.5 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-[13px] text-foreground outline-none focus:border-primary"
          placeholder="e.g. 30"
          @input="emit('updateGoals', { targetDuration: ($event.target as HTMLInputElement).value })"
        />
      </div>
      <div v-if="supportsDistance">
        <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">
          Goal distance ({{ distanceUnitLabel(distanceUnit) }})
        </label>
        <input
          :value="exercise.targetDistance ?? ''"
          type="text"
          inputmode="decimal"
          class="mt-0.5 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-[13px] text-foreground outline-none focus:border-primary"
          placeholder="Optional"
          @input="
            emit('updateGoals', {
              targetDistance: normalizeDistanceInput(($event.target as HTMLInputElement).value),
            })
          "
        />
      </div>
    </div>

    <div
      v-if="isCardio"
      class="mb-2"
      :class="supportsDistance ? 'grid grid-cols-2 gap-2' : ''"
    >
      <div>
        <label class="mb-1 block text-[10px] font-bold uppercase tracking-wide text-muted">Duration (minutes)</label>
        <CardioDurationInput
          v-model="cardioDuration"
          :target-duration="cardioTargetDurationMinutes(exercise)"
        />
      </div>
      <div v-if="supportsDistance">
        <label class="mb-1 block text-[10px] font-bold uppercase tracking-wide text-muted">
          Distance ({{ distanceUnitLabel(distanceUnit) }})
        </label>
        <CardioDistanceInput
          v-model="cardioDistance"
          :distance-unit="distanceUnit"
          :target-distance="cardioTargetDistance(exercise)"
        />
      </div>
    </div>

    <div v-if="isCardio" class="mb-2">
      <label class="mb-1 block text-[10px] font-bold uppercase tracking-wide text-muted">
        Calories (optional)
      </label>
      <input
        :value="cardioCalories"
        type="text"
        inputmode="numeric"
        pattern="[0-9]*"
        placeholder="From watch or machine"
        class="w-full rounded-lg border border-border bg-card-inner px-3 py-2 text-sm font-semibold text-foreground placeholder:font-normal placeholder:text-muted focus:border-primary focus:outline-none"
        @input="onCardioCaloriesInput"
      />
      <p
        v-if="hasCustomCardioCalories"
        class="mt-1 text-[11px] text-muted"
      >
        Using your logged calories in the workout total.
      </p>
      <p
        v-else-if="cardioCalorieEstimate != null"
        class="mt-1 text-[11px] text-muted"
      >
        {{ formatWorkoutCalories(cardioCalorieEstimate) }} estimated
      </p>
      <p
        v-else-if="cardioLoggedDurationMinutes(exercise) || cardioTargetDurationMinutes(exercise)"
        class="mt-1 text-[11px] text-muted"
      >
        Add body weight in Settings to see an estimate.
      </p>
    </div>

    <div
      v-if="goalsEditorOpen && !exercise.isCircuit && !isCardio"
      :id="`exercise-goals-editor-${exercise.id}`"
      class="mb-2 rounded-lg border border-border bg-card-inner/50 p-2.5"
    >
      <div class="grid gap-2" :class="showCoreTime ? 'grid-cols-3' : 'grid-cols-2'">
        <div>
          <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal reps</label>
          <input
            :value="exercise.targetReps ?? ''"
            type="text"
            class="mt-0.5 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-[13px] text-foreground outline-none focus:border-primary"
            :placeholder="isCore ? 'e.g. 15–20' : 'e.g. 8–12'"
            inputmode="text"
            @input="emit('updateGoals', { targetReps: ($event.target as HTMLInputElement).value })"
          />
        </div>
        <div v-if="showCoreTime">
          <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal time (sec)</label>
          <input
            :value="exercise.targetTimeSeconds ?? coreTimeGoalSeconds"
            type="text"
            inputmode="numeric"
            class="mt-0.5 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-[13px] text-foreground outline-none focus:border-primary"
            placeholder="e.g. 60"
            @input="emit('updateGoals', { targetTimeSeconds: ($event.target as HTMLInputElement).value })"
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
        v-if="!embeddedInSuperset && (canLinkWithNext || (linkPartnerOptions && linkPartnerOptions.length > 0))"
        class="mt-3 flex flex-wrap items-center gap-2 border-t border-border/60 pt-2.5"
      >
        <span class="text-[10px] font-bold uppercase tracking-wide text-muted">Superset</span>
        <button
          v-if="canLinkWithNext"
          type="button"
          class="rounded-md border border-primary/40 bg-primary/10 px-2 py-1 text-[11px] font-semibold text-primary hover:bg-primary/20"
          @click="emit('linkWithNext')"
        >
          Link with next
        </button>
        <div v-if="linkPartnerOptions && linkPartnerOptions.length > 0" class="relative">
          <button
            type="button"
            class="rounded-md border border-border bg-card-inner px-2 py-1 text-[11px] font-semibold text-muted hover:text-primary"
            :aria-expanded="linkPickerOpen"
            @click="linkPickerOpen = !linkPickerOpen"
          >
            Link with…
          </button>
          <div
            v-if="linkPickerOpen"
            class="absolute left-0 top-full z-20 mt-1 min-w-[12rem] rounded-lg border border-border bg-card p-1 shadow-lg"
          >
            <button
              v-for="opt in linkPartnerOptions"
              :key="opt.id"
              type="button"
              class="block w-full rounded-md px-2 py-1.5 text-left text-xs font-semibold text-foreground hover:bg-card-inner"
              @click="pickLinkPartner(opt.id)"
            >
              {{ opt.name }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <div
      v-if="suggestion && !exercise.isCircuit && !isCardio && suggestion.reason !== 'No history yet'"
      class="mb-2.5 rounded-lg border border-success bg-success-soft p-2"
    >
      <div class="text-[13px] font-bold text-success-text">
        Predicted goal:
        {{ exercise.sets.length }} × {{ suggestion.suggestedReps }}
        @ {{ formatWeightWithUnit(suggestion.suggestedWeight, weightUnit, 1) }}
      </div>
      <div class="mt-0.5 text-[11px] text-success-text/80">{{ suggestion.reason }}</div>
    </div>

    <template v-if="exercise.isCircuit">
      <CircuitSetRow
        v-for="(set, index) in exercise.sets"
        :key="set.id"
        :set="set"
        :index="index"
        :exercise="exercise"
        :weight-unit="weightUnit"
        @toggle="emit('toggleCircuitSet', set.id)"
        @update="(field, value) => onCircuitSetUpdate(set.id, field, value)"
      />
    </template>

    <template v-else-if="!isCardio">
      <div class="mb-1 flex min-w-0">
        <span class="w-14 shrink-0" />
        <span class="min-w-0 flex-1 basis-0 text-center text-[10px] font-bold uppercase text-muted">Weight</span>
        <span class="min-w-0 flex-1 basis-0 text-center text-[10px] font-bold uppercase text-muted">Reps</span>
        <span
          v-if="showCoreTime"
          class="min-w-0 flex-1 basis-0 text-center text-[10px] font-bold uppercase text-muted"
        >Time</span>
        <span class="w-8 shrink-0" />
      </div>
      <SetRow
        v-for="(set, index) in exercise.sets"
        :key="set.id"
        :set="set"
        :index="index"
        :next-set-id="index < exercise.sets.length - 1 ? exercise.sets[index + 1]?.id : undefined"
        :target-reps="setRepGoal"
        :target-weight-stored="index === 0 ? exercise.targetWeight : undefined"
        :prior-set-weight-stored="index > 0 ? exercise.sets[index - 1]?.weight : undefined"
        :prior-set-reps="index > 0 ? exercise.sets[index - 1]?.reps : undefined"
        :show-duration="showCoreTime"
        :target-duration-seconds="coreTimeGoalSeconds || undefined"
        :prior-set-duration-seconds="index > 0 ? exercise.sets[index - 1]?.durationSeconds : undefined"
        @update="(f, v) => onSetRowUpdate(set.id, index, f, v)"
        @advance-to-next-weight="
          index < exercise.sets.length - 1 && exercise.sets[index + 1]
            ? focusSetWeightInput(exercise.sets[index + 1]!.id)
            : undefined
        "
        @toggle-warmup="emit('toggleWarmupSet', set.id)"
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
  </div>
</template>
