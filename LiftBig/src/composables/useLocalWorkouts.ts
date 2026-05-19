import { ref, watch } from 'vue'
import {
  getDayExercises,
  getDayPlanFolderName,
  getDayPlanName,
  getDayPlanNotes,
  isRestDayEntry,
  type Exercise,
  type WorkoutDay,
  type WorkoutLog,
  type WorkoutTemplate,
} from '@/types/workout'
import { addDaysToDateKey, endOfMonthKeyFor } from '@/utils/dateKey'
import { LIFTBIG_STORAGE_KEYS } from '@/utils/liftbigStorageKeys'
import { applyPredictedGoalsToExercises } from '@/utils/progressiveOverload'
import { cloneExercisesForCopy, cloneTemplateToExercises } from '@/utils/templateToLog'
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

  function getPlanName(dateKey: string): string | undefined {
    return getDayPlanName(log.value[dateKey])
  }

  function getPlanFolderName(dateKey: string): string | undefined {
    return getDayPlanFolderName(log.value[dateKey])
  }

  function getPlanNotes(dateKey: string): string | undefined {
    return getDayPlanNotes(log.value[dateKey])
  }

  /** Assign a plan template to a calendar day (merges exercises; sets plan name, folder, and coaching notes). */
  function assignPlanToDate(dateKey: string, template: WorkoutTemplate, folderName?: string) {
    const existing = getDayExercises(log.value[dateKey])
    const preservedNotes = dayNotes(log.value[dateKey])
    const entry: WorkoutDay = {
      exercises: [...existing, ...cloneTemplateToExercises(template)],
      planName: template.name,
    }
    if (folderName) entry.planFolderName = folderName
    if (template.notes?.trim()) entry.planNotes = template.notes.trim()
    if (preservedNotes !== undefined) entry.notes = preservedNotes
    log.value = { ...log.value, [dateKey]: entry }
    flush()
  }

  /** Apply template starting at `startDateKey`. If `restDaysPerWeek` is 0, only that day gets the plan. Otherwise each 7-day block through month end gets training days filled and rest slots marked (empty days only). */
  function applyPlanWithWeeklyRest(
    startDateKey: string,
    template: WorkoutTemplate,
    restDaysPerWeek: number,
    folderName?: string,
  ) {
    const r = Math.min(6, Math.max(0, Math.round(restDaysPerWeek)))
    if (r === 0) {
      const existing = getDayExercises(log.value[startDateKey])
      const preservedNotes = dayNotes(log.value[startDateKey])
      const added = cloneTemplateToExercises(template)
      const entry: WorkoutDay = {
        exercises: [...existing, ...added],
        planName: template.name,
      }
      if (folderName) entry.planFolderName = folderName
      if (template.notes?.trim()) entry.planNotes = template.notes.trim()
      if (preservedNotes !== undefined) entry.notes = preservedNotes
      log.value = { ...log.value, [startDateKey]: entry }
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
          const dayEntry: WorkoutDay = {
            exercises: added,
            planName: template.name,
          }
          if (folderName) dayEntry.planFolderName = folderName
          if (template.notes?.trim()) dayEntry.planNotes = template.notes.trim()
          if (preservedNotes !== undefined) dayEntry.notes = preservedNotes
          next[current] = dayEntry
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

  function moveDay(fromKey: string, toKey: string) {
    const next = { ...log.value }
    const fromEntry = next[fromKey]
    if (fromEntry === undefined) return
    next[toKey] = fromEntry
    delete next[fromKey]
    log.value = next
    flush()
  }

  function swapDays(keyA: string, keyB: string) {
    const next = { ...log.value }
    const entryA = next[keyA]
    const entryB = next[keyB]
    if (entryA !== undefined) next[keyB] = entryA
    else delete next[keyB]
    if (entryB !== undefined) next[keyA] = entryB
    else delete next[keyA]
    log.value = next
    flush()
  }

  /** Copy exercises (goals + set structure, empty working sets) from one day onto another. Source day is unchanged. */
  function copyExercisesToDay(fromKey: string, toKey: string) {
    const source = getDayExercises(log.value[fromKey])
    if (source.length === 0) return
    const cloned = cloneExercisesForCopy(source)
    applyPredictedGoalsToExercises(cloned, log.value, toKey, { refreshFromHistory: true })
    const next = { ...log.value }
    const existing = getDayExercises(next[toKey])
    const preservedNotes = dayNotes(next[toKey])
    const merged = [...existing, ...cloned]
    if (preservedNotes !== undefined) {
      next[toKey] = { exercises: merged, notes: preservedNotes }
    } else {
      next[toKey] = merged
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
    getPlanName,
    getPlanFolderName,
    getPlanNotes,
    assignPlanToDate,
    applyPlanWithWeeklyRest,
    moveDay,
    swapDays,
    copyExercisesToDay,
  }
}
