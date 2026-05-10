<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import { RouterLink } from 'vue-router'
import ExerciseDetailSheet from '@/components/library/ExerciseDetailSheet.vue'
import PlanEditorModal from '@/components/plans/PlanEditorModal.vue'
import PlanShuffleModal from '@/components/plans/PlanShuffleModal.vue'
import SchedulePlanCalendarSheet from '@/components/plans/SchedulePlanCalendarSheet.vue'
import { settingsInjectionKey, templatesInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import type { WorkoutTemplate } from '@/types/workout'
import { getLibraryExercise, type LibraryExercise } from '@/utils/exerciseLibrary'
import { estimatePlanDurationMinutes, formatPlanDurationEstimate } from '@/utils/planDuration'
import { formatWeightWithUnit, parseStoredLbs } from '@/utils/units'

const templates = inject(templatesInjectionKey)!
const workouts = inject(workoutsInjectionKey)!
const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)

function formatTemplateWeight(s: string | undefined): string {
  if (!s?.trim()) return ''
  const lbs = parseStoredLbs(s)
  if (Number.isNaN(lbs)) return s
  return formatWeightWithUnit(lbs, weightUnit.value, 1)
}

const planList = computed(() => templates.templates.value)

const modalOpen = ref(false)
const editing = ref<WorkoutTemplate | null>(null)
const shuffleOpen = ref(false)
const scheduleOpen = ref(false)
const scheduleTemplate = ref<WorkoutTemplate | null>(null)

function openNew() {
  editing.value = null
  modalOpen.value = true
}

function openEdit(t: WorkoutTemplate) {
  editing.value = t
  modalOpen.value = true
}

function closeModal() {
  modalOpen.value = false
}

function openShuffle() {
  shuffleOpen.value = true
}

function closeShuffle() {
  shuffleOpen.value = false
}

function openScheduleToCalendar(t: WorkoutTemplate) {
  scheduleTemplate.value = t
  scheduleOpen.value = true
}

function closeScheduleSheet() {
  scheduleOpen.value = false
  scheduleTemplate.value = null
}

function onScheduleApply(payload: { startDateKey: string; restDaysPerWeek: number }) {
  if (!scheduleTemplate.value) return
  workouts.applyPlanWithWeeklyRest(
    payload.startDateKey,
    scheduleTemplate.value,
    payload.restDaysPerWeek,
  )
  closeScheduleSheet()
}

function onSave(payload: { id: string | null; name: string; exercises: import('@/types/workout').TemplateExercise[] }) {
  const list = planList.value
  let next: WorkoutTemplate[]
  if (payload.id) {
    next = list.map((t) =>
      t.id === payload.id
        ? { ...t, name: payload.name, exercises: payload.exercises }
        : t,
    )
  } else {
    const newT: WorkoutTemplate = {
      id: `${Date.now()}`,
      name: payload.name,
      exercises: payload.exercises,
    }
    next = [...list, newT]
  }
  templates.setAll(next)
  closeModal()
}

function deletePlan(id: string) {
  if (!confirm('Delete this plan?')) return
  templates.setAll(planList.value.filter((t) => t.id !== id))
}

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

function planDurationLabel(t: WorkoutTemplate): string {
  return formatPlanDurationEstimate(estimatePlanDurationMinutes(t))
}
</script>

