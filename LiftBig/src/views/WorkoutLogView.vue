<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import SettingsSheet from '@/components/layout/SettingsSheet.vue'
import LibraryPickerModal from '@/components/library/LibraryPickerModal.vue'
import ExerciseCard from '@/components/workout/ExerciseCard.vue'
import RestTimer from '@/components/workout/RestTimer.vue'
import { settingsInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import type { Exercise } from '@/types/workout'
import { formatDisplayDate } from '@/utils/dateKey'
import { searchLibrary, type LibraryExercise } from '@/utils/exerciseLibrary'
import {
  applyLiftBigBackupToStorage,
  collectLiftBigBackupPayload,
  downloadLiftBigBackupJson,
  parseLiftBigBackupJson,
} from '@/utils/liftbigBackup'

const route = useRoute()
const router = useRouter()
const workouts = inject(workoutsInjectionKey)!
const settings = inject(settingsInjectionKey)!

const dateKey = computed(() => {
  const d = route.params.date
  const s = Array.isArray(d) ? d[0] : d
  return s ?? ''
})

const exercises = ref<Exercise[]>([])
const notes = ref('')
const inputName = ref('')
const libraryOpen = ref(false)
const showInlineLibraryMatches = ref(false)
const menuOpen = ref(false)
const settingsOpen = ref(false)

const inlineLibraryMatches = computed(() => {
  const needle = inputName.value.trim()
  if (!needle) return []
  return searchLibrary(needle, 'all').slice(0, 5)
})

function loadDay() {
  const k = dateKey.value
  if (!k) return
  exercises.value = JSON.parse(JSON.stringify(workouts.getDay(k))) as Exercise[]
  notes.value = workouts.getDayNotesForDate(k)
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

watch(notes, (value) => {
  const k = dateKey.value
  if (!k) return
  workouts.setDayNotes(k, value)
})

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

function closeMenu() {
  menuOpen.value = false
}

function openSettingsFromMenu() {
  settingsOpen.value = true
  menuOpen.value = false
}

function onExportBackup() {
  workouts.flush()
  downloadLiftBigBackupJson(collectLiftBigBackupPayload())
}

async function onImportBackup(file: File) {
  let text: string
  try {
    text = await file.text()
  } catch {
    window.alert('Could not read that file.')
    return
  }

  const parsed = parseLiftBigBackupJson(text)
  if (!parsed.ok) {
    window.alert(parsed.error)
    return
  }

  const ok = window.confirm(
    'Replace all LiftBig data on this device with this backup?\n\nCurrent workouts, plans, and settings will be overwritten.',
  )
  if (!ok) return

  workouts.flush()
  applyLiftBigBackupToStorage(parsed.data)
  settingsOpen.value = false
  window.location.reload()
}

const sheetTheme = computed(() => settings.theme.value)
const sheetWeightUnit = computed(() => settings.weightUnit.value)
const sheetAverageRestSeconds = computed(() => settings.averageRestSeconds.value)
const sheetAverageLiftSeconds = computed(() => settings.averageLiftSeconds.value)
</script>

<template>
  <div class="min-h-full bg-background pb-8">
    <Teleport to="body">
      <div
        v-if="menuOpen"
        class="fixed inset-0 z-20 bg-black/50"
        aria-hidden="true"
        @click="closeMenu"
      />
    </Teleport>

    <header
      class="sticky top-0 z-30 grid grid-cols-3 items-start gap-2 border-b border-border bg-background/95 px-4 pb-3 pt-4 backdrop-blur-sm"
    >
      <div>
        <RouterLink to="/" class="mb-2 inline-block text-xs font-bold text-muted hover:text-primary">
          ← Home
        </RouterLink>
        <h1 class="text-3xl font-black tracking-[0.2em] text-primary">LIFTBIG</h1>
        <p class="text-xs text-muted">{{ formatDisplayDate(dateKey) }}</p>
      </div>

      <div class="flex justify-center pt-1">
        <RestTimer />
      </div>

      <div class="flex flex-col items-end gap-2">
        <div class="relative">
          <button
            type="button"
            class="flex h-9 w-9 items-center justify-center rounded-lg border border-border bg-card text-foreground"
            :aria-expanded="menuOpen"
            aria-controls="workout-menu"
            aria-label="Open menu"
            @click="menuOpen = !menuOpen"
          >
            <i class="fa-solid fa-bars text-sm" aria-hidden="true" />
          </button>
          <div
            v-if="menuOpen"
            id="workout-menu"
            class="absolute right-0 z-50 mt-2 w-[13rem] rounded-2xl border border-border bg-card-inner py-1 shadow-xl"
            role="menu"
            @click.stop
          >
            <RouterLink v-slot="{ navigate, isActive }" to="/plates" custom>
              <button
                type="button"
                role="menuitem"
                class="flex w-full items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
                :class="{ '!text-primary': isActive }"
                @click="closeMenu(); navigate($event)"
              >
                <i class="fa-solid fa-weight-hanging w-5 text-center text-base text-muted" aria-hidden="true" />
                Plates
              </button>
            </RouterLink>
            <RouterLink v-slot="{ navigate, isActive }" to="/one-rep-max" custom>
              <button
                type="button"
                role="menuitem"
                class="flex w-full items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
                :class="{ '!text-primary': isActive }"
                @click="closeMenu(); navigate($event)"
              >
                <i class="fa-solid fa-calculator w-5 text-center text-base text-muted" aria-hidden="true" />
                1RM
              </button>
            </RouterLink>
            <button
              type="button"
              role="menuitem"
              class="flex w-full items-center gap-3 px-4 py-3 text-left text-sm font-bold text-foreground active:bg-card"
              @click="openSettingsFromMenu"
            >
              <i class="fa-solid fa-gear w-5 text-center text-base text-muted" aria-hidden="true" />
              Settings
            </button>
          </div>
        </div>
        <RouterLink
          to="/library"
          class="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-border text-muted hover:border-primary hover:text-primary"
          aria-label="Open exercise library"
        >
          <i class="fa-solid fa-book text-sm" aria-hidden="true" />
        </RouterLink>
      </div>
    </header>

    <div class="px-4 pb-above-workout-dock pt-4">
      <section class="mb-3.5 rounded-xl border border-border bg-card p-3.5">
        <h2 class="text-sm font-bold uppercase tracking-wide text-muted">Notes</h2>
        <textarea
          v-model="notes"
          class="mt-2 min-h-24 w-full resize-y rounded-lg border border-border bg-card-inner px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
          placeholder="Add notes for this workout..."
        />
      </section>

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

      <button
        v-if="exercises.length > 0"
        type="button"
        class="mx-auto mt-3 flex w-full max-w-lg justify-center rounded-xl bg-primary py-3.5 text-base font-extrabold tracking-wide text-foreground"
        @click="finish"
      >
        Finish Workout
      </button>
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
    </div>

    <LibraryPickerModal
      :show="libraryOpen"
      @close="libraryOpen = false"
      @pick="addFromLibrary"
    />

    <SettingsSheet
      :open="settingsOpen"
      :theme="sheetTheme"
      :weight-unit="sheetWeightUnit"
      :average-rest-seconds="sheetAverageRestSeconds"
      :average-lift-seconds="sheetAverageLiftSeconds"
      @close="settingsOpen = false"
      @update:theme="settings.setTheme"
      @update:weight-unit="settings.setWeightUnit"
      @update:average-rest-seconds="settings.setAverageRestSeconds"
      @update:average-lift-seconds="settings.setAverageLiftSeconds"
      @export-backup="onExportBackup"
      @import-backup="onImportBackup"
    />
  </div>
</template>
