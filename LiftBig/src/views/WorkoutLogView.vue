<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import LibraryPickerModal from '@/components/library/LibraryPickerModal.vue'
import ExerciseCard from '@/components/workout/ExerciseCard.vue'
import RestTimer from '@/components/workout/RestTimer.vue'
import { workoutsInjectionKey } from '@/composables/injectionKeys'
import type { Exercise } from '@/types/workout'
import { formatDisplayDate } from '@/utils/dateKey'
import { searchLibrary, type LibraryExercise } from '@/utils/exerciseLibrary'

const route = useRoute()
const router = useRouter()
const workouts = inject(workoutsInjectionKey)!

const dateKey = computed(() => {
  const d = route.params.date
  const s = Array.isArray(d) ? d[0] : d
  return s ?? ''
})

const exercises = ref<Exercise[]>([])
const inputName = ref('')
const libraryOpen = ref(false)
const showInlineLibraryMatches = ref(false)

const inlineLibraryMatches = computed(() => {
  const needle = inputName.value.trim()
  if (!needle) return []
  return searchLibrary(needle, 'all').slice(0, 5)
})

function loadDay() {
  const k = dateKey.value
  if (!k) return
  exercises.value = JSON.parse(JSON.stringify(workouts.getDay(k))) as Exercise[]
}

watch(dateKey, loadDay, { immediate: true })

watch(
  exercises,
  (list) => {
    const k = dateKey.value
    if (!k) return
    workouts.setDay(k, JSON.parse(JSON.stringify(list)) as Exercise[])
  },
  { deep: true },
)

const workoutLogPlain = computed(() => workouts.log.value)

