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
  PPL_SPLITS,
  PPL_SPLIT_LABELS,
  LIBRARY_TRAIT_FILTERS,
  LIBRARY_TRAIT_FILTER_LABELS,
  exerciseMatchesPplSplit,
  exerciseMatchesTraitFilters,
  exerciseTagIsPplSplit,
  listLibraryEquipmentTypes,
  searchLibrary,
  type LibraryExercise,
  type LibraryFilterGroup,
  type LibraryTraitFilter,
  type PplSplit,
} from '@/utils/exerciseLibrary'
import { formatDisplayDate } from '@/utils/dateKey'
import { cardioListStats, collectLibraryCardioHistory } from '@/utils/cardioProgress'
import {
  collectLibraryExerciseHistory,
  strengthListStats,
} from '@/utils/exerciseProgress'
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
const selectedGroup = ref<LibraryFilterGroup>('all')
const selectedPplSplit = ref<PplSplit | 'all'>('all')
const activeTraits = ref<LibraryTraitFilter[]>([])
const equipmentTypes = listLibraryEquipmentTypes()

function setGroup(g: LibraryFilterGroup) {
  selectedGroup.value = g
}

function setPplSplit(split: PplSplit | 'all') {
  selectedPplSplit.value = split
}

function isTraitActive(trait: LibraryTraitFilter): boolean {
  return activeTraits.value.includes(trait)
}

function toggleTrait(trait: LibraryTraitFilter) {
  if (activeTraits.value.includes(trait)) {
    activeTraits.value = activeTraits.value.filter((t) => t !== trait)
  } else {
    activeTraits.value = [...activeTraits.value, trait]
  }
}

function clearTraits() {
  activeTraits.value = []
}

function isEquipmentSelected(eq: string): boolean {
  return settings.equipmentFilterPrefs.value.includes(eq)
}

function toggleEquipment(eq: string) {
  settings.toggleEquipmentFilter(eq)
}

function selectAllEquipment() {
  settings.clearEquipmentFilters()
}

function isLogged(ex: LibraryExercise): boolean {
  return hasUserLoggedLibraryExercise(workouts.log.value, ex)
}

function logStats(ex: LibraryExercise) {
  return getLibraryExerciseLogStats(workouts.log.value, ex)
}

function quickStatLabels(ex: LibraryExercise): { sessions: number; avg14: string; max: string } {
  if (ex.isCardio) {
    const s = cardioListStats(collectLibraryCardioHistory(workouts.log.value, ex))
    return {
      sessions: s.sessions,
      avg14: s.avg14DayDurationMinutes == null ? '—' : `${Math.round(s.avg14DayDurationMinutes)} min`,
      max: s.maxDurationMinutes == null ? '—' : `${s.maxDurationMinutes} min`,
    }
  }
  const s = strengthListStats(collectLibraryExerciseHistory(workouts.log.value, ex))
  return {
    sessions: s.sessions,
    avg14:
      s.avg14DayMaxLbs == null ? '—' : formatWeightWithUnit(s.avg14DayMaxLbs, weightUnit.value, 1),
    max: s.maxLbs == null ? '—' : formatWeightWithUnit(s.maxLbs, weightUnit.value, 1),
  }
}

function maxWeightLabel(ex: LibraryExercise): string {
  const w = logStats(ex).maxWeightLbs
  if (w == null) return '—'
  return formatWeightWithUnit(w, weightUnit.value, 1)
}

function lastSessionFirstSetLabel(ex: LibraryExercise): string {
  const s = logStats(ex).lastInitialSet
  if (!s) return '—'
  if (ex.isCardio) {
    return s.repsDisplay === '—' ? '—' : `${s.repsDisplay} min`
  }
  const wPart =
    s.weightLbs == null ? '—' : formatWeightWithUnit(s.weightLbs, weightUnit.value, 1)
  return `${s.repsDisplay} reps × ${wPart}`
}