<template>
  <div>
    <header class="mb-4 border-b border-border pb-3">
      <div class="flex items-start justify-between gap-2">
        <div>
          <h1 class="text-3xl font-black tracking-[0.2em] text-primary">LIFTBIG</h1>
          <p class="text-[10px] font-bold tracking-[0.2em] text-muted">Training Journal</p>
        </div>
        <div class="flex flex-wrap items-center justify-end gap-2">
          <button
            type="button"
            class="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-bold text-primary hover:border-primary"
            @click="openShuffle"
          >
            <i class="fa-solid fa-shuffle" aria-hidden="true" />
            Shuffle
          </button>
          <RouterLink
            to="/library"
            class="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-bold text-primary hover:border-primary"
          >
            <i class="fa-solid fa-book" aria-hidden="true" />
            Library
          </RouterLink>
        </div>
      </div>
    </header>

    <p class="mb-3 text-[10px] leading-snug text-muted">
      Time estimates assume ~1 min per working set and ~1 min rest between consecutive sets.
    </p>

    <div v-if="planList.length === 0" class="py-12 text-center">
      <p class="text-lg font-bold text-foreground">No plans yet.</p>
      <p class="mt-2 text-sm text-muted">Create a template to reuse across your calendar.</p>
    </div>

    <ul v-else class="space-y-3 pb-24">
      <li
        v-for="item in planList"
        :key="item.id"
        class="rounded-xl border border-border bg-card p-4"
      >
        <div class="flex items-start justify-between gap-2">
          <h3 class="text-lg font-extrabold text-foreground">{{ item.name }}</h3>
          <div class="flex shrink-0 flex-wrap justify-end gap-2">
            <button
              type="button"
              class="rounded-lg border border-border px-3 py-1 text-xs font-bold text-teal-200 hover:border-teal-700"
              @click="openScheduleToCalendar(item)"
            >
              Calendar
            </button>
            <button
              type="button"
              class="rounded-lg bg-blue px-3 py-1 text-xs font-bold text-foreground"
              @click="openEdit(item)"
            >
              Edit
            </button>
            <button
              type="button"
              class="rounded-lg border border-red-900/50 px-3 py-1 text-xs font-bold text-red-400"
              @click="deletePlan(item.id)"
            >
              Delete
            </button>
          </div>
        </div>
        <p class="mt-1 text-xs text-muted">
          {{ item.exercises.length }} exercise{{ item.exercises.length !== 1 ? 's' : '' }}
          · {{ planDurationLabel(item) }}
        </p>
        <ul class="mt-2 space-y-1 border-t border-border pt-2">
          <li
            v-for="ex in item.exercises"
            :key="ex.id"
            class="flex flex-wrap items-center gap-2 text-sm text-foreground"
          >
            <span class="text-muted">·</span>
            <span class="font-semibold">{{ ex.name }}</span>
            <button
              v-if="ex.libraryId && getLibraryExercise(ex.libraryId)"
              type="button"
              class="text-primary hover:text-foreground"
              aria-label="How to perform this exercise"
              @click="openLibraryDetail(ex.libraryId)"
            >
              <i class="fa-solid fa-circle-info text-xs" aria-hidden="true" />
            </button>
            <span class="text-muted">
              {{ ex.sets.length }} × {{ ex.sets[0]?.targetReps || '?' }}
              <template v-if="ex.sets[0]?.targetWeight"> @ {{ formatTemplateWeight(ex.sets[0].targetWeight) }}</template>
            </span>
          </li>
        </ul>
      </li>
    </ul>

    <button
      type="button"
      class="fixed bottom-24 left-1/2 z-30 flex -translate-x-1/2 items-center rounded-full bg-primary px-6 py-3 text-sm font-extrabold tracking-wide text-foreground shadow-lg max-sm:left-1/2 max-sm:max-w-[calc(100%-2rem)]"
      @click="openNew"
    >
      + New Plan
    </button>

    <PlanEditorModal
      :weight-unit="weightUnit"
      :show="modalOpen"
      :initial="editing"
      @close="closeModal"
      @save="onSave"
    />

    <PlanShuffleModal :show="shuffleOpen" @close="closeShuffle" @save="onSave" />

    <SchedulePlanCalendarSheet
      :open="scheduleOpen"
      :template="scheduleTemplate"
      @close="closeScheduleSheet"
      @apply="onScheduleApply"
    />

    <ExerciseDetailSheet
      :open="detailOpen"
      :exercise="detailExercise"
      @close="closeLibraryDetail"
    />
  </div>
</template>
