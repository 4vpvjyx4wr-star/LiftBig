<script setup lang="ts">
import { computed, inject, onBeforeUnmount, onMounted, ref } from 'vue'
import {
  libraryFavoritesInjectionKey,
  settingsInjectionKey,
  workoutsInjectionKey,
} from '@/composables/injectionKeys'
import {
  MUSCLE_GROUPS,
  MUSCLE_GROUP_LABELS,
  searchLibrary,
  type LibraryExercise,
  type MuscleGroup,
} from '@/utils/exerciseLibrary'
import { formatDisplayDate } from '@/utils/dateKey'
import {
  getLibraryExerciseLogStats,
  hasUserLoggedLibraryExercise,
} from '@/utils/libraryExerciseTracking'
import { formatWeightWithUnit } from '@/utils/units'

const props = withDefaults(
  defineProps<{
    /** Narrow list: full library, saved favorites, or exercises with log history. */
    scope?: 'all' | 'favorites' | 'logged'
  }>(),
  { scope: 'all' },
)

const emit = defineEmits<{
  selectExercise: [exercise: LibraryExercise]
}>()

const workouts = inject(workoutsInjectionKey)!
const favorites = inject(libraryFavoritesInjectionKey)!
const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)

const searchQuery = ref('')
const selectedGroup = ref<MuscleGroup | 'all'>('all')

function setGroup(g: MuscleGroup | 'all') {
  selectedGroup.value = g
}

function isLogged(ex: LibraryExercise): boolean {
  return hasUserLoggedLibraryExercise(workouts.log.value, ex)
}

function logStats(ex: LibraryExercise) {
  return getLibraryExerciseLogStats(workouts.log.value, ex)
}

function maxWeightLabel(ex: LibraryExercise): string {
  const w = logStats(ex).maxWeightLbs
  if (w == null) return '—'
  return formatWeightWithUnit(w, weightUnit.value, 1)
}

function lastSessionFirstSetLabel(ex: LibraryExercise): string {
  const s = logStats(ex).lastInitialSet
  if (!s) return '—'
  const wPart =
    s.weightLbs == null ? '—' : formatWeightWithUnit(s.weightLbs, weightUnit.value, 1)
  return `${s.repsDisplay} reps × ${wPart}`
}

function lastSessionDateLabel(ex: LibraryExercise): string {
  const s = logStats(ex).lastInitialSet
  if (!s) return ''
  return formatDisplayDate(s.dateKey)
}

/** Native tooltip fallback (e.g. touch / screen readers). */
function statsTitleAttr(ex: LibraryExercise): string {
  if (!isLogged(ex)) {
    return 'No workouts logged for this exercise yet'
  }
  const s = logStats(ex)
  const max = s.maxWeightLbs == null ? '—' : formatWeightWithUnit(s.maxWeightLbs, weightUnit.value, 1)
  const date = s.lastInitialSet ? formatDisplayDate(s.lastInitialSet.dateKey) : '—'
  const first = lastSessionFirstSetLabel(ex)
  return `Max weight (≥1 rep): ${max}. Last workout (${date}) first set: ${first}`
}

const filtered = computed(() => {
  let list = searchLibrary(searchQuery.value, selectedGroup.value)
  if (props.scope === 'favorites') {
    list = list.filter((ex) => favorites.isFavorite(ex.id))
  } else if (props.scope === 'logged') {
    list = list.filter((ex) => hasUserLoggedLibraryExercise(workouts.log.value, ex))
  }
  return list
})

const emptyHint = computed(() => {
  if (props.scope === 'favorites') {
    return 'Tap the star on any exercise to save it here.'
  }
  if (props.scope === 'logged') {
    return 'Exercises you add from the library—or log with the same name—show a green check and appear here.'
  }
  return null
})

/** Horizontal chip strip: vertical wheel → scroll (desktop / fine pointer only). Touch swipe unchanged. */
const muscleGroupStripRef = ref<HTMLElement | null>(null)

function normalizeWheelDeltaY(el: HTMLElement, e: WheelEvent): number {
  switch (e.deltaMode) {
    case WheelEvent.DOM_DELTA_LINE:
      return e.deltaY * 16
    case WheelEvent.DOM_DELTA_PAGE:
      return e.deltaY * el.clientWidth
    default:
      return e.deltaY
  }
}

function onMuscleGroupStripWheel(e: WheelEvent) {
  if (!window.matchMedia('(pointer: fine)').matches) return

  const el = muscleGroupStripRef.value
  if (!el || el.scrollWidth <= el.clientWidth + 1) return

  const dy = normalizeWheelDeltaY(el, e)
  const maxScroll = el.scrollWidth - el.clientWidth
  const next = Math.min(maxScroll, Math.max(0, el.scrollLeft + dy))

  if (next === el.scrollLeft) return

  e.preventDefault()
  el.scrollLeft = next
}

onMounted(() => {
  const el = muscleGroupStripRef.value
  if (!el) return
  el.addEventListener('wheel', onMuscleGroupStripWheel, { passive: false })
})

