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

const workouts = useLocalWorkouts()
const templates = useTemplates()
const settings = useSettings()
const libraryFavorites = useLibraryFavorites()

provide(workoutsInjectionKey, workouts)
provide(templatesInjectionKey, templates)
provide(settingsInjectionKey, settings)
provide(libraryFavoritesInjectionKey, libraryFavorites)

/** Workouts autosave is debounced; flush before the tab goes away so nothing is lost on close. */
function flushWorkoutsToDisk() {
  workouts.flush()
}

function onDocumentVisibilityChange() {
  if (document.visibilityState === 'hidden') flushWorkoutsToDisk()
}

onMounted(() => {
  if (typeof navigator !== 'undefined' && navigator.storage?.persist) {
    void navigator.storage.persist().catch(() => {})
  }
  window.addEventListener('pagehide', flushWorkoutsToDisk)
  document.addEventListener('visibilitychange', onDocumentVisibilityChange)
})

onBeforeUnmount(() => {
  window.removeEventListener('pagehide', flushWorkoutsToDisk)
  document.removeEventListener('visibilitychange', onDocumentVisibilityChange)
})
</script>

<template>
  <RouterView />
</template>
