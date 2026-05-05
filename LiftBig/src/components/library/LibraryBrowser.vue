<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  MUSCLE_GROUPS,
  MUSCLE_GROUP_LABELS,
  searchLibrary,
  type LibraryExercise,
  type MuscleGroup,
} from '@/utils/exerciseLibrary'

const emit = defineEmits<{
  selectExercise: [exercise: LibraryExercise]
}>()

const searchQuery = ref('')
const selectedGroup = ref<MuscleGroup | 'all'>('all')

const filtered = computed(() =>
  searchLibrary(searchQuery.value, selectedGroup.value),
)

function setGroup(g: MuscleGroup | 'all') {
  selectedGroup.value = g
}
</script>

<template>
  <div>
    <label class="sr-only" for="library-search">Search exercises</label>
    <input
      id="library-search"
      v-model="searchQuery"
      type="search"
      class="w-full rounded-lg border border-border bg-card-inner px-3 py-2.5 text-sm text-foreground outline-none focus:border-primary"
      placeholder="Search by name, muscle, equipment…"
      autocomplete="off"
    />

    <div class="mt-3 flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      <button
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          selectedGroup === 'all'
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setGroup('all')"
      >
        All
      </button>
      <button
        v-for="g in MUSCLE_GROUPS"
        :key="g"
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          selectedGroup === g
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setGroup(g)"
      >
        {{ MUSCLE_GROUP_LABELS[g] }}
      </button>
    </div>

    <ul class="mt-4 space-y-2 pb-2">
      <li v-for="ex in filtered" :key="ex.id">
        <button
          type="button"
          class="flex w-full flex-col items-start rounded-xl border border-border bg-card-inner px-4 py-3 text-left hover:border-primary"
          @click="emit('selectExercise', ex)"
        >
          <div class="flex w-full items-start justify-between gap-2">
            <span class="font-bold text-foreground">{{ ex.name }}</span>
            <span v-if="ex.equipment" class="shrink-0 text-[10px] font-bold uppercase text-muted">
              {{ ex.equipment }}
            </span>
          </div>
          <div class="mt-2 flex flex-wrap gap-1">
            <span
              v-for="mg in ex.muscleGroups"
              :key="mg"
              class="rounded bg-background px-1.5 py-0.5 text-[10px] font-semibold text-muted"
            >
              {{ MUSCLE_GROUP_LABELS[mg] }}
            </span>
          </div>
        </button>
      </li>
    </ul>

    <p v-if="filtered.length === 0" class="py-8 text-center text-sm text-muted">
      No exercises match your filters.
    </p>
  </div>
</template>