onBeforeUnmount(() => {
  muscleGroupStripRef.value?.removeEventListener('wheel', onMuscleGroupStripWheel)
})
</script>

<template>
  <div>
    <label class="sr-only" for="library-search">Search exercises</label>
    <input
      id="library-search"
      v-model="searchQuery"
      type="search"
      class="w-full rounded-lg border border-border bg-card-inner px-3 py-2.5 text-sm text-foreground outline-none focus:border-primary"
      placeholder="Search by name, muscle, tags, equipment…"
      autocomplete="off"
    />

    <div
      ref="muscleGroupStripRef"
      class="mt-3 flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
    >
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
      <li v-for="ex in filtered" :key="ex.id" class="flex items-stretch gap-1.5">
        <button
          type="button"
          class="flex min-w-0 flex-1 flex-col items-stretch rounded-xl border border-border bg-card-inner px-3 py-3 text-left hover:border-primary"
          @click="emit('selectExercise', ex)"
        >
          <div class="flex w-full items-start justify-between gap-2">
            <span class="min-w-0 font-bold text-foreground">{{ ex.name }}</span>
            <div class="flex shrink-0 items-center gap-1">
              <i
                v-if="isLogged(ex)"
                class="fa-solid fa-circle-check shrink-0 text-base text-green-500"
                title="Logged before"
                aria-label="You have logged this exercise"
              />
              <div class="group relative shrink-0" @click.stop>
                <button
                  type="button"
                  class="rounded p-1 text-muted transition hover:text-primary focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                  :aria-label="statsTitleAttr(ex)"
                  @click.stop
                >
                  <i class="fa-solid fa-chart-line text-sm" aria-hidden="true" />
                </button>
                <div
                  role="tooltip"
                  class="pointer-events-none invisible absolute right-0 top-full z-30 mt-1.5 w-[min(17rem,calc(100vw-2.5rem))] rounded-lg border border-border bg-card px-3 py-2 text-[11px] leading-snug text-foreground opacity-0 shadow-lg transition duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100"
                >
                  <p class="border-b border-border pb-1.5 font-bold text-foreground">Your log</p>
                  <template v-if="!isLogged(ex)">
                    <p class="mt-1.5 text-muted">No workouts logged yet. Log this lift to see max weight and your last first set.</p>
                  </template>
                  <template v-else>
                    <p class="mt-1.5">
                      <span class="text-muted">Max (≥1 rep):</span>
                      {{ ' ' }}
                      <span class="font-semibold">{{ maxWeightLabel(ex) }}</span>
                    </p>
                    <p class="mt-1">
                      <span class="text-muted">Last session — first set</span>
                      <span v-if="lastSessionDateLabel(ex)" class="block text-[10px] text-muted">
                        {{ lastSessionDateLabel(ex) }}
                      </span>
                      <span class="mt-0.5 block font-semibold">{{ lastSessionFirstSetLabel(ex) }}</span>
                    </p>
                  </template>
                </div>
              </div>
              <span v-if="ex.equipment" class="text-[10px] font-bold uppercase text-muted">
                {{ ex.equipment }}
              </span>
            </div>
          </div>
          <p v-if="ex.summary" class="mt-1.5 line-clamp-2 text-left text-xs leading-snug text-muted">
            {{ ex.summary }}
          </p>
          <div class="mt-2 flex flex-wrap gap-1">
            <span
              v-for="mg in ex.muscleGroups"
              :key="mg"
              class="rounded bg-background px-1.5 py-0.5 text-[10px] font-semibold text-muted"
            >
              {{ MUSCLE_GROUP_LABELS[mg] }}
            </span>
            <span
              v-for="tag in ex.tags ?? []"
              :key="tag"
              class="rounded border border-primary/35 bg-primary/10 px-1.5 py-0.5 text-[10px] font-bold text-primary"
            >
              {{ tag }}
            </span>
          </div>
        </button>
        <button
          type="button"
          class="flex w-11 shrink-0 flex-col items-center justify-center rounded-xl border border-border bg-card-inner px-1 text-foreground hover:border-primary"
          :class="favorites.isFavorite(ex.id) ? 'border-amber-500/40 bg-card' : ''"
          :aria-pressed="favorites.isFavorite(ex.id)"
          :aria-label="favorites.isFavorite(ex.id) ? 'Remove from favorites' : 'Add to favorites'"
          @click.stop="favorites.toggle(ex.id)"
        >
          <i
            class="fa-solid fa-star text-lg"
            :class="favorites.isFavorite(ex.id) ? 'text-amber-400' : 'text-muted'"
            aria-hidden="true"
          />
        </button>
      </li>
    </ul>

    <div v-if="filtered.length === 0" class="py-8 text-center">
      <p class="text-sm text-muted">No exercises match your filters.</p>
      <p v-if="emptyHint" class="mt-2 px-2 text-xs leading-relaxed text-muted">
        {{ emptyHint }}
      </p>
    </div>
  </div>
</template>
