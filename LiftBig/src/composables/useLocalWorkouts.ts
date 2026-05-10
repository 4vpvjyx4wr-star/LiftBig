import { ref, watch } from 'vue'
import {
  getDayExercises,
  isRestDayEntry,
  type Exercise,
  type WorkoutDay,
  type WorkoutLog,
  type WorkoutTemplate,
} from '@/types/workout'
import { addDaysToDateKey, endOfMonthKeyFor } from '@/utils/dateKey'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { cloneTemplateToExercises } from '@/utils/templateToLog'
import { loadJson, saveJson } from '@/utils/storage'

const KEY = LIFTBIG_STORAGE_KEYS.workouts
const DEBOUNCE_MS = 400

export function useLocalWorkouts() {
  const log = ref<WorkoutLog>(loadJson<WorkoutLog>(KEY, {}))
  let timer: ReturnType<typeof setTimeout> | null = null

  function persist() {
    saveJson(KEY, log.value)
  }

  function schedulePersist() {
    if (timer) clearTimeout(timer)
    timer = setTimeout(() => {
      persist()
      timer = null
    }, DEBOUNCE_MS)
  }

  watch(log, schedulePersist, { deep: true })

  function flush() {
    if (timer) {
      clearTimeout(timer)
      timer = null
    }
    persist()
  }

  function dayNotes(entry: WorkoutLog[string] | undefined): string | undefined {
    if (entry && typeof entry === 'object' && !Array.isArray(entry)) {
      const n = (entry as WorkoutDay).notes
      if (typeof n === 'string' && n.length > 0) return n
    }
    return undefined
  }

  function getDay(dateKey: string): Exercise[] {
    return getDayExercises(log.value[dateKey])
  }

  function getDayNotesForDate(dateKey: string): string {
    const entry = log.value[dateKey]
    if (entry && typeof entry === 'object' && !Array.isArray(entry)) {
      const n = (entry as WorkoutDay).notes
      return typeof n === 'string' ? n : ''
    }
    return ''
  }

  function setDay(dateKey: string, exercises: Exercise[]) {
    const next = { ...log.value }
    const preservedNotes = dayNotes(next[dateKey])
    if (exercises.length === 0) {
      delete next[dateKey]
    } else if (preservedNotes !== undefined) {
      next[dateKey] = { exercises, notes: preservedNotes }
    } else {
      next[dateKey] = exercises
    }
    log.value = next
  }

  function setDayNotes(dateKey: string, notes: string) {
    const next = { ...log.value }
    const entry = next[dateKey]
    const ex = getDayExercises(entry)
    const trimmed = notes.trim()
    const rest = isRestDayEntry(entry)

    if (ex.length === 0 && trimmed === '' && !rest) {
      delete next[dateKey]
    } else if (trimmed === '') {
      if (rest) {
        next[dateKey] = { exercises: [], isRestDay: true }
      } else {
        next[dateKey] = ex
      }
    } else if (rest && ex.length === 0) {
      next[dateKey] = { exercises: [], isRestDay: true, notes }
    } else {
      next[dateKey] = { exercises: ex, notes }
    }
    log.value = next
  }

  function appendExercises(dateKey: string, exercises: Exercise[]) {
    const existing = getDayExercises(log.value[dateKey])
    const preservedNotes = dayNotes(log.value[dateKey])
    log.value = {
      ...log.value,
      [dateKey]:
        preservedNotes !== undefined
          ? { exercises: [...existing, ...exercises], notes: preservedNotes }
          : [...existing, ...exercises],
    }
  }

  function deleteDay(dateKey: string) {
    const next = { ...log.value }
    delete next[dateKey]
    log.value = next
    flush()
  }

  function isRestDay(dateKey: string): boolean {
    return isRestDayEntry(log.value[dateKey])
  }

  function markRestDay(dateKey: string) {
    const next = { ...log.value }
    const preservedNotes = dayNotes(next[dateKey])
    next[dateKey] =
      preservedNotes !== undefined
        ? { exercises: [], isRestDay: true, notes: preservedNotes }
        : { exercises: [], isRestDay: true }
    log.value = next
    flush()
  }

  /** Apply template starting at `startDateKey`. If `restDaysPerWeek` is 0, only that day gets the plan. Otherwise each 7-day block through month end gets training days filled and rest slots marked (empty days only). */
  function applyPlanWithWeeklyRest(
    startDateKey: string,
    template: WorkoutTemplate,
    restDaysPerWeek: number,
  ) {
    const r = Math.min(6, Math.max(0, Math.round(restDaysPerWeek)))
    if (r === 0) {
      appendExercises(startDateKey, cloneTemplateToExercises(template))
      flush()
      return
    }

    let next = { ...log.value }
    const endKey = endOfMonthKeyFor(startDateKey)
    let current = startDateKey
    let offset = 0
    const trainingSlots = Math.max(0, 7 - r)

    while (current <= endKey) {
      const pos = offset % 7
      const entry = next[current]
      const hasEx = getDayExercises(entry).length > 0
      const rest = isRestDayEntry(entry)
      if (!hasEx && !rest) {
        const preservedNotes = dayNotes(entry)
        if (pos < trainingSlots) {
          const added = cloneTemplateToExercises(template)
          next[current] =
            preservedNotes !== undefined
              ? { exercises: added, notes: preservedNotes }
              : added
        } else {
          next[current] =
            preservedNotes !== undefined
              ? { exercises: [], isRestDay: true, notes: preservedNotes }
              : { exercises: [], isRestDay: true }
        }
      }
      current = addDaysToDateKey(current, 1)
      offset++
    }

    log.value = next
    flush()
  }

  return {
    log,
    flush,
    getDay,
    getDayNotesForDate,
    setDay,
    setDayNotes,
    appendExercises,
    deleteDay,
    isRestDay,
    markRestDay,
    applyPlanWithWeeklyRest,
  }
}
