<script setup lang="ts">
import { computed, inject, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import Sortable from 'sortablejs'
import { RouterLink } from 'vue-router'
import MonthGrid from '@/components/calendar/MonthGrid.vue'
import MonthNav from '@/components/calendar/MonthNav.vue'
import CopyDaySheet from '@/components/calendar/CopyDaySheet.vue'
import MoveDaySheet from '@/components/calendar/MoveDaySheet.vue'
import ExerciseDetailSheet from '@/components/library/ExerciseDetailSheet.vue'
import ExerciseNameSuggestList from '@/components/library/ExerciseNameSuggestList.vue'
import LibraryPickerModal from '@/components/library/LibraryPickerModal.vue'
import AssignPlanSheet from '@/components/plans/AssignPlanSheet.vue'
import {
  settingsInjectionKey,
  workoutsInjectionKey,
  templatesInjectionKey,
} from '@/composables/injectionKeys'
import { useExerciseNameSuggest } from '@/composables/useExerciseNameSuggest'
import { useMonthCalendar } from '@/composables/useMonthCalendar'
import type { Exercise, WorkoutTemplate } from '@/types/workout'
import { formatDisplayDate, todayKey } from '@/utils/dateKey'
import {
  dismissDailyReminderForToday,
  evaluateDailyLiftReminder,
} from '@/utils/dailyLiftReminder'
import { haptic } from '@/utils/haptics'
import {
  displayInputToStoredLbsString,
  formatMaxWeightDisplay,
  formatWeightWithUnit,
  parseStoredLbs,
  storedLbsStringToDisplay,
} from '@/utils/units'
import {
  formatPlanDurationEstimate,
  planDurationAssumptionsFromSeconds,
} from '@/utils/planDuration'
import { getLibraryExercise, isFavoritesLibrarySearchQuery, resolveManualExerciseInput, type LibraryExercise } from '@/utils/exerciseLibrary'
import { predictWorkoutGoals } from '@/utils/progressiveOverload'
import { formatCircuitExerciseGoal } from '@/utils/circuitExerciseDisplay'
import { cardioTargetDurationMinutes, exerciseIsCardio } from '@/types/workout'

const workouts = inject(workoutsInjectionKey)!
const templates = inject(templatesInjectionKey)!
const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)

const today = todayKey()
const viewYear = ref(new Date().getFullYear())
const viewMonth = ref(new Date().getMonth())
const selectedDate = ref(today)

const { monthLabel, cells, trainedDaysInMonth, loggedRestDaysInMonth, consistencyDaysInMonth } =
  useMonthCalendar(viewYear, viewMonth)

const cellKeys = computed(() => cells.value.keys)
const daysInMonth = computed(() => cells.value.daysInMonth)

function changeMonth(delta: number) {
  let nm = viewMonth.value + delta
  let ny = viewYear.value
  if (nm > 11) {
    nm = 0
    ny++
  }
  if (nm < 0) {
    nm = 11
    ny--
  }
  viewMonth.value = nm
  viewYear.value = ny
}

const planSheetOpen = ref(false)

const workoutLogPlain = computed(() => workouts.log.value)
const templateList = computed(() => templates.templates.value)

const dayExercises = computed(() => workouts.getDay(selectedDate.value))
const exerciseCount = computed(() => dayExercises.value.length)
const dayPlanName = computed(() => workouts.getPlanName(selectedDate.value))
const dayPlanFolderName = computed(() => workouts.getPlanFolderName(selectedDate.value))
const dayPlanNotes = computed(() => workouts.getPlanNotes(selectedDate.value))

const trained = computed(() => trainedDaysInMonth(workoutLogPlain.value))
const loggedRest = computed(() => loggedRestDaysInMonth(workoutLogPlain.value))
const consistencyDays = computed(() => consistencyDaysInMonth(workoutLogPlain.value))
const consistency = computed(() =>
  consistencyDays.value > 0
    ? Math.round((consistencyDays.value / daysInMonth.value) * 100)
    : 0,
)

const selectedIsRest = computed(() => workouts.isRestDay(selectedDate.value))

function dayStats(exercises: Exercise[]) {
  let sets = 0
  let reps = 0
  let maxW = 0
  for (const ex of exercises) {
    sets += ex.sets.length
    for (const s of ex.sets) {
      const r = parseInt(s.reps, 10)
      if (!isNaN(r)) reps += r
      const w = parseFloat(s.weight)
      if (!isNaN(w)) maxW = Math.max(maxW, w)
    }
  }
  return { sets, reps, maxW }
}

