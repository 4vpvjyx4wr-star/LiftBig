<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import { RouterLink } from 'vue-router'
import MonthGrid from '@/components/calendar/MonthGrid.vue'
import MonthNav from '@/components/calendar/MonthNav.vue'
import AssignPlanSheet from '@/components/plans/AssignPlanSheet.vue'
import { workoutsInjectionKey, templatesInjectionKey } from '@/composables/injectionKeys'
import { useMonthCalendar } from '@/composables/useMonthCalendar'
import { cloneTemplateToExercises } from '@/utils/templateToLog'
import { formatDisplayDate, todayKey } from '@/utils/dateKey'

const workouts = inject(workoutsInjectionKey)!
const templates = inject(templatesInjectionKey)!

const today = todayKey()
const viewYear = ref(new Date().getFullYear())
const viewMonth = ref(new Date().getMonth())
const selectedDate = ref(today)

const { monthLabel, cells } = useMonthCalendar(viewYear, viewMonth)

const cellKeys = computed(() => cells.value.keys)

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

function deleteDay() {
  if (!confirm('Delete all exercises for this day?')) return
  workouts.deleteDay(selectedDate.value)
}

function onAssignPlan(t: import('@/types/workout').WorkoutTemplate) {
  const added = cloneTemplateToExercises(t)
  workouts.appendExercises(selectedDate.value, added)
  planSheetOpen.value = false
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
      <p class="mt-1 text-sm text-muted">
        {{ exerciseCount }} exercise{{ exerciseCount !== 1 ? 's' : '' }} logged
      </p>
      <div class="mt-4 flex flex-wrap gap-2">
        <RouterLink
          :to="`/workout/${selectedDate}`"
          class="inline-flex flex-1 items-center justify-center rounded-lg bg-blue px-4 py-3 text-center text-sm font-bold text-foreground min-[400px]:flex-none"
        >
          Open Log
        </RouterLink>
        <button
          type="button"
          class="rounded-lg border border-red-900/50 bg-card-inner px-4 py-3 text-sm font-bold text-red-400"
          :disabled="exerciseCount === 0"
          @click="deleteDay"
        >
          Delete day
        </button>
      </div>
    </section>

    <button
      v-if="templateList.length > 0"
      type="button"
      class="mt-4 flex w-full items-center justify-center gap-2 rounded-xl border border-dashed border-border bg-card py-3 text-sm font-bold text-foreground"
      @click="planSheetOpen = true"
    >
      <i class="fa-solid fa-clipboard-list text-muted" aria-hidden="true" />
      Assign a Plan to This Day
    </button>

    <AssignPlanSheet
      :open="planSheetOpen"
      :templates="templateList"
      @close="planSheetOpen = false"
      @pick="onAssignPlan"
    />
  </div>
</template>
