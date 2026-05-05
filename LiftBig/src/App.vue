<script setup lang="ts">
import { provide } from 'vue'
import { RouterView } from 'vue-router'
import {
  workoutsInjectionKey,
  templatesInjectionKey,
  settingsInjectionKey,
} from '@/composables/injectionKeys'
import { useLocalWorkouts } from '@/composables/useLocalWorkouts'
import { useTemplates } from '@/composables/useTemplates'
import { useSettings } from '@/composables/useSettings'

const workouts = useLocalWorkouts()
const templates = useTemplates()
const settings = useSettings()

provide(workoutsInjectionKey, workouts)
provide(templatesInjectionKey, templates)
provide(settingsInjectionKey, settings)
</script>

<template>
  <RouterView />
</template>