const selectedDayStats = computed(() => dayStats(dayExercises.value))

const selectedDayDuration = computed(() => {
  const totalSets = selectedDayStats.value.sets
  if (totalSets <= 0) return ''
  const assumptions = planDurationAssumptionsFromSeconds(
    settings.averageLiftSeconds.value,
    settings.averageRestSeconds.value,
  )
  const minutes =
    totalSets * assumptions.minutesPerSet + (totalSets - 1) * assumptions.minutesRestBetweenSets
  return formatPlanDurationEstimate(minutes)
})

function deleteDay() {
  const msg = selectedIsRest.value
    ? 'Remove this rest day from the calendar?'
    : 'Delete all exercises for this day?'
  if (!confirm(msg)) return
  workouts.deleteDay(selectedDate.value)
}

function onAssignPlan(payload: { template: WorkoutTemplate; restDaysPerWeek: number; folderName?: string }) {
  workouts.applyPlanWithWeeklyRest(selectedDate.value, payload.template, payload.restDaysPerWeek, payload.folderName)
  planSheetOpen.value = false
  haptic('success')
}

const moveSheetOpen = ref(false)
const copySheetOpen = ref(false)
const detailOpen = ref(false)
const detailExercise = ref<LibraryExercise | null>(null)

function openLibraryDetail(libraryId: string | undefined) {
  if (!libraryId) return
  const entry = getLibraryExercise(libraryId)
  if (!entry) return
  detailExercise.value = entry
  detailOpen.value = true
}

function closeLibraryDetail() {
  detailOpen.value = false
  detailExercise.value = null
}

function onMoveDone(targetDate: string, action: 'move' | 'swap') {
  if (action === 'swap') {
    workouts.swapDays(selectedDate.value, targetDate)
  } else {
    workouts.moveDay(selectedDate.value, targetDate)
  }
  moveSheetOpen.value = false
  selectedDate.value = targetDate
}

function onCopyDone(targetDate: string) {
  workouts.copyExercisesToDay(selectedDate.value, targetDate)
  copySheetOpen.value = false
  selectedDate.value = targetDate
}

function exerciseGoalLabel(ex: Exercise): string {
  if (exerciseIsCardio(ex)) {
    const duration = cardioTargetDurationMinutes(ex)
    return duration ? `${duration} min` : `${ex.sets.length} set${ex.sets.length !== 1 ? 's' : ''}`
  }
  if (ex.isCircuit) {
    return formatCircuitExerciseGoal(ex, weightUnit.value)
  }

  const parts: string[] = []
  const setCount = ex.sets.length
  parts.push(`${setCount} set${setCount !== 1 ? 's' : ''}`)

  const lbs = ex.targetWeight ? parseStoredLbs(ex.targetWeight) : NaN
  const hasRepGoal = !!(ex.targetReps ?? '').trim()
  const pred = predictWorkoutGoals(ex.name, workouts.log.value, {
    currentTargetReps: ex.targetReps,
    excludeDateKey: selectedDate.value,
    displayUnit: weightUnit.value,
    lockRepGoal: hasRepGoal,
    ignoreStoredGoalWeight: true,
  })

  const repsLabel = pred.hasHistory ? pred.suggestedReps : ex.targetReps
  if (repsLabel) {
    parts.push(`× ${repsLabel}`)
  }
  if (pred.hasHistory && pred.suggestedWeightLbs > 0) {
    parts.push(`@ ${formatWeightWithUnit(pred.suggestedWeightLbs, weightUnit.value, 1)}`)
  } else if (ex.targetWeight && !Number.isNaN(lbs)) {
    parts.push(`@ ${formatWeightWithUnit(lbs, weightUnit.value, 1)}`)
  }

  return parts.join(' ')
}

function removeExercise(exerciseId: string, exerciseName: string) {
  if (!confirm(`Remove "${exerciseName}" from this day?`)) return
  const updated = dayExercises.value.filter((ex) => ex.id !== exerciseId)
  workouts.setDay(selectedDate.value, updated)
}

const editingGoalsId = ref<string | null>(null)
const editGoalRepsDraft = ref('')
const editGoalWeightDraft = ref('')

function openGoalEditor(ex: Exercise) {
  editingGoalsId.value = ex.id
  editGoalRepsDraft.value = ex.targetReps ?? ''
  editGoalWeightDraft.value = ex.targetWeight
    ? storedLbsStringToDisplay(ex.targetWeight, weightUnit.value)
    : ''
}

