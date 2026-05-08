import { ref, watch } from 'vue'
import { getDayExercises, getDayNotes, type Exercise, type WorkoutLog } from '@/types/workout'
import { LIFTBIG_LEGACY_STORAGE_KEY_ALIASES, LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { loadJsonWithRecovery, saveJson } from '@/utils/storage'

const KEY = LIFTBIG_STORAGE_KEYS.workouts
const DEBOUNCE_MS = 400

export function useLocalWorkouts() {
  const log = ref<WorkoutLog>(
    loadJsonWithRecovery<WorkoutLog>(KEY, {}, {
      legacyKeys: LIFTBIG_LEGACY_STORAGE_KEY_ALIASES.workouts,
    }),
  )
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

  function getDay(dateKey: string): Exercise[] {
    return getDayExercises(log.value[dateKey])
  }

  function getDayNotesForDate(dateKey: string): string {
    return getDayNotes(log.value[dateKey])
  }

  function setDay(dateKey: string, exercises: Exercise[]) {
    const next = { ...log.value }
    const existingNotes = getDayNotes(next[dateKey])
    if (exercises.length === 0 && !existingNotes.trim()) delete next[dateKey]
    else next[dateKey] = { exercises, notes: existingNotes }
    log.value = next
  }

  function setDayNotes(dateKey: string, notes: string) {
    const next = { ...log.value }
    const existingExercises = getDayExercises(next[dateKey])
    const trimmedNotes = notes.trim()
    if (existingExercises.length === 0 && !trimmedNotes) {
      delete next[dateKey]
      log.value = next
      return
    }
    next[dateKey] = { exercises: existingExercises, notes }
    log.value = next
  }

  function appendExercises(dateKey: string, exercises: Exercise[]) {
    const existing = getDayExercises(log.value[dateKey])
    const notes = getDayNotes(log.value[dateKey])
    log.value = { ...log.value, [dateKey]: { exercises: [...existing, ...exercises], notes } }
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
