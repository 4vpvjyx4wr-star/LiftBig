<script setup lang="ts">
import { provide } from 'vue'
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
</script>

<template>
  <RouterView />
</template>
