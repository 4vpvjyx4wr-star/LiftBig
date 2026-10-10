<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import MonthGrid from '@/components/calendar/MonthGrid.vue'
import MonthNav from '@/components/calendar/MonthNav.vue'
import { workoutsInjectionKey } from '@/composables/injectionKeys'
import { useMonthCalendar } from '@/composables/useMonthCalendar'
import { todayKey } from '@/utils/dateKey'

const props = defineProps<{
  modelValue: string
}>()

const emit = defineEmits<{
  'update:modelValue': [dateKey: string]
}>()

const workouts = inject(workoutsInjectionKey)!
const today = todayKey()
const viewYear = ref(new Date().getFullYear())
const viewMonth = ref(new Date().getMonth())
const { monthLabel, cells } = useMonthCalendar(viewYear, viewMonth)
const cellKeys = computed(() => cells.value.keys)

watch(
  () => props.modelValue,
  (key) => {
    const [year, month] = key.split('-').map(Number)
    if (!year || !month) return
    viewYear.value = year
    viewMonth.value = month - 1
  },
  { immediate: true },
)

function changeMonth(delta: number) {
  let month = viewMonth.value + delta
  let year = viewYear.value
  if (month > 11) {
    month = 0
    year += 1
  }
  if (month < 0) {
    month = 11
    year -= 1
  }
  viewMonth.value = month
  viewYear.value = year
}
</script>

<template>
  <div>
    <MonthNav :label="monthLabel" @prev="changeMonth(-1)" @next="changeMonth(1)" />
    <div class="rounded-xl border border-border bg-card-inner p-3">
      <MonthGrid
        :cell-keys="cellKeys"
        :selected-key="modelValue"
        :today-key="today"
        :log="workouts.log.value"
        highlight-selection
        @pick="emit('update:modelValue', $event)"
      />
    </div>
  </div>
</template>
