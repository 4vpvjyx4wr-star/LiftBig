import { ref, watch } from 'vue'
import { getDayExercises, type Exercise, type WorkoutDay, type WorkoutLog } from '@/types/workout'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
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
    const ex = getDayExercises(next[dateKey])
    const trimmed = notes.trim()
    if (ex.length === 0 && trimmed === '') {
      delete next[dateKey]
    } else if (trimmed === '') {
      next[dateKey] = ex
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

  return {
    log,
    flush,
    getDay,
    getDayNotesForDate,
    setDay,
    setDayNotes,
    appendExercises,
    deleteDay,
  }
}