function saveGoalEdits() {
  const id = editingGoalsId.value
  if (!id) return
  const updated = dayExercises.value.map((ex) => {
    if (ex.id !== id) return ex
    const next = { ...ex }
    const reps = editGoalRepsDraft.value.trim()
    next.targetReps = reps || undefined
    const w = editGoalWeightDraft.value.trim()
    next.targetWeight = w ? displayInputToStoredLbsString(w, weightUnit.value) : undefined
    return next
  })
  workouts.setDay(selectedDate.value, updated)
  editingGoalsId.value = null
}

function cancelGoalEdits() {
  editingGoalsId.value = null
}

const addPanelOpen = ref(false)
const addInputName = ref('')
const addGoalReps = ref('')
const addGoalWeightStoredLbs = ref('')
const libraryPickerOpen = ref(false)
const {
  show: showExerciseSuggest,
  matches: exerciseSuggestMatches,
  onFocus: onExerciseSuggestFocus,
  hideSoon: hideExerciseSuggestSoon,
  dismiss: dismissExerciseSuggest,
} = useExerciseNameSuggest(addInputName)

function newId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 11)}`
}

function addExerciseGoals(): Partial<Pick<Exercise, 'targetReps' | 'targetWeight'>> {
  const out: Partial<Pick<Exercise, 'targetReps' | 'targetWeight'>> = {}
  const reps = addGoalReps.value.trim()
  const w = addGoalWeightStoredLbs.value.trim()
  if (reps) out.targetReps = reps
  if (w) out.targetWeight = w
  return out
}

function addManualExercise() {
  const trimmed = addInputName.value.trim()
  if (!trimmed) return
  if (isFavoritesLibrarySearchQuery(trimmed)) return
  const resolved = resolveManualExerciseInput(trimmed)
  if (resolved) {
    addFromLibrary(resolved)
    addInputName.value = ''
    return
  }
  const ex: Exercise = {
    id: newId(),
    name: trimmed,
    ...addExerciseGoals(),
    sets: [{ id: newId(), reps: '', weight: '' }],
  }
  workouts.appendExercises(selectedDate.value, [ex])
  addInputName.value = ''
}

function addFromLibrary(lib: LibraryExercise) {
  const ex: Exercise = {
    id: newId(),
    name: lib.name,
    libraryId: lib.id,
    ...addExerciseGoals(),
    sets: [{ id: newId(), reps: '', weight: '' }],
  }
  workouts.appendExercises(selectedDate.value, [ex])
}

function addFromInlineMatch(lib: LibraryExercise) {
  addFromLibrary(lib)
  addInputName.value = ''
  dismissExerciseSuggest()
}

function openAddPanel() {
  addInputName.value = ''
  addGoalReps.value = ''
  addGoalWeightStoredLbs.value = ''
  addPanelOpen.value = true
}

function toggleRestDay() {
  if (selectedIsRest.value) {
    workouts.deleteDay(selectedDate.value)
    return
  }
  if (exerciseCount.value > 0) {
    if (!confirm('Replace this day’s logged workout with a rest day?')) return
  }
  workouts.markRestDay(selectedDate.value)
}

function onPickDay(key: string) {
  selectedDate.value = key
}

const homeExerciseListEl = ref<HTMLElement | null>(null)
let homeExerciseSortable: Sortable | null = null

function destroyHomeExerciseSortable() {
  homeExerciseSortable?.destroy()
  homeExerciseSortable = null
}

function bindHomeExerciseSortable() {
  destroyHomeExerciseSortable()
  const el = homeExerciseListEl.value
  if (!el || dayExercises.value.length < 2) return

  homeExerciseSortable = Sortable.create(el, {
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
      const next = [...dayExercises.value]
      const [moved] = next.splice(oi, 1)
      if (!moved) return
      next.splice(ni, 0, moved)
      workouts.setDay(selectedDate.value, next)
    },
  })
}

onMounted(() => {
  nextTick(bindHomeExerciseSortable)
})

watch(selectedDate, () => {
  nextTick(bindHomeExerciseSortable)
})

watch(exerciseCount, () => {
  nextTick(bindHomeExerciseSortable)
})

onBeforeUnmount(() => {
  destroyHomeExerciseSortable()
})

const dailyReminderDismissTick = ref(0)

const dailyReminder = computed(() => {
  dailyReminderDismissTick.value
  return evaluateDailyLiftReminder(
    workoutLogPlain.value,
    settings.dailyLiftReminderEnabled.value,
    settings.dailyLiftReminderTime.value,
  )
})

function dismissDailyNudge() {
  dismissDailyReminderForToday()
  dailyReminderDismissTick.value++
  haptic('tap')
}

const liftHref = computed(() => `/workout/${today}`)
</script>

<template>
  <div>
    <div
      v-if="dailyReminder.shouldNudge"
      class="mb-4 flex items-start gap-3 rounded-xl border border-primary/40 bg-primary/10 px-4 py-3"
      role="status"
    >
      <i class="fa-solid fa-dumbbell mt-0.5 text-primary" aria-hidden="true" />
      <div class="min-w-0 flex-1">
        <p class="text-sm font-extrabold text-foreground">Time to lift big</p>
        <p class="mt-0.5 text-xs leading-snug text-muted">
          You haven't logged today's workout yet. Open your log when you're ready.
        </p>
        <div class="mt-2 flex flex-wrap gap-2">
          <RouterLink
            :to="liftHref"
            class="inline-flex rounded-lg bg-primary px-3 py-1.5 text-xs font-bold text-foreground"
          >
            Open log
          </RouterLink>
          <button
            type="button"
            class="rounded-lg border border-border bg-card-inner px-3 py-1.5 text-xs font-bold text-muted"
            @click="dismissDailyNudge"
          >
            Not today
          </button>
        </div>
      </div>
    </div>

    <div class="mb-4">
      <MonthNav :label="monthLabel" @prev="changeMonth(-1)" @next="changeMonth(1)" />
    </div>

    <div class="mb-3 flex rounded-xl border border-border bg-card">
      <div class="flex flex-1 flex-col items-center py-3">
        <span class="text-2xl font-black text-foreground">{{ trained }}</span>
        <span class="text-[10px] font-bold tracking-wider text-muted">TRAINED</span>
      </div>
      <div class="w-px bg-border" />
      <div class="flex flex-1 flex-col items-center py-3">
        <span class="text-2xl font-black text-foreground">{{ loggedRest }}</span>
        <span class="text-[10px] font-bold tracking-wider text-muted">REST</span>
      </div>
      <div class="w-px bg-border" />
      <div class="flex flex-1 flex-col items-center py-3">
        <span class="text-2xl font-black text-foreground">{{ consistency }}%</span>
        <span class="text-[10px] font-bold tracking-wider text-muted">CONSISTENCY</span>
      </div>
    </div>

    <div class="rounded-xl border border-border bg-card p-3">
      <MonthGrid
        :cell-keys="cellKeys"
        :selected-key="selectedDate"
        :today-key="today"
        :log="workoutLogPlain"
        :highlight-selection="true"
        @pick="onPickDay"
      />
    </div>

    <section class="relative mt-4 rounded-xl border border-border bg-card p-4">
      <div class="absolute right-3 top-3 flex gap-1.5">
        <button
          type="button"
          class="rounded-lg border border-border bg-card-inner px-3 py-1.5 text-xs font-bold text-foreground disabled:opacity-40"
          :disabled="exerciseCount === 0"
          @click="copySheetOpen = true"
        >
          <i class="fa-solid fa-copy mr-1 text-[10px] text-muted" aria-hidden="true" />Copy
        </button>
        <button
          type="button"
          class="rounded-lg border border-border bg-card-inner px-3 py-1.5 text-xs font-bold text-foreground disabled:opacity-40"
          :disabled="exerciseCount === 0"
          @click="moveSheetOpen = true"
        >
          <i class="fa-solid fa-right-left mr-1 text-[10px] text-muted" aria-hidden="true" />Move / Swap
        </button>
      </div>
      <h3 class="pr-36 text-lg font-bold text-foreground">{{ formatDisplayDate(selectedDate) }}</h3>
      <div class="mt-2 flex gap-2">
        <RouterLink
          :to="`/workout/${selectedDate}`"
          class="inline-flex flex-1 items-center justify-center rounded-lg bg-blue px-4 py-2.5 text-center text-sm font-bold text-foreground"
        >
          {{ exerciseCount === 0 ? 'Log workout' : 'Open log' }}
        </RouterLink>
        <button
          type="button"
          class="flex-1 rounded-lg border border-teal-800/60 bg-teal-950/35 px-4 py-2.5 text-sm font-bold text-teal-200"
          @click="toggleRestDay"
        >
          {{ selectedIsRest ? 'Clear rest day' : 'Rest day' }}
        </button>
        <button
          type="button"
          class="flex-1 rounded-lg border border-red-900/50 bg-card-inner px-4 py-2.5 text-sm font-bold text-red-400"
          :disabled="exerciseCount === 0 && !selectedIsRest"
          @click="deleteDay"
        >
          Delete day
        </button>
      </div>

      <template v-if="selectedIsRest">
        <p class="mt-2 text-sm font-semibold text-teal-300/90">Rest day — counts toward your consistency score.</p>
      </template>
      <template v-else-if="exerciseCount === 0">
        <p class="mt-2 text-sm text-muted">No workout logged for this day.</p>
      </template>
      <template v-else>
        <p v-if="dayPlanName" class="mt-3">
          <span class="text-base font-extrabold text-foreground">{{ dayPlanName }}</span>
          <span v-if="dayPlanFolderName" class="ml-1.5 text-xs text-muted">({{ dayPlanFolderName }})</span>
        </p>
        <p
          v-if="dayPlanNotes"
          class="mt-2 whitespace-pre-line rounded-lg border border-border bg-card-inner/60 px-2.5 py-2 text-xs leading-relaxed text-foreground"
        >
          {{ dayPlanNotes }}
        </p>
        <p class="mt-2 text-xs text-muted">
          {{ selectedDayDuration }} · {{ selectedDayStats.sets }} sets · {{ selectedDayStats.reps }} total reps (where entered) ·
          max {{ formatMaxWeightDisplay(selectedDayStats.maxW, weightUnit) }}
        </p>
        <ul ref="homeExerciseListEl" class="mt-3 space-y-2">
          <li
            v-for="ex in dayExercises"
            :key="ex.id"
            class="flex items-center gap-2 rounded-lg border border-border bg-card-inner px-3 py-2"
          >
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <RouterLink
                  :to="`/workout/${selectedDate}`"
                  class="exercise-reorder-handle cursor-grab font-bold text-foreground hover:text-primary active:cursor-grabbing touch-manipulation select-none"
                  title="Hold, then drag to reorder"
                >
                  {{ ex.name }}
                </RouterLink>
                <button
                  v-if="ex.libraryId && getLibraryExercise(ex.libraryId)"
                  type="button"
                  class="text-primary hover:text-foreground"
                  aria-label="How to perform this exercise"
                  @click="openLibraryDetail(ex.libraryId)"
                >
                  <i class="fa-solid fa-circle-info text-xs" aria-hidden="true" />
                </button>
              </div>
              <div class="flex items-center gap-1.5">
                <span class="text-xs text-muted">{{ exerciseGoalLabel(ex) }}</span>
                <button
                  v-if="!ex.isCircuit"
                  type="button"
                  class="text-muted hover:text-primary"
                  aria-label="Edit goals"
                  @click="editingGoalsId === ex.id ? cancelGoalEdits() : openGoalEditor(ex)"
                >
                  <i class="fa-solid fa-pen text-[10px]" aria-hidden="true" />
                </button>
              </div>
              <div
                v-if="editingGoalsId === ex.id"
                class="mt-2 rounded-lg border border-border bg-card p-2.5"
              >
                <div class="grid grid-cols-2 gap-2">
                  <div>
                    <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal reps</label>
                    <input
                      v-model="editGoalRepsDraft"
                      type="text"
                      class="mt-0.5 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-sm text-foreground outline-none focus:border-primary"
                      placeholder="e.g. 8–12"
                      inputmode="text"
                    />
                  </div>
                  <div>
                    <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal weight</label>
                    <input
                      v-model="editGoalWeightDraft"
                      type="text"
                      inputmode="decimal"
                      class="mt-0.5 w-full rounded-lg border border-border bg-card-inner px-2 py-1.5 text-sm text-foreground outline-none focus:border-primary"
                      :placeholder="weightUnit === 'lb' ? 'lb' : 'kg'"
                    />
                  </div>
                </div>
                <div class="mt-2 flex gap-2">
                  <button
                    type="button"
                    class="flex-1 rounded-lg bg-primary px-3 py-1.5 text-xs font-bold text-foreground"
                    @click="saveGoalEdits"
                  >
                    Save
                  </button>
                  <button
                    type="button"
                    class="flex-1 rounded-lg border border-border bg-card-inner px-3 py-1.5 text-xs font-bold text-muted"
                    @click="cancelGoalEdits"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
            <button
              type="button"
              class="flex h-7 w-7 shrink-0 items-center justify-center rounded-md text-red-400 hover:bg-red-900/30"
              aria-label="Remove exercise"
              @click="removeExercise(ex.id, ex.name)"
            >
              <i class="fa-solid fa-xmark text-sm" aria-hidden="true" />
            </button>
          </li>
        </ul>
        <div v-if="addPanelOpen" class="mt-3 rounded-lg border border-border bg-card-inner p-3">
          <div class="relative">
            <input
              v-model="addInputName"
              type="text"
              class="w-full rounded-lg border border-border bg-card px-3 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              placeholder="Exercise name..."
              @focus="onExerciseSuggestFocus()"
              @blur="hideExerciseSuggestSoon()"
              @keydown.enter="addManualExercise"
            />
            <ExerciseNameSuggestList
              :show="showExerciseSuggest"
              :matches="exerciseSuggestMatches"
              @pick="addFromInlineMatch"
            />
          </div>
          <div class="mt-2 grid grid-cols-2 gap-2">
            <div>
              <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal reps</label>
              <input
                v-model="addGoalReps"
                type="text"
                class="mt-0.5 w-full rounded-lg border border-border bg-card px-2 py-1.5 text-sm text-foreground outline-none focus:border-primary"
                placeholder="e.g. 8–12"
                inputmode="text"
              />
            </div>
            <div>
              <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">Goal weight</label>
              <input
                :value="storedLbsStringToDisplay(addGoalWeightStoredLbs, weightUnit)"
                type="text"
                inputmode="decimal"
                class="mt-0.5 w-full rounded-lg border border-border bg-card px-2 py-1.5 text-sm text-foreground outline-none focus:border-primary"
                :placeholder="weightUnit === 'lb' ? 'lb' : 'kg'"
                @input="
                  addGoalWeightStoredLbs = displayInputToStoredLbsString(
                    ($event.target as HTMLInputElement).value,
                    weightUnit,
                  )
                "
              />
            </div>
          </div>
          <div class="mt-2 flex gap-2">
            <button
              type="button"
              class="flex-1 rounded-lg bg-blue px-4 py-2.5 text-sm font-bold text-foreground"
              @click="addManualExercise"
            >
              Add
            </button>
            <button
              type="button"
              class="flex-1 rounded-lg border border-primary/50 bg-card px-4 py-2.5 text-sm font-bold text-primary"
              @click="libraryPickerOpen = true"
            >
              Library
            </button>
            <button
              type="button"
              class="rounded-lg border border-border bg-card px-4 py-2.5 text-sm font-bold text-muted"
              @click="addPanelOpen = false"
            >
              Close
            </button>
          </div>
        </div>
        <button
          v-else
          type="button"
          class="mt-3 flex w-full items-center justify-center gap-2 rounded-lg border border-dashed border-border bg-card-inner px-4 py-2.5 text-sm font-bold text-foreground"
          @click="openAddPanel"
        >
          <i class="fa-solid fa-plus text-xs text-muted" aria-hidden="true" />
          Add exercise
        </button>
      </template>

      <div class="mt-4 flex flex-wrap gap-2">
        <button
          v-if="templateList.length > 0"
          type="button"
          class="flex w-full min-[400px]:w-auto min-[400px]:flex-1 items-center justify-center gap-2 rounded-lg border border-dashed border-border bg-card-inner px-4 py-3 text-sm font-bold text-foreground"
          @click="planSheetOpen = true"
        >
          <i class="fa-solid fa-clipboard-list text-muted" aria-hidden="true" />
          Assign a plan to this day
        </button>
      </div>
    </section>

    <AssignPlanSheet :open="planSheetOpen" @close="planSheetOpen = false" @pick="onAssignPlan" />
    <CopyDaySheet
      :open="copySheetOpen"
      :source-date="selectedDate"
      @close="copySheetOpen = false"
      @done="onCopyDone"
    />
    <MoveDaySheet
      :open="moveSheetOpen"
      :source-date="selectedDate"
      @close="moveSheetOpen = false"
      @done="onMoveDone"
    />
    <ExerciseDetailSheet :open="detailOpen" :exercise="detailExercise" @close="closeLibraryDetail" />
    <LibraryPickerModal
      :show="libraryPickerOpen"
      @close="libraryPickerOpen = false"
      @pick="addFromLibrary"
    />
  </div>
</template>
