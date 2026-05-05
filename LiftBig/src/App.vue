<script setup lang="ts">
import { provide } from 'vue'
import { RouterView } from 'vue-router'
import { workoutsInjectionKey, templatesInjectionKey } from '@/composables/injectionKeys'
import { useLocalWorkouts } from '@/composables/useLocalWorkouts'
import { useTemplates } from '@/composables/useTemplates'

const workouts = useLocalWorkouts()
const templates = useTemplates()

provide(workoutsInjectionKey, workouts)
provide(templatesInjectionKey, templates)
</script>

<template>
  <RouterView />
</template>
