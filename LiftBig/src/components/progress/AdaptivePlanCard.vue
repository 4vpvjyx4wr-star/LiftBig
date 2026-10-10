<script setup lang="ts">
import { computed, inject } from 'vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import { usePro } from '@/composables/usePro'
import { suggestNextSession } from '@/utils/adaptivePlanning'
import { formatWeightFromLbs } from '@/utils/units'

const workouts = inject(workoutsInjectionKey)!
const settings = inject(settingsInjectionKey)!
const { active: proActive } = usePro()

const suggestions = computed(() => (proActive.value ? suggestNextSession(workouts.log.value) : []))
</script>

<template>
  <section
    v-if="proActive && suggestions.length > 0"
    class="mb-4 rounded-xl border border-border bg-card px-4 py-3"
  >
    <h2 class="text-sm font-extrabold text-foreground">Next session</h2>
    <p class="mt-0.5 text-xs leading-snug text-muted">
      Suggestions from your logged sets. They stay on this phone.
    </p>
    <ul class="mt-3 space-y-2">
      <li v-for="item in suggestions" :key="item.exerciseName">
        <p class="text-sm font-bold text-foreground">{{ item.exerciseName }}</p>
        <p class="text-xs text-muted">
          {{ item.suggestedReps }} reps ·
          {{ formatWeightFromLbs(item.suggestedWeightLbs, settings.weightUnit.value) }}
          {{ settings.weightUnit.value }}
        </p>
        <p class="text-[11px] leading-snug text-muted">{{ item.reason }}</p>
      </li>
    </ul>
  </section>
</template>
