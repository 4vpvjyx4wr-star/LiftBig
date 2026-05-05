<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import ExerciseDetailSheet from '@/components/library/ExerciseDetailSheet.vue'
import LibraryBrowser from '@/components/library/LibraryBrowser.vue'
import type { LibraryExercise } from '@/utils/exerciseLibrary'

const detailOpen = ref(false)
const selected = ref<LibraryExercise | null>(null)

const libraryScope = ref<'all' | 'favorites' | 'logged'>('all')

function openDetail(ex: LibraryExercise) {
  selected.value = ex
  detailOpen.value = true
}

function closeDetail() {
  detailOpen.value = false
  selected.value = null
}

function setScope(s: 'all' | 'favorites' | 'logged') {
  libraryScope.value = s
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

    <p class="mb-3 text-sm text-muted">
      Browse by muscle group or search names, tags, and equipment. A green check means you have logged
      that lift before. Star any exercise to favorite it.
    </p>

    <div class="mb-4 flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      <button
        type="button"
        class="shrink-0 rounded-full border px-3 py-2 text-[11px] font-bold tracking-wide"
        :class="
          libraryScope === 'all'
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setScope('all')"
      >
        All exercises
      </button>
      <button
        type="button"
        class="shrink-0 rounded-full border px-3 py-2 text-[11px] font-bold tracking-wide"
        :class="
          libraryScope === 'favorites'
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setScope('favorites')"
      >
        <i class="fa-solid fa-star mr-1 text-[10px]" aria-hidden="true" />
        Favorites
      </button>
      <button
        type="button"
        class="shrink-0 rounded-full border px-3 py-2 text-[11px] font-bold tracking-wide"
        :class="
          libraryScope === 'logged'
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setScope('logged')"
      >
        <i class="fa-solid fa-circle-check mr-1 text-[10px]" aria-hidden="true" />
        Logged before
      </button>
    </div>

    <LibraryBrowser :scope="libraryScope" @select-exercise="openDetail" />

    <ExerciseDetailSheet :open="detailOpen" :exercise="selected" @close="closeDetail" />
  </div>
</template>
