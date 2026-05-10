<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import { RouterLink } from 'vue-router'
import MonthGrid from '@/components/calendar/MonthGrid.vue'
import MonthNav from '@/components/calendar/MonthNav.vue'
import AssignPlanSheet from '@/components/plans/AssignPlanSheet.vue'
import {
  settingsInjectionKey,
  workoutsInjectionKey,
  templatesInjectionKey,
} from '@/composables/injectionKeys'
import { useMonthCalendar } from '@/composables/useMonthCalendar'
import type { Exercise, WorkoutTemplate } from '@/types/workout'
import { formatDisplayDate, todayKey } from '@/utils/dateKey'
import { formatMaxWeightDisplay } from '@/utils/units'

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

function deleteDay() {
  const msg = selectedIsRest.value
    ? 'Remove this rest day from the calendar?'
    : 'Delete all exercises for this day?'
  if (!confirm(msg)) return
  workouts.deleteDay(selectedDate.value)
}

function onAssignPlan(payload: { template: WorkoutTemplate; restDaysPerWeek: number }) {
  workouts.applyPlanWithWeeklyRest(selectedDate.value, payload.template, payload.restDaysPerWeek)
  planSheetOpen.value = false
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
</script>

<template>
  <div>
    <header class="mb-4 border-b border-border pb-3">
      <h1 class="text-3xl font-black tracking-[0.2em] text-primary">LIFTBIG</h1>
      <p class="text-[10px] font-bold tracking-[0.2em] text-muted">Training Journal</p>
    </header>

    <MonthNav :label="monthLabel" @prev="changeMonth(-1)" @next="changeMonth(1)" />

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

    <section class="mt-4 rounded-xl border border-border bg-card p-4">
      <h3 class="text-lg font-bold text-foreground">{{ formatDisplayDate(selectedDate) }}</h3>

      <template v-if="selectedIsRest">
        <p class="mt-2 text-sm font-semibold text-teal-300/90">Rest day — counts toward your consistency score.</p>
      </template>
      <template v-else-if="exerciseCount === 0">
        <p class="mt-2 text-sm text-muted">No workout logged for this day.</p>
      </template>
      <template v-else>
        <p class="mt-2 text-xs text-muted">
          {{ selectedDayStats.sets }} sets · {{ selectedDayStats.reps }} total reps (where entered) ·
          max {{ formatMaxWeightDisplay(selectedDayStats.maxW, weightUnit) }}
        </p>
        <ul class="mt-3 space-y-2">
          <li
            v-for="ex in dayExercises"
            :key="ex.id"
            class="rounded-lg border border-border bg-card-inner px-3 py-2"
          >
            <div class="font-bold text-foreground">{{ ex.name }}</div>
            <div class="text-xs text-muted">{{ ex.sets.length }} sets</div>
          </li>
        </ul>
      </template>

      <div class="mt-4 flex flex-wrap gap-2">
        <RouterLink
          :to="`/workout/${selectedDate}`"
          class="inline-flex flex-1 items-center justify-center rounded-lg bg-blue px-4 py-3 text-center text-sm font-bold text-foreground min-[400px]:flex-none"
        >
          {{ exerciseCount === 0 ? 'Log workout' : 'Open log' }}
        </RouterLink>
        <button
          type="button"
          class="rounded-lg border border-teal-800/60 bg-teal-950/35 px-4 py-3 text-sm font-bold text-teal-200"
          @click="toggleRestDay"
        >
          {{ selectedIsRest ? 'Clear rest day' : 'Rest day' }}
        </button>
        <button
          type="button"
          class="rounded-lg border border-red-900/50 bg-card-inner px-4 py-3 text-sm font-bold text-red-400"
          :disabled="exerciseCount === 0 && !selectedIsRest"
          @click="deleteDay"
        >
          Delete day
        </button>
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

    <AssignPlanSheet
      :open="planSheetOpen"
      :templates="templateList"
      @close="planSheetOpen = false"
      @pick="onAssignPlan"
    />
  </div>
</template>