function maxStatLabel(ex: LibraryExercise): string {
  const s = logStats(ex)
  if (ex.isCardio) {
    return s.maxDurationMinutes == null ? '—' : `${s.maxDurationMinutes} min`
  }
  return maxWeightLabel(ex)
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
  if (ex.isCardio) {
    const max = s.maxDurationMinutes == null ? '—' : `${s.maxDurationMinutes} min`
    const date = s.lastInitialSet ? formatDisplayDate(s.lastInitialSet.dateKey) : '—'
    const last = lastSessionFirstSetLabel(ex)
    return `Longest session: ${max}. Last workout (${date}): ${last}`
  }
  const max = s.maxWeightLbs == null ? '—' : formatWeightWithUnit(s.maxWeightLbs, weightUnit.value, 1)
  const date = s.lastInitialSet ? formatDisplayDate(s.lastInitialSet.dateKey) : '—'
  const first = lastSessionFirstSetLabel(ex)
  return `Max weight (≥1 rep): ${max}. Last workout (${date}) first set: ${first}`
}

const filtered = computed(() => {
  let list = searchLibrary(searchQuery.value, selectedGroup.value)
  const equipment = settings.equipmentFilterPrefs.value
  if (equipment.length > 0) {
    const allowed = new Set(equipment.map((e) => e.toLowerCase()))
    list = list.filter((ex) => {
      const eq = (ex.equipment ?? '').trim().toLowerCase()
      return eq && allowed.has(eq)
    })
  }
  if (selectedPplSplit.value !== 'all') {
    list = list.filter((ex) => exerciseMatchesPplSplit(ex, selectedPplSplit.value))
  }
  if (activeTraits.value.length > 0) {
    list = list.filter((ex) => exerciseMatchesTraitFilters(ex, activeTraits.value))
  }
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
const pplSplitStripRef = ref<HTMLElement | null>(null)
const traitStripRef = ref<HTMLElement | null>(null)
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

function onHorizontalStripWheel(el: HTMLElement | null, e: WheelEvent) {
  if (!window.matchMedia('(pointer: fine)').matches) return
  if (!el || el.scrollWidth <= el.clientWidth + 1) return

  const dy = normalizeWheelDeltaY(el, e)
  const maxScroll = el.scrollWidth - el.clientWidth
  const next = Math.min(maxScroll, Math.max(0, el.scrollLeft + dy))

  if (next === el.scrollLeft) return

  e.preventDefault()
  el.scrollLeft = next
}

function onPplSplitStripWheel(e: WheelEvent) {
  onHorizontalStripWheel(pplSplitStripRef.value, e)
}

function onTraitStripWheel(e: WheelEvent) {
  onHorizontalStripWheel(traitStripRef.value, e)
}

function onMuscleGroupStripWheel(e: WheelEvent) {
  onHorizontalStripWheel(muscleGroupStripRef.value, e)
}

onMounted(() => {
  pplSplitStripRef.value?.addEventListener('wheel', onPplSplitStripWheel, { passive: false })
  traitStripRef.value?.addEventListener('wheel', onTraitStripWheel, { passive: false })
  muscleGroupStripRef.value?.addEventListener('wheel', onMuscleGroupStripWheel, { passive: false })
})

onBeforeUnmount(() => {
  pplSplitStripRef.value?.removeEventListener('wheel', onPplSplitStripWheel)
  traitStripRef.value?.removeEventListener('wheel', onTraitStripWheel)
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
      class="mt-3 flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
    >
      <button
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          settings.equipmentFilterPrefs.value.length === 0
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="selectAllEquipment"
      >
        All equipment
      </button>
      <button
        v-for="eq in equipmentTypes"
        :key="eq"
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          isEquipmentSelected(eq)
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="toggleEquipment(eq)"
      >
        {{ eq }}
      </button>
    </div>

    <div
      ref="pplSplitStripRef"
      class="mt-3 flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
    >
      <button
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          selectedPplSplit === 'all'
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setPplSplit('all')"
      >
        All splits
      </button>
      <button
        v-for="split in PPL_SPLITS"
        :key="split"
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          selectedPplSplit === split
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setPplSplit(split)"
      >
        {{ PPL_SPLIT_LABELS[split] }}
      </button>
    </div>

    <div
      ref="traitStripRef"
      class="mt-3 flex gap-2 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
    >
      <button
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          activeTraits.length === 0
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="clearTraits"
      >
        All types
      </button>
      <button
        v-for="trait in LIBRARY_TRAIT_FILTERS"
        :key="trait"
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          isTraitActive(trait)
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="toggleTrait(trait)"
      >
        {{ LIBRARY_TRAIT_FILTER_LABELS[trait] }}
      </button>
    </div>

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
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          selectedGroup === 'cardio'
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setGroup('cardio')"
      >
        Cardio
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
        <div
          class="relative rounded-xl border border-border bg-card-inner hover:border-primary"
        >
          <button
            type="button"
            class="flex w-full min-w-0 flex-col items-stretch px-3 py-3 pr-9 text-left"
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
                      <p class="mt-1.5 text-muted">
                        {{
                          ex.isCardio
                            ? 'No sessions logged yet. Log duration to see your history here.'
                            : 'No workouts logged yet. Log this lift to see max weight and your last first set.'
                        }}
                      </p>
                    </template>
                    <template v-else-if="ex.isCardio">
                      <p class="mt-1.5">
                        <span class="text-muted">Longest session:</span>
                        {{ ' ' }}
                        <span class="font-semibold">{{ maxStatLabel(ex) }}</span>
                      </p>
                      <p class="mt-1">
                        <span class="text-muted">Last session</span>
                        <span v-if="lastSessionDateLabel(ex)" class="block text-[10px] text-muted">
                          {{ lastSessionDateLabel(ex) }}
                        </span>
                        <span class="mt-0.5 block font-semibold">{{ lastSessionFirstSetLabel(ex) }}</span>
                      </p>
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
                v-if="ex.isCardio"
                class="rounded border border-emerald-500/40 bg-emerald-500/10 px-1.5 py-0.5 text-[10px] font-bold text-emerald-400"
              >
                Cardio
              </span>
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
                class="rounded border px-1.5 py-0.5 text-[10px] font-bold"
                :class="
                  exerciseTagIsPplSplit(ex, tag)
                    ? 'border-violet-500/40 bg-violet-500/10 text-violet-300'
                    : 'border-primary/35 bg-primary/10 text-primary'
                "
              >
                {{ tag }}
              </span>
            </div>
            <template v-if="isLogged(ex)">
              <div
                v-for="stats in [quickStatLabels(ex)]"
                :key="'stats'"
                class="mt-2 grid grid-cols-3 gap-1.5 rounded-lg border border-border/60 bg-background/50 px-2 py-2 text-center"
              >
                <div>
                  <div class="text-[9px] font-bold uppercase tracking-wide text-muted">Sessions</div>
                  <div class="mt-0.5 text-sm font-black text-foreground">{{ stats.sessions }}</div>
                </div>
                <div>
                  <div class="text-[9px] font-bold uppercase tracking-wide text-muted">14d avg</div>
                  <div class="mt-0.5 text-sm font-black text-foreground">{{ stats.avg14 }}</div>
                </div>
                <div>
                  <div class="text-[9px] font-bold uppercase tracking-wide text-muted">Max</div>
                  <div class="mt-0.5 text-sm font-black text-foreground">{{ stats.max }}</div>
                </div>
              </div>
            </template>
          </button>
          <button
            type="button"
            class="absolute bottom-2 right-2 rounded p-1 text-muted transition hover:text-primary focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            :aria-pressed="favorites.isFavorite(ex.id)"
            :aria-label="favorites.isFavorite(ex.id) ? 'Remove from favorites' : 'Add to favorites'"
            @click.stop="favorites.toggle(ex.id)"
          >
            <i
              class="fa-solid fa-star text-sm"
              :class="favorites.isFavorite(ex.id) ? 'text-amber-400' : 'text-muted'"
              aria-hidden="true"
            />
          </button>
        </div>
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
