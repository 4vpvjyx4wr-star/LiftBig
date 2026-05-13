<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import MonthGrid from '@/components/calendar/MonthGrid.vue'
import MonthNav from '@/components/calendar/MonthNav.vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import { useMonthCalendar } from '@/composables/useMonthCalendar'
import { formatDisplayDate } from '@/utils/dateKey'

const props = defineProps<{
  open: boolean
  sourceDate: string
}>()

const emit = defineEmits<{
  close: []
  done: [targetDate: string, action: 'move' | 'swap']
}>()

const workouts = inject(workoutsInjectionKey)!
const settings = inject(settingsInjectionKey)!

const viewYear = ref(new Date().getFullYear())
const viewMonth = ref(new Date().getMonth())

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

const targetDate = ref<string | null>(null)

const targetHasExercises = computed(() => {
  if (!targetDate.value) return false
  return workouts.getDay(targetDate.value).length > 0
})

const targetIsRest = computed(() => {
  if (!targetDate.value) return false
  return workouts.isRestDay(targetDate.value)
})

const actionLabel = computed(() => {
  if (!targetDate.value) return ''
  if (targetHasExercises.value) return 'Swap'
  return 'Move'
})

const actionDescription = computed(() => {
  if (!targetDate.value) return ''
  const from = formatDisplayDate(props.sourceDate)
  const to = formatDisplayDate(targetDate.value)
  if (targetHasExercises.value) {
    return `Swap workouts between ${from} and ${to}.`
  }
  if (targetIsRest.value) {
    return `Move exercises to ${to} (currently a rest day — it will be replaced).`
  }
  return `Move exercises from ${from} to ${to}.`
})

function onPickTarget(key: string) {
  if (key === props.sourceDate) return
  targetDate.value = key
}

function confirm() {
  if (!targetDate.value) return
  const action = targetHasExercises.value ? 'swap' : 'move'
  emit('done', targetDate.value, action)
}

watch(
  () => props.open,
  (open) => {
    if (open) {
      const parts = props.sourceDate.split('-').map(Number)
      viewYear.value = parts[0]!
      viewMonth.value = parts[1]! - 1
      targetDate.value = null
    }
  },
)
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex flex-col justify-end bg-black/65"
      role="dialog"
      aria-modal="true"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[80vh] overflow-y-auto rounded-t-2xl border border-border border-b-0 bg-card px-4 pb-8 pt-2"
        @click.stop
      >
        <div class="mx-auto mb-3 h-1 w-10 rounded-full bg-border" />
        <h3 class="text-center text-lg font-extrabold text-foreground">Move / Swap Workout</h3>
        <p class="mb-4 text-center text-xs text-muted">
          Pick a target day. If it's empty, exercises are moved. If it already has exercises,
          the two days will be swapped.
        </p>

        <div class="mb-3">
          <MonthNav :label="monthLabel" @prev="changeMonth(-1)" @next="changeMonth(1)" />
        </div>

        <div class="rounded-xl border border-border bg-card-inner p-3">
          <MonthGrid
            :cell-keys="cellKeys"
            :selected-key="targetDate"
            :today-key="sourceDate"
            :log="workouts.log.value"
            :highlight-selection="true"
            @pick="onPickTarget"
          />
        </div>

        <div v-if="targetDate" class="mt-4 rounded-xl border border-border bg-card-inner px-4 py-3">
          <p class="text-sm text-foreground">
            <span class="font-bold text-primary">{{ actionLabel }}:</span>
            {{ actionDescription }}
          </p>
        </div>

        <div class="mt-4 flex gap-2">
          <button
            type="button"
            class="flex-1 rounded-lg border border-border bg-card-inner px-4 py-2.5 text-sm font-bold text-foreground"
            @click="emit('close')"
          >
            Cancel
          </button>
          <button
            type="button"
            class="flex-1 rounded-lg bg-primary px-4 py-2.5 text-sm font-bold text-foreground disabled:opacity-40"
            :disabled="!targetDate"
            @click="confirm"
          >
            {{ targetDate ? actionLabel : 'Select a day' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
