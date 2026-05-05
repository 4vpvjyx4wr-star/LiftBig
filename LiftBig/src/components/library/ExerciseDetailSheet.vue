<script setup lang="ts">
import { computed, inject } from 'vue'
import {
  libraryFavoritesInjectionKey,
  workoutsInjectionKey,
} from '@/composables/injectionKeys'
import type { LibraryExercise } from '@/utils/exerciseLibrary'
import { MUSCLE_GROUP_LABELS } from '@/utils/exerciseLibrary'
import { hasUserLoggedLibraryExercise } from '@/utils/libraryExerciseTracking'

const props = defineProps<{
  open: boolean
  exercise: LibraryExercise | null
}>()

const emit = defineEmits<{
  close: []
}>()

const workouts = inject(workoutsInjectionKey)!
const favorites = inject(libraryFavoritesInjectionKey)!

const isLogged = computed(() =>
  props.exercise ? hasUserLoggedLibraryExercise(workouts.log.value, props.exercise) : false,
)

function toggleFavorite() {
  if (!props.exercise) return
  favorites.toggle(props.exercise.id)
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open && exercise"
      class="fixed inset-0 z-50 flex flex-col justify-end bg-black/65"
      role="dialog"
      aria-modal="true"
      aria-labelledby="exercise-detail-title"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[85vh] overflow-y-auto rounded-t-2xl border border-border border-b-0 bg-card px-4 pb-8 pt-2"
        @click.stop
      >
        <div class="mx-auto mb-3 h-1 w-10 rounded-full bg-border" />
        <button
          type="button"
          class="mb-2 text-xs font-bold text-muted hover:text-primary"
          @click="emit('close')"
        >
          Close
        </button>

        <div class="flex flex-wrap items-start justify-between gap-2">
          <h3 id="exercise-detail-title" class="text-xl font-extrabold text-foreground">
            {{ exercise.name }}
          </h3>
          <div class="flex shrink-0 items-center gap-2">
            <span
              v-if="isLogged"
              class="inline-flex items-center gap-1 rounded-full border border-green-600/40 bg-green-500/10 px-2.5 py-1 text-[11px] font-bold text-green-500"
            >
              <i class="fa-solid fa-circle-check" aria-hidden="true" />
              Logged
            </span>
            <button
              type="button"
              class="inline-flex items-center gap-1.5 rounded-full border border-border bg-card-inner px-3 py-1.5 text-[11px] font-bold text-foreground hover:border-primary"
              :class="favorites.isFavorite(exercise.id) ? 'border-amber-500/50' : ''"
              :aria-pressed="favorites.isFavorite(exercise.id)"
              @click="toggleFavorite"
            >
              <i
                class="fa-solid fa-star"
                :class="favorites.isFavorite(exercise.id) ? 'text-amber-400' : 'text-muted'"
                aria-hidden="true"
              />
              {{ favorites.isFavorite(exercise.id) ? 'Favorited' : 'Favorite' }}
            </button>
          </div>
        </div>

        <p v-if="exercise.equipment" class="mt-1 text-sm text-muted">{{ exercise.equipment }}</p>
        <p class="mt-3 text-sm leading-relaxed text-foreground">{{ exercise.summary }}</p>

        <div class="mt-3 flex flex-wrap gap-1.5">
          <span
            v-for="g in exercise.muscleGroups"
            :key="g"
            class="rounded-full border border-border bg-card-inner px-2.5 py-0.5 text-[11px] font-bold text-muted"
          >
            {{ MUSCLE_GROUP_LABELS[g] }}
          </span>
          <span
            v-for="tag in exercise.tags ?? []"
            :key="tag"
            class="rounded-full border border-primary/40 bg-primary/15 px-2.5 py-0.5 text-[11px] font-bold text-primary"
          >
            {{ tag }}
          </span>
        </div>

        <h4 class="mt-6 text-xs font-bold uppercase tracking-wide text-muted">How to perform</h4>
        <ol class="mt-2 list-decimal space-y-2 pl-5 text-sm text-foreground">
          <li v-for="(step, i) in exercise.instructions" :key="i" class="leading-relaxed">
            {{ step }}
          </li>
        </ol>

        <template v-if="exercise.tips?.length">
          <h4 class="mt-6 text-xs font-bold uppercase tracking-wide text-muted">Tips</h4>
          <ul class="mt-2 space-y-2 text-sm text-foreground">
            <li v-for="(tip, i) in exercise.tips" :key="i" class="flex gap-2 leading-relaxed">
              <span class="shrink-0 text-primary">·</span>
              <span>{{ tip }}</span>
            </li>
          </ul>
        </template>
      </div>
    </div>
  </Teleport>
</template>
