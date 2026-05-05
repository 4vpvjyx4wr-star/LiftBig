import { ref, watch } from 'vue'
import type { Exercise, WorkoutLog } from '@/types/workout'
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
    return log.value[dateKey] ?? []
  }

  function setDay(dateKey: string, exercises: Exercise[]) {
    const next = { ...log.value }
    if (exercises.length === 0) delete next[dateKey]
    else next[dateKey] = exercises
    log.value = next
  }

  function appendExercises(dateKey: string, exercises: Exercise[]) {
    const existing = log.value[dateKey] ?? []
    log.value = { ...log.value, [dateKey]: [...existing, ...exercises] }
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
    setDay,
    appendExercises,
    deleteDay,
  }
}
