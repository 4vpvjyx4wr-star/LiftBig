<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import ExerciseDetailSheet from '@/components/library/ExerciseDetailSheet.vue'
import LibraryBrowser from '@/components/library/LibraryBrowser.vue'
import type { LibraryExercise } from '@/utils/exerciseLibrary'

const detailOpen = ref(false)
const selected = ref<LibraryExercise | null>(null)

function openDetail(ex: LibraryExercise) {
  selected.value = ex
  detailOpen.value = true
}

function closeDetail() {
  detailOpen.value = false
  selected.value = null
}
</script>

<template>
  <div>
    <header class="mb-4 border-b border-border pb-3">
      <RouterLink to="/plans" class="mb-2 inline-block text-xs font-bold text-muted hover:text-primary">
        ← Plans
      </RouterLink>
      <h1 class="text-3xl font-black tracking-[0.2em] text-primary">LIFTBIG</h1>
      <p class="text-[10px] font-bold tracking-[0.2em] text-muted">Exercise library</p>
    </header>

    <p class="mb-4 text-sm text-muted">
      Browse by muscle group or search. Tap an exercise for step-by-step form cues.
    </p>

    <LibraryBrowser @select-exercise="openDetail" />

    <ExerciseDetailSheet :open="detailOpen" :exercise="selected" @close="closeDetail" />
  </div>
</template>
