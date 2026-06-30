<script setup lang="ts">
import { onBeforeUnmount, onMounted, provide } from 'vue'
import { RouterView } from 'vue-router'
import {
  workoutsInjectionKey,
  templatesInjectionKey,
  settingsInjectionKey,
  libraryFavoritesInjectionKey,
} from '@/composables/injectionKeys'
import { useLocalWorkouts } from '@/composables/useLocalWorkouts'
import { useLibraryFavorites } from '@/composables/useLibraryFavorites'
import { useTemplates } from '@/composables/useTemplates'
import { useSettings } from '@/composables/useSettings'
import { maybeFireDailyLiftNotification } from '@/utils/dailyLiftReminder'
import { clearBackupRestorePending, isBackupRestorePending } from '@/utils/liftbigBackup'

const workouts = useLocalWorkouts()
const templates = useTemplates()
const settings = useSettings()
const libraryFavorites = useLibraryFavorites()

provide(workoutsInjectionKey, workouts)
provide(templatesInjectionKey, templates)
provide(settingsInjectionKey, settings)
provide(libraryFavoritesInjectionKey, libraryFavorites)

let dailyReminderInterval: ReturnType<typeof setInterval> | null = null

function checkDailyLiftReminder() {
  maybeFireDailyLiftNotification(
    workouts.log.value,
    settings.dailyLiftReminderEnabled.value,
    settings.dailyLiftReminderTime.value,
  )
}

/** Workouts autosave is debounced; flush before the tab goes away so nothing is lost on close. */
function flushWorkoutsToDisk() {
  if (isBackupRestorePending()) return
  workouts.flush()
}

function onDocumentVisibilityChange() {
  if (document.visibilityState === 'hidden') flushWorkoutsToDisk()
}

onMounted(() => {
  clearBackupRestorePending()
  if (typeof navigator !== 'undefined' && navigator.storage?.persist) {
    void navigator.storage.persist().catch(() => {})
  }
  window.addEventListener('pagehide', flushWorkoutsToDisk)
  document.addEventListener('visibilitychange', onDocumentVisibilityChange)
  checkDailyLiftReminder()
  dailyReminderInterval = setInterval(checkDailyLiftReminder, 60_000)
})

onBeforeUnmount(() => {
  window.removeEventListener('pagehide', flushWorkoutsToDisk)
  document.removeEventListener('visibilitychange', onDocumentVisibilityChange)
  if (dailyReminderInterval) clearInterval(dailyReminderInterval)
})
</script>

<template>
  <RouterView />
</template>
