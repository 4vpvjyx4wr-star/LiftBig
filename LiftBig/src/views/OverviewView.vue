<script setup lang="ts">
import { computed, inject, ref } from 'vue'
import { useRouter } from 'vue-router'
import MonthGrid from '@/components/calendar/MonthGrid.vue'
import MonthNav from '@/components/calendar/MonthNav.vue'
import { workoutsInjectionKey } from '@/composables/injectionKeys'
import { useMonthCalendar } from '@/composables/useMonthCalendar'
import type { Exercise } from '@/types/workout'
import { formatDisplayDate, todayKey } from '@/utils/dateKey'

const router = useRouter()
const workouts = inject(workoutsInjectionKey)!

const viewYear = ref(new Date().getFullYear())
const viewMonth = ref(new Date().getMonth())
const modalDate = ref<string | null>(null)

const { monthLabel, cells, trainedDaysInMonth } = useMonthCalendar(viewYear, viewMonth)

const cellKeys = computed(() => cells.value.keys)
const daysInMonth = computed(() => cells.value.daysInMonth)

const workoutLogPlain = computed(() => workouts.log.value)

const trained = computed(() => trainedDaysInMonth(workoutLogPlain.value))
const restDays = computed(() => daysInMonth.value - trained.value)
const consistency = computed(() =>
  trained.value > 0 ? Math.round((trained.value / daysInMonth.value) * 100) : 0,
)

const modalExercises = computed<Exercise[]>(() =>
  modalDate.value ? (workoutLogPlain.value[modalDate.value] ?? []) : [],
)

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

const modalStats = computed(() => dayStats(modalExercises.value))

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

function openModal(key: string) {
  modalDate.value = key
}

function closeModal() {
  modalDate.value = null
}

function deleteModalDay() {
  if (!modalDate.value) return
  if (!confirm('Remove all exercises for this day?')) return
  workouts.deleteDay(modalDate.value)
  closeModal()
}

function editDay() {
  if (!modalDate.value) return
  router.push(`/workout/${modalDate.value}`)
  closeModal()
}
</script>

<template>
  <div>
    <header class="mb-4 border-b border-border pb-3">
      <h1 class="text-3xl font-black tracking-[0.2em] text-primary">LIFTBIG</h1>
      <p class="text-[10px] font-bold tracking-[0.2em] text-muted">Monthly Overview</p>
    </header>

    <MonthNav :label="monthLabel" @prev="changeMonth(-1)" @next="changeMonth(1)" />

    <div class="mb-3 flex rounded-xl border border-border bg-card">
      <div class="flex flex-1 flex-col items-center py-3">
        <span class="text-2xl font-black text-foreground">{{ trained }}</span>
        <span class="text-[10px] font-bold tracking-wider text-muted">TRAINED</span>
      </div>
      <div class="w-px bg-border" />
      <div class="flex flex-1 flex-col items-center py-3">
        <span class="text-2xl font-black text-foreground">{{ restDays }}</span>
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
        :selected-key="null"
        :today-key="todayKey()"
        :log="workoutLogPlain"
        :highlight-selection="false"
        @pick="openModal"
      />
    </div>

    <Teleport to="body">
      <div
        v-if="modalDate"
        class="fixed inset-0 z-50 flex items-end justify-center bg-black/65 sm:items-center"
        @click.self="closeModal"
      >
        <div
          class="max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-card p-4 sm:rounded-2xl"
          @click.stop
        >
          <h3 class="text-lg font-extrabold text-foreground">
            {{ formatDisplayDate(modalDate) }}
          </h3>

          <template v-if="modalExercises.length === 0">
            <p class="mt-3 text-sm text-muted">No workout logged for this day.</p>
            <button
              type="button"
              class="mt-4 w-full rounded-lg bg-blue py-3 text-sm font-bold text-foreground"
              @click="editDay"
            >
              Log workout
            </button>
          </template>

          <template v-else>
            <p class="mt-2 text-xs text-muted">
              {{ modalStats.sets }} sets · {{ modalStats.reps }} total reps (where entered) · max
              {{ modalStats.maxW || '—' }} lbs
            </p>
            <ul class="mt-4 space-y-2">
              <li
                v-for="ex in modalExercises"
                :key="ex.id"
                class="rounded-lg border border-border bg-card-inner px-3 py-2"
              >
                <div class="font-bold text-foreground">{{ ex.name }}</div>
                <div class="text-xs text-muted">{{ ex.sets.length }} sets</div>
              </li>
            </ul>
            <div class="mt-4 flex flex-col gap-2 sm:flex-row">
              <button
                type="button"
                class="flex-1 rounded-lg bg-blue py-3 text-sm font-bold text-foreground"
                @click="editDay"
              >
                Edit
              </button>
              <button
                type="button"
                class="flex-1 rounded-lg border border-red-900/50 py-3 text-sm font-bold text-red-400"
                @click="deleteModalDay"
              >
                Delete day
              </button>
            </div>
          </template>

          <button
            type="button"
            class="mt-3 w-full py-2 text-sm font-semibold text-muted"
            @click="closeModal"
          >
            Close
          </button>
        </div>
      </div>
    </Teleport>
  </div>
</template>
