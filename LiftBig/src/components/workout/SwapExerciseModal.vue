<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import LibraryBrowser from '@/components/library/LibraryBrowser.vue'
import type { Exercise } from '@/types/workout'
import { getComparableLibraryExercises, type LibraryExercise } from '@/utils/exerciseLibrary'

const props = defineProps<{
  show: boolean
  exercise: Exercise | null
}>()

const emit = defineEmits<{
  close: []
  pick: [exercise: LibraryExercise]
}>()

const similarSearchQuery = ref('')

watch(
  () => props.show,
  (open) => {
    if (open) similarSearchQuery.value = ''
  },
)

const comparables = computed(() =>
  props.exercise ? getComparableLibraryExercises(props.exercise) : [],
)

const filteredComparables = computed(() => {
  const q = similarSearchQuery.value.trim().toLowerCase()
  if (!q) return comparables.value
  return comparables.value.filter((ex) => {
    const hay = `${ex.name} ${ex.equipment ?? ''} ${(ex.tags ?? []).join(' ')}`.toLowerCase()
    return hay.includes(q)
  })
})

function onSelect(ex: LibraryExercise) {
  emit('pick', ex)
  emit('close')
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="show && exercise"
      class="fixed inset-0 z-[60] flex items-end justify-center bg-black/65 sm:items-center"
      role="dialog"
      aria-modal="true"
      aria-labelledby="swap-exercise-title"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-t-2xl border border-border bg-card p-4 sm:max-h-[85vh] sm:rounded-2xl"
        @click.stop
      >
        <h3 id="swap-exercise-title" class="text-lg font-extrabold text-foreground">
          Swap exercise
        </h3>
        <p class="mt-1 text-xs text-muted">
          Replace <span class="font-semibold text-foreground">{{ exercise.name }}</span>
          {{
            exercise.isCardio
              ? 'with another cardio activity. Duration stays the same.'
              : 'with a comparable movement. Sets stay the same; adjust weight if needed.'
          }}
        </p>

        <section v-if="comparables.length > 0" class="mt-4">
          <h4 class="text-[11px] font-bold uppercase tracking-wide text-muted">
            Similar movements
          </h4>
          <label class="mt-2 block">
            <span class="sr-only">Search similar movements</span>
            <input
              v-model="similarSearchQuery"
              type="search"
              placeholder="Search similar movements…"
              class="w-full rounded-lg border border-border bg-card-inner px-3 py-2.5 text-sm text-foreground placeholder:text-muted focus:border-primary focus:outline-none"
            />
          </label>
          <ul class="mt-2 space-y-1">
            <li v-for="ex in filteredComparables" :key="ex.id">
              <button
                type="button"
                class="flex w-full items-center justify-between rounded-lg border border-border bg-card-inner px-3 py-2.5 text-left text-sm font-semibold text-foreground hover:border-primary/60"
                @click="onSelect(ex)"
              >
                <span>{{ ex.name }}</span>
                <span class="ml-2 shrink-0 text-[11px] text-muted">{{ ex.equipment ?? '' }}</span>
              </button>
            </li>
            <li
              v-if="filteredComparables.length === 0"
              class="rounded-lg border border-dashed border-border px-3 py-2.5 text-sm text-muted"
            >
              No similar movements match “{{ similarSearchQuery.trim() }}”.
            </li>
          </ul>
        </section>

        <section class="mt-5">
          <h4 class="text-[11px] font-bold uppercase tracking-wide text-muted">
            All exercises
          </h4>
          <p class="mt-1 text-[11px] text-muted">
            Pick any library exercise if nothing similar fits.
          </p>
          <div class="mt-3">
            <LibraryBrowser @select-exercise="onSelect" />
          </div>
        </section>

        <button
          type="button"
          class="mt-4 w-full rounded-lg border border-border py-3 text-sm font-bold text-muted"
          @click="emit('close')"
        >
          Cancel
        </button>
      </div>
    </div>
  </Teleport>
</template>
