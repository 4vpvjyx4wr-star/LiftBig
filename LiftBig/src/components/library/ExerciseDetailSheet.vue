<script setup lang="ts">
import type { LibraryExercise } from '@/utils/exerciseLibrary'
import { MUSCLE_GROUP_LABELS } from '@/utils/exerciseLibrary'

defineProps<{
  open: boolean
  exercise: LibraryExercise | null
}>()

const emit = defineEmits<{
  close: []
}>()
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

        <h3 id="exercise-detail-title" class="text-xl font-extrabold text-foreground">
          {{ exercise.name }}
        </h3>
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
