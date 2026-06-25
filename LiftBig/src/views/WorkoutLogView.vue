<script setup lang="ts">
import { computed, inject, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import Sortable from 'sortablejs'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import SettingsSheet from '@/components/layout/SettingsSheet.vue'
import LibraryPickerModal from '@/components/library/LibraryPickerModal.vue'
import ExerciseNameSuggestList from '@/components/library/ExerciseNameSuggestList.vue'
import ExerciseCard from '@/components/workout/ExerciseCard.vue'
import SwapExerciseModal from '@/components/workout/SwapExerciseModal.vue'
import RestTimer from '@/components/workout/RestTimer.vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import { useExerciseNameSuggest } from '@/composables/useExerciseNameSuggest'
import { provideWorkoutSetLoggingFocus } from '@/composables/useWorkoutSetLoggingFocus'
import type { Exercise } from '@/types/workout'
import type { LibraryExercise } from '@/utils/exerciseLibrary'
import { getLibraryExercise, libraryExerciseIsCardio } from '@/utils/exerciseLibrary'
import {
  applyBodyWeightDefaultsToExercise,
  applyBodyWeightDefaultsToExercises,
  applyBodyWeightOnExerciseSwap,
  defaultWeightForNewSet,
} from '@/utils/bodyWeightDefaults'
import { formatDisplayDate } from '@/utils/dateKey'
import {
  isFavoritesLibrarySearchQuery,
  resolveManualExerciseInput,
} from '@/utils/exerciseLibrary'
import { applyPredictedGoalsToExercises } from '@/utils/progressiveOverload'
import { displayInputToStoredLbsString, storedLbsStringToDisplay } from '@/utils/units'
import {
  applyLiftBigBackupToStorage,
  collectLiftBigBackupPayload,
  downloadLiftBigBackupJson,
  parseLiftBigBackupJson,
} from '@/utils/liftbigBackup'
import { planDurationAssumptionsFromSeconds, formatPlanDurationEstimate } from '@/utils/planDuration'
import {
  estimateWorkoutCalories,
  formatWorkoutCalories,
} from '@/utils/workoutCalories'

const route = useRoute()
const router = useRouter()
const workouts = inject(workoutsInjectionKey)!
const settings = inject(settingsInjectionKey)!
const setLoggingFocusActive = provideWorkoutSetLoggingFocus()

const dateKey = computed(() => {
  const d = route.params.date
  const s = Array.isArray(d) ? d[0] : d
  return s ?? ''
})

const exercises = ref<Exercise[]>([])
/** Draft for the workout-level notes box; debounced into storage (per day). */
const workoutNotesDraft = ref('')
let workoutNotesBoundDate = ''
let workoutNotesTimer: ReturnType<typeof setTimeout> | null = null
const WORKOUT_NOTES_DEBOUNCE_MS = 550

const inputName = ref('')
const libraryOpen = ref(false)
const swapModalExerciseId = ref<string | null>(null)
const {
  show: showExerciseSuggest,
  matches: exerciseSuggestMatches,
  onFocus: onExerciseSuggestFocus,
  hideSoon: hideExerciseSuggestSoon,
  dismiss: dismissExerciseSuggest,
} = useExerciseNameSuggest(inputName)
const menuOpen = ref(false)
const settingsOpen = ref(false)
/** Optional targets applied to the next manually / library-added exercise (stored lb string for weight). */
const goalRepsDraft = ref('')
const goalWeightStoredLbs = ref('')

const weightUnit = computed(() => settings.weightUnit.value)
const planName = computed(() => workouts.getPlanName(dateKey.value))
const planFolderName = computed(() => workouts.getPlanFolderName(dateKey.value))
const planCoachingNotes = computed(() => workouts.getPlanNotes(dateKey.value)?.trim() || undefined)

function optionalGoalsFromDock(): Partial<Pick<Exercise, 'targetReps' | 'targetWeight'>> {
  const out: Partial<Pick<Exercise, 'targetReps' | 'targetWeight'>> = {}
  const reps = goalRepsDraft.value.trim()
  const w = goalWeightStoredLbs.value.trim()
  if (reps) out.targetReps = reps
  if (w) out.targetWeight = w
  return out
}

function flushWorkoutNotesForDate(dateKeyToSave: string) {
  if (workoutNotesTimer) {
    clearTimeout(workoutNotesTimer)
    workoutNotesTimer = null
  }
  if (!dateKeyToSave) return
  workouts.setDayNotes(dateKeyToSave, workoutNotesDraft.value)
}

function scheduleWorkoutNotesPersist() {
  const k = dateKey.value
  if (!k) return
  workoutNotesBoundDate = k
  if (workoutNotesTimer) clearTimeout(workoutNotesTimer)
  workoutNotesTimer = setTimeout(() => {
    workoutNotesTimer = null
    workouts.setDayNotes(k, workoutNotesDraft.value)
  }, WORKOUT_NOTES_DEBOUNCE_MS)
}

function normalizeExerciseForLog(ex: Exercise): Exercise {
  const lib = ex.libraryId ? getLibraryExercise(ex.libraryId) : undefined
  const isCardio = ex.isCardio === true || libraryExerciseIsCardio(lib)
  if (!isCardio) return ex
  const next: Exercise = { ...ex, isCardio: true }
  if (next.sets.length === 0) {
    next.sets = [{ id: newId(), reps: '', weight: '' }]
  }
  return next
}

function loadDay() {
  const k = dateKey.value
  if (!k) return
  if (workoutNotesBoundDate && workoutNotesBoundDate !== k) {
    flushWorkoutNotesForDate(workoutNotesBoundDate)
  }
  const loaded = (JSON.parse(JSON.stringify(workouts.getDay(k))) as Exercise[]).map(
    normalizeExerciseForLog,
  )
  applyPredictedGoalsToExercises(loaded, workouts.log.value, k)
  exercises.value = applyBodyWeightDefaultsToExercises(loaded, settings.bodyWeightLbs.value)
  workoutNotesDraft.value = workouts.getDayNotesForDate(k)
  workoutNotesBoundDate = k
}

watch(dateKey, loadDay, { immediate: true })

watch(
  () => settings.bodyWeightLbs.value,
  (lbs) => {
    if (lbs <= 0) return
    exercises.value = applyBodyWeightDefaultsToExercises(exercises.value, lbs)
  },
)

watch(
  exercises,
  (list) => {
    const k = dateKey.value
    if (!k) return
    workouts.setDay(k, JSON.parse(JSON.stringify(list)) as Exercise[])
  },
  { deep: true },
)

const workoutLogPlain = computed(() => workouts.log.value)

const calorieEstimate = computed(() => {
  const assumptions = planDurationAssumptionsFromSeconds(
    settings.averageLiftSeconds.value,
    settings.averageRestSeconds.value,
  )
  return estimateWorkoutCalories(
    exercises.value,
    settings.bodyWeightLbs.value,
    assumptions,
  )
})

const hasBodyWeightForCalories = computed(() => settings.bodyWeightLbs.value > 0)

const exerciseListEl = ref<HTMLElement | null>(null)
let exerciseSortable: Sortable | null = null

function destroyExerciseSortable() {
  exerciseSortable?.destroy()
  exerciseSortable = null
}

function bindExerciseSortable() {
  destroyExerciseSortable()
  const el = exerciseListEl.value
  if (!el || exercises.value.length < 2) return

  exerciseSortable = Sortable.create(el, {
    animation: 180,
    handle: '.exercise-reorder-handle',
    delay: 500,
    delayOnTouchOnly: true,
    touchStartThreshold: 5,
    ghostClass: 'exercise-sortable-ghost',
    chosenClass: 'exercise-sortable-chosen',
    onEnd(evt: Sortable.SortableEvent) {
      const oi = evt.oldIndex
      const ni = evt.newIndex
      if (oi == null || ni == null || oi === ni) return
      const next = [...exercises.value]
      const [moved] = next.splice(oi, 1)
      if (!moved) return
      next.splice(ni, 0, moved)
      exercises.value = next
    },
  })
}

onMounted(() => {
  nextTick(bindExerciseSortable)
})

watch(dateKey, () => {
  nextTick(bindExerciseSortable)
})

watch(
  () => exercises.value.length,
  () => {
    nextTick(bindExerciseSortable)
  },
)

onBeforeUnmount(() => {
  flushWorkoutNotesForDate(workoutNotesBoundDate)
  destroyExerciseSortable()
})

function newId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 11)}`
}

function appendExercise(ex: Exercise) {
  exercises.value = [
    ...exercises.value,
    applyBodyWeightDefaultsToExercise(ex, settings.bodyWeightLbs.value),
  ]
}

function addExercise() {
  const trimmed = inputName.value.trim()
  if (!trimmed) {
    window.alert('Please enter an exercise name.')
    return
  }
  if (isFavoritesLibrarySearchQuery(trimmed)) return
  const resolved = resolveManualExerciseInput(trimmed)
  if (resolved) {
    addFromLibrary(resolved)
    inputName.value = ''
    return
  }
  exercises.value = [
    ...exercises.value,
    {
      id: newId(),
      name: trimmed,
      ...optionalGoalsFromDock(),
      sets: [{ id: newId(), reps: '', weight: '' }],
    },
  ]
  inputName.value = ''
}

function addFromLibrary(ex: LibraryExercise) {
  if (libraryExerciseIsCardio(ex)) {
    appendExercise({
      id: newId(),
      name: ex.name,
      libraryId: ex.id,
      isCardio: true,
      sets: [{ id: newId(), reps: '', weight: '' }],
    })
    return
  }
  appendExercise({
    id: newId(),
    name: ex.name,
    libraryId: ex.id,
    ...optionalGoalsFromDock(),
    sets: [{ id: newId(), reps: '', weight: '' }],
  })
}

function addFromInlineLibrary(ex: LibraryExercise) {
  addFromLibrary(ex)
  inputName.value = ''
  dismissExerciseSuggest()
}

function addSet(exerciseId: string) {
  const bodyLbs = settings.bodyWeightLbs.value
  exercises.value = exercises.value.map((ex) => {
    if (ex.id !== exerciseId) return ex
    const weight = defaultWeightForNewSet(ex, bodyLbs)
    return {
      ...ex,
      sets: [...ex.sets, { id: newId(), reps: '', weight }],
    }
  })
}

function updateSet(exerciseId: string, setId: string, field: 'reps' | 'weight', value: string) {
  exercises.value = exercises.value.map((ex) => {
    if (ex.id !== exerciseId) return ex
    return {
      ...ex,
      sets: ex.sets.map((s) => (s.id === setId ? { ...s, [field]: value } : s)),
    }
  })
}

function toggleCircuitSet(exerciseId: string, setId: string) {
  exercises.value = exercises.value.map((ex) => {
    if (ex.id !== exerciseId) return ex
    return {
      ...ex,
      sets: ex.sets.map((s) => (s.id === setId ? { ...s, checked: !s.checked } : s)),
    }
  })
}

function toggleWarmupSet(exerciseId: string, setId: string) {
  exercises.value = exercises.value.map((ex) => {
    if (ex.id !== exerciseId) return ex
    return {
      ...ex,
      sets: ex.sets.map((s) => {
        if (s.id !== setId) return s
        const nextWarmup = !s.isWarmup
        return nextWarmup ? { ...s, isWarmup: true } : { ...s, isWarmup: undefined }
      }),
    }
  })
}

function deleteSet(exerciseId: string, setId: string) {
  exercises.value = exercises.value.map((ex) =>
    ex.id !== exerciseId ? ex : { ...ex, sets: ex.sets.filter((s) => s.id !== setId) },
  )
}

function deleteExercise(exerciseId: string) {
  exercises.value = exercises.value.filter((ex) => ex.id !== exerciseId)
}

function updateExerciseGoals(
  exerciseId: string,
  patch: Partial<{ targetReps: string; targetWeight: string; targetDuration: string; targetDistance: string }>,
) {
  exercises.value = exercises.value.map((ex) => {
    if (ex.id !== exerciseId) return ex
    const next: Exercise = { ...ex }
    if (patch.targetDuration !== undefined) {
      const t = patch.targetDuration.trim()
      next.targetDuration = t ? t : undefined
    }
    if (patch.targetDistance !== undefined) {
      const t = patch.targetDistance.trim()
      next.targetDistance = t ? t : undefined
    }
    if (patch.targetReps !== undefined) {
      const t = patch.targetReps.trim()
      next.targetReps = t ? t : undefined
    }
    if (patch.targetWeight !== undefined) {
      const t = patch.targetWeight.trim()
      next.targetWeight = t
        ? displayInputToStoredLbsString(t, settings.weightUnit.value)
        : undefined
    }
    return next
  })
}

function updateExerciseNotes(exerciseId: string, notes: string) {
  exercises.value = exercises.value.map((ex) => {
    if (ex.id !== exerciseId) return ex
    const next: Exercise = { ...ex }
    if (!notes) delete next.notes
    else next.notes = notes
    return next
  })
}

const swapModalExercise = computed(() => {
  const id = swapModalExerciseId.value
  if (!id) return null
  return exercises.value.find((ex) => ex.id === id) ?? null
})

function openSwapExercise(exerciseId: string) {
  swapModalExerciseId.value = exerciseId
}

function applySwapExerciseReplacement(lib: LibraryExercise) {
  const id = swapModalExerciseId.value
  if (!id) return
  const isCardio = libraryExerciseIsCardio(lib)
  exercises.value = exercises.value.map((ex) => {
    if (ex.id !== id) return ex
    const swapped: Exercise = {
      ...ex,
      name: lib.name,
      libraryId: lib.id,
      isCardio: isCardio ? true : undefined,
      targetDuration: isCardio ? ex.targetDuration : undefined,
      targetDistance: isCardio ? ex.targetDistance : undefined,
      targetReps: isCardio ? undefined : ex.targetReps,
      targetWeight: isCardio ? undefined : ex.targetWeight,
      sets: isCardio
        ? [{ id: ex.sets[0]?.id ?? newId(), reps: ex.sets[0]?.reps ?? '', weight: '' }]
        : ex.sets,
    }
    return applyBodyWeightOnExerciseSwap(swapped, settings.bodyWeightLbs.value)
  })
  swapModalExerciseId.value = null
}

function finish() {
  const total = exercises.value.reduce((acc, ex) => acc + ex.sets.length, 0)
  const ok = window.confirm(
    `Save and finish?\n\n${exercises.value.length} exercise(s), ${total} sets for ${formatDisplayDate(dateKey.value)}.`,
  )
  if (!ok) return
  workouts.flush()
  router.push('/')
}

function closeMenu() {
  menuOpen.value = false
}

function openSettingsFromMenu() {
  settingsOpen.value = true
  menuOpen.value = false
}

function onExportBackup() {
  workouts.flush()
  downloadLiftBigBackupJson(collectLiftBigBackupPayload())
}

async function onImportBackup(file: File) {
  let text: string
  try {
    text = await file.text()
  } catch {
    window.alert('Could not read that file.')
    return
  }

  const parsed = parseLiftBigBackupJson(text)
  if (!parsed.ok) {
    window.alert(parsed.error)
    return
  }

  const ok = window.confirm(
    'Replace all LiftBig data on this device with this backup?\n\nCurrent workouts, plans, and settings will be overwritten.',
  )
  if (!ok) return

  workouts.flush()
  applyLiftBigBackupToStorage(parsed.data)
  settingsOpen.value = false
  window.location.reload()
}

const sheetTheme = computed(() => settings.theme.value)
const sheetWeightUnit = computed(() => settings.weightUnit.value)
const sheetDistanceUnit = computed(() => settings.distanceUnit.value)
const sheetAverageRestSeconds = computed(() => settings.averageRestSeconds.value)
const sheetAverageLiftSeconds = computed(() => settings.averageLiftSeconds.value)
const sheetBodyWeightLbs = computed(() => settings.bodyWeightLbs.value)
</script>

<template>
  <div class="min-h-full bg-background pb-8">
    <Teleport to="body">
      <div
        v-if="menuOpen"
        class="fixed inset-0 z-20 bg-black/50"
        aria-hidden="true"
        @click="closeMenu"
      />
    </Teleport>

    <header
      class="sticky top-0 z-30 flex items-start justify-between gap-2 border-b border-border bg-background/95 px-4 pb-3 pt-4 backdrop-blur-sm"
    >
      <div class="min-w-0">
        <RouterLink
          to="/"
          class="mb-2 inline-flex items-center gap-2 text-xs font-bold text-muted hover:text-primary"
        >
          <i class="fa-solid fa-house text-sm" aria-hidden="true" />
          Home
        </RouterLink>
        <h1 class="text-3xl font-black tracking-[0.2em] text-primary">LIFTBIG</h1>
        <p class="text-xs text-muted">{{ formatDisplayDate(dateKey) }}</p>
      </div>

      <div class="flex items-start gap-2">
        <div class="pt-1">
          <RestTimer :show-floating="false" compact />
        </div>

        <div class="flex flex-col items-end gap-2">
          <div class="relative">
            <button
              type="button"
              class="flex h-9 w-9 items-center justify-center rounded-lg border border-border bg-card text-foreground"
              :aria-expanded="menuOpen"
              aria-controls="workout-menu"
              aria-label="Open menu"
              @click="menuOpen = !menuOpen"
            >
              <i class="fa-solid fa-bars text-sm" aria-hidden="true" />
            </button>
            <div
              v-if="menuOpen"
              id="workout-menu"
              class="absolute right-0 z-50 mt-2 w-[13rem] rounded-2xl border border-border bg-card-inner py-1 shadow-xl"
              role="menu"
              @click.stop
            >
              <RouterLink v-slot="{ navigate, isActive }" to="/plates" custom>
                <button
                  type="button"
                  role="menuitem"
                  class="flex w-full items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
                  :class="{ '!text-primary': isActive }"
                  @click="closeMenu(); navigate($event)"
                >
                  <i class="fa-solid fa-weight-hanging w-5 text-center text-base text-muted" aria-hidden="true" />
                  Plates
                </button>
              </RouterLink>
              <RouterLink v-slot="{ navigate, isActive }" to="/one-rep-max" custom>
                <button
                  type="button"
                  role="menuitem"
                  class="flex w-full items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
                  :class="{ '!text-primary': isActive }"
                  @click="closeMenu(); navigate($event)"
                >
                  <i class="fa-solid fa-calculator w-5 text-center text-base text-muted" aria-hidden="true" />
                  1RM
                </button>
              </RouterLink>
              <button
                type="button"
                role="menuitem"
                class="flex w-full items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
                @click="openSettingsFromMenu"
              >
                <i class="fa-solid fa-gear w-5 text-center text-base text-muted" aria-hidden="true" />
                Settings
              </button>
            </div>
          </div>
          <RouterLink
            to="/library"
            class="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-border text-muted hover:border-primary hover:text-primary"
            aria-label="Open exercise library"
          >
            <i class="fa-solid fa-book text-sm" aria-hidden="true" />
          </RouterLink>
        </div>
      </div>
    </header>

    <div class="px-4 pb-6 pt-4">
      <section
        v-if="planCoachingNotes"
        class="mb-3.5 rounded-xl border border-primary/35 bg-card-inner/70 p-3.5"
      >
        <div class="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
          <h2 class="text-sm font-bold uppercase tracking-wide text-primary">Today's plan</h2>
          <p v-if="planName" class="text-sm font-extrabold text-foreground">{{ planName }}</p>
          <p v-if="planFolderName" class="text-xs text-muted">({{ planFolderName }})</p>
        </div>
        <p class="mt-2 whitespace-pre-line text-sm leading-relaxed text-foreground">
          {{ planCoachingNotes }}
        </p>
      </section>
      <section class="mb-3.5 rounded-xl border border-border bg-card p-3.5">
        <h2 class="text-sm font-bold uppercase tracking-wide text-muted">Notes</h2>
        <textarea
          v-model="workoutNotesDraft"
          class="mt-2 min-h-24 w-full resize-y rounded-lg border border-border bg-card-inner px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
          placeholder="Add notes for this workout (saved automatically)…"
          @input="scheduleWorkoutNotesPersist"
          @blur="flushWorkoutNotesForDate(workoutNotesBoundDate)"
        />
      </section>

      <div v-if="exercises.length === 0" class="py-16 text-center">
        <p class="text-lg font-bold text-foreground">No exercises yet.</p>
        <p class="mt-2 text-sm text-muted">Add one below or assign a plan from Home.</p>
      </div>

      <div v-if="exercises.length > 0" ref="exerciseListEl">
        <ExerciseCard
          v-for="ex in exercises"
          :key="ex.id"
          :exercise="ex"
          :workout-log="workoutLogPlain"
          :session-date-key="dateKey"
          @add-set="addSet(ex.id)"
          @update-set="(setId, field, v) => updateSet(ex.id, setId, field, v)"
          @toggle-circuit-set="(setId) => toggleCircuitSet(ex.id, setId)"
          @toggle-warmup-set="(setId) => toggleWarmupSet(ex.id, setId)"
          @delete-set="(setId) => deleteSet(ex.id, setId)"
          @swap-exercise="openSwapExercise(ex.id)"
          @delete-exercise="deleteExercise(ex.id)"
          @update-goals="(patch) => updateExerciseGoals(ex.id, patch)"
          @update-notes="(n) => updateExerciseNotes(ex.id, n)"
        />
      </div>

      <section
        v-show="!setLoggingFocusActive"
        class="mt-3.5 rounded-xl border border-border bg-card p-3.5"
      >
        <h2 class="mb-2.5 text-sm font-bold uppercase tracking-wide text-muted">Add exercise</h2>
        <div class="flex gap-2">
          <div class="flex min-w-0 flex-1 flex-col gap-2">
            <div class="relative min-w-0">
              <input
                v-model="inputName"
                type="text"
                data-touch-input
                class="min-w-0 w-full rounded-lg border border-border bg-card-inner px-3 py-2.5 text-base text-foreground outline-none focus:border-primary"
                placeholder="Add exercise manually..."
                @focus="onExerciseSuggestFocus()"
                @blur="hideExerciseSuggestSoon()"
                @keydown.enter="addExercise"
              />
              <ExerciseNameSuggestList
                :show="showExerciseSuggest"
                :matches="exerciseSuggestMatches"
                @pick="addFromInlineLibrary"
              />
            </div>
            <div class="grid min-w-0 grid-cols-2 gap-2">
              <div class="min-w-0">
                <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal reps</label>
                <input
                  v-model="goalRepsDraft"
                  type="text"
                  data-touch-input
                  class="mt-0.5 w-full min-w-0 rounded-lg border border-border bg-card-inner px-2 py-1.5 text-base text-foreground outline-none focus:border-primary"
                  placeholder="e.g. 8–12"
                  inputmode="text"
                />
              </div>
              <div class="min-w-0">
                <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal weight</label>
                <input
                  :value="storedLbsStringToDisplay(goalWeightStoredLbs, weightUnit)"
                  type="text"
                  inputmode="decimal"
                  data-touch-input
                  class="mt-0.5 w-full min-w-0 rounded-lg border border-border bg-card-inner px-2 py-1.5 text-base text-foreground outline-none focus:border-primary"
                  :placeholder="weightUnit === 'lb' ? 'lb' : 'kg'"
                  @input="
                    goalWeightStoredLbs = displayInputToStoredLbsString(
                      ($event.target as HTMLInputElement).value,
                      weightUnit,
                    )
                  "
                />
              </div>
            </div>
          </div>
          <div class="flex shrink-0 flex-col gap-2 self-start">
            <button
              type="button"
              class="w-full shrink-0 rounded-lg bg-blue px-5 py-2.5 font-bold text-foreground"
              @click="addExercise"
            >
              Add
            </button>
            <button
              type="button"
              class="w-full shrink-0 rounded-lg border border-primary/50 bg-card-inner px-5 py-2.5 font-bold text-primary"
              @click="libraryOpen = true"
            >
              Library
            </button>
          </div>
        </div>
      </section>

      <section
        v-if="exercises.length > 0"
        class="mt-3.5 rounded-xl border border-border bg-card p-3.5"
      >
        <div class="flex items-start gap-3">
          <i class="fa-solid fa-fire-flame-curved mt-0.5 text-lg text-primary" aria-hidden="true" />
          <div class="min-w-0">
            <h2 class="text-sm font-bold uppercase tracking-wide text-muted">Calories burned</h2>
            <p
              v-if="calorieEstimate"
              class="mt-1 text-xl font-extrabold text-foreground"
            >
              {{ formatWorkoutCalories(calorieEstimate.calories) }}
            </p>
            <p
              v-else-if="!hasBodyWeightForCalories"
              class="mt-1 text-sm text-muted"
            >
              Add your body weight in
              <button
                type="button"
                class="font-bold text-primary underline-offset-2 hover:underline"
                @click="settingsOpen = true"
              >
                Settings
              </button>
              to see an estimate.
            </p>
            <p v-else class="mt-1 text-sm text-muted">
              Log sets or cardio duration to estimate calories.
            </p>
            <p
              v-if="calorieEstimate"
              class="mt-1 text-xs text-muted"
            >
              {{ formatPlanDurationEstimate(calorieEstimate.durationMinutes) }} session · estimate based on your body weight and logged work
            </p>
          </div>
        </div>
      </section>

      <button
        v-if="exercises.length > 0"
        type="button"
        class="mx-auto mt-3 flex w-full max-w-lg justify-center rounded-xl bg-primary py-3.5 text-base font-extrabold tracking-wide text-foreground"
        @click="finish"
      >
        Finish Workout
      </button>
    </div>

    <LibraryPickerModal
      :show="libraryOpen"
      @close="libraryOpen = false"
      @pick="addFromLibrary"
    />

    <SwapExerciseModal
      :show="swapModalExercise != null"
      :exercise="swapModalExercise"
      @close="swapModalExerciseId = null"
      @pick="applySwapExerciseReplacement"
    />

    <SettingsSheet
      :open="settingsOpen"
      :theme="sheetTheme"
      :weight-unit="sheetWeightUnit"
      :distance-unit="sheetDistanceUnit"
      :average-rest-seconds="sheetAverageRestSeconds"
      :average-lift-seconds="sheetAverageLiftSeconds"
      :body-weight-lbs="sheetBodyWeightLbs"
      @close="settingsOpen = false"
      @update:theme="settings.setTheme"
      @update:weight-unit="settings.setWeightUnit"
      @update:distance-unit="settings.setDistanceUnit"
      @update:average-rest-seconds="settings.setAverageRestSeconds"
      @update:average-lift-seconds="settings.setAverageLiftSeconds"
      @update:body-weight-lbs="settings.setBodyWeightLbs"
      @export-backup="onExportBackup"
      @import-backup="onImportBackup"
    />
  </div>
</template>