function newId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 11)}`
}

function addExercise() {
  const trimmed = inputName.value.trim()
  if (!trimmed) {
    window.alert('Please enter an exercise name.')
    return
  }
  exercises.value = [
    ...exercises.value,
    {
      id: newId(),
      name: trimmed,
      sets: [{ id: newId(), reps: '', weight: '' }],
    },
  ]
  inputName.value = ''
}

function addFromLibrary(ex: LibraryExercise) {
  exercises.value = [
    ...exercises.value,
    {
      id: newId(),
      name: ex.name,
      libraryId: ex.id,
      sets: [{ id: newId(), reps: '', weight: '' }],
    },
  ]
}

function addFromInlineLibrary(ex: LibraryExercise) {
  addFromLibrary(ex)
  inputName.value = ''
  showInlineLibraryMatches.value = false
}

function hideInlineLibraryMatchesSoon() {
  window.setTimeout(() => {
    showInlineLibraryMatches.value = false
  }, 120)
}

function addSet(exerciseId: string) {
  exercises.value = exercises.value.map((ex) =>
    ex.id === exerciseId
      ? { ...ex, sets: [...ex.sets, { id: newId(), reps: '', weight: '' }] }
      : ex,
  )
}

function updateSet(exerciseId: string, setId: string, field: 'reps' | 'weight', value: string) {
  exercises.value = exercises.value.map((ex) => {
    if (ex.id !== exerciseId) return ex
    return {
      ...ex,
      sets: ex.sets.map((s) => (s.id === setId ? { ...s, [field]: value } : s)),
    }
  })
}

function toggleCircuitSet(exerciseId: string, setId: string) {
  exercises.value = exercises.value.map((ex) => {
    if (ex.id !== exerciseId) return ex
    return {
      ...ex,
      sets: ex.sets.map((s) => (s.id === setId ? { ...s, checked: !s.checked } : s)),
    }
  })
}

function deleteSet(exerciseId: string, setId: string) {
  exercises.value = exercises.value.map((ex) =>
    ex.id !== exerciseId ? ex : { ...ex, sets: ex.sets.filter((s) => s.id !== setId) },
  )
}

function deleteExercise(exerciseId: string) {
  exercises.value = exercises.value.filter((ex) => ex.id !== exerciseId)
}

function finish() {
  const total = exercises.value.reduce((acc, ex) => acc + ex.sets.length, 0)
  const ok = window.confirm(
    `Save and finish?\n\n${exercises.value.length} exercise(s), ${total} sets for ${formatDisplayDate(dateKey.value)}.`,
  )
  if (!ok) return
  workouts.flush()
  router.push('/')
}
</script>

<template>
  <div class="min-h-full bg-background pb-8">
    <header
      class="flex items-start justify-between gap-2 border-b border-border px-4 pb-3 pt-4"
    >
      <div>
        <RouterLink to="/" class="mb-2 inline-block text-xs font-bold text-muted hover:text-primary">
          ← Home
        </RouterLink>
        <h1 class="text-3xl font-black tracking-[0.2em] text-primary">LIFTBIG</h1>
        <p class="text-xs text-muted">{{ formatDisplayDate(dateKey) }}</p>
      </div>
      <div class="flex flex-col items-end gap-2">
        <RouterLink
          to="/library"
          class="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-border text-muted hover:border-primary hover:text-primary"
          aria-label="Open exercise library"
        >
          <i class="fa-solid fa-book text-sm" aria-hidden="true" />
        </RouterLink>
        <RestTimer />
      </div>
    </header>

    <div class="px-4 pb-above-workout-dock pt-4">
      <div v-if="exercises.length === 0" class="py-16 text-center">
        <p class="text-lg font-bold text-foreground">No exercises yet.</p>
        <p class="mt-2 text-sm text-muted">Add one below or assign a plan from Home.</p>
      </div>

      <ExerciseCard
        v-for="ex in exercises"
        :key="ex.id"
        :exercise="ex"
        :workout-log="workoutLogPlain"
        @add-set="addSet(ex.id)"
        @update-set="(setId, field, v) => updateSet(ex.id, setId, field, v)"
        @toggle-circuit-set="(setId) => toggleCircuitSet(ex.id, setId)"
        @delete-set="(setId) => deleteSet(ex.id, setId)"
        @delete-exercise="deleteExercise(ex.id)"
      />
    </div>

    <div
      class="fixed bottom-0 left-0 right-0 border-t border-border bg-background/95 pb-workout-dock-safe pt-3 backdrop-blur-sm"
    >
      <div class="mx-auto flex max-w-lg gap-2">
        <div class="relative min-w-0 flex-1">
          <input
            v-model="inputName"
            type="text"
            class="min-w-0 w-full rounded-lg border border-border bg-card px-3 py-2.5 text-foreground outline-none focus:border-primary"
            placeholder="Add exercise manually..."
            @focus="showInlineLibraryMatches = true"
            @blur="hideInlineLibraryMatchesSoon"
            @keydown.enter="addExercise"
          />
          <div
            v-if="showInlineLibraryMatches && inlineLibraryMatches.length > 0"
            class="absolute bottom-full left-0 right-0 z-20 mb-1 rounded-lg border border-border bg-card p-1 shadow-lg"
          >
            <button
              v-for="match in inlineLibraryMatches"
              :key="match.id"
              type="button"
              class="block w-full rounded-md px-3 py-2 text-left text-sm text-foreground hover:bg-card-inner"
              @click="addFromInlineLibrary(match)"
            >
              <span class="font-semibold">{{ match.name }}</span>
              <span class="ml-2 text-xs text-muted">{{ match.equipment ?? 'Exercise' }}</span>
            </button>
          </div>
        </div>
        <button
          type="button"
          class="shrink-0 rounded-lg border border-primary/50 bg-card-inner px-3 py-2.5 text-xs font-bold text-primary sm:px-4"
          @click="libraryOpen = true"
        >
          Library
        </button>
        <button
          type="button"
          class="shrink-0 rounded-lg bg-blue px-5 py-2.5 font-bold text-foreground"
          @click="addExercise"
        >
          Add
        </button>
      </div>
      <button
        v-if="exercises.length > 0"
        type="button"
        class="mx-auto mt-3 flex w-full max-w-lg justify-center rounded-xl bg-primary py-3.5 text-base font-extrabold tracking-wide text-foreground"
        @click="finish"
      >
        Finish Workout
      </button>
    </div>

    <LibraryPickerModal
      :show="libraryOpen"
      @close="libraryOpen = false"
      @pick="addFromLibrary"
    />
  </div>
</template>
