import { computed, type Ref } from 'vue'
import { getDayExercises, isRestDayEntry, type WorkoutLog } from '@/types/workout'
import { MONTHS, WEEKDAYS } from '@/utils/dateKey'

export function useMonthCalendar(viewYear: Ref<number>, viewMonth: Ref<number>) {
  const monthLabel = computed(
    () => `${MONTHS[viewMonth.value]} ${viewYear.value}`,
  )

  const cells = computed(() => {
    const y = viewYear.value
    const m = viewMonth.value
    const firstDay = new Date(y, m, 1).getDay()
    const daysInMonth = new Date(y, m + 1, 0).getDate()
    const pad = (n: number) => String(n).padStart(2, '0')
    const keys: (string | null)[] = [
      ...Array.from({ length: firstDay }, () => null),
      ...Array.from({ length: daysInMonth }, (_, i) => {
        const d = i + 1
        return `${y}-${pad(m + 1)}-${pad(d)}`
      }),
    ]
    return { keys, daysInMonth, firstDay }
  })

  function trainedDaysInMonth(log: WorkoutLog): number {
    const { keys } = cells.value
    let n = 0
    for (const k of keys) {
      if (k && getDayExercises(log[k]).length > 0) n++
    }
    return n
  }

  function loggedRestDaysInMonth(log: WorkoutLog): number {
    const { keys } = cells.value
    let n = 0
    for (const k of keys) {
      if (k && isRestDayEntry(log[k])) n++
    }
    return n
  }

  /** Days that count toward consistency: workout logged or explicit rest day */
  function consistencyDaysInMonth(log: WorkoutLog): number {
    const { keys } = cells.value
    let n = 0
    for (const k of keys) {
      if (!k) continue
      const entry = log[k]
      if (getDayExercises(entry).length > 0 || isRestDayEntry(entry)) n++
    }
    return n
  }

  return {
    weekdays: WEEKDAYS,
    monthLabel,
    cells,
    trainedDaysInMonth,
    loggedRestDaysInMonth,
    consistencyDaysInMonth,
  }
}
