<script setup lang="ts">
import { computed, inject, onMounted, onUnmounted, ref } from 'vue';
import {
  WORKOUT_LOG_KEY,
  LIBRARY_FAVORITES_KEY,
  SETTINGS_KEY,
} from '../keys/injectionKeys';
import {
  hasLoggedExercise,
  getExerciseLogStats,
} from '../../patches/libraryExerciseTracking-CAhSe-yn.js';
import {
  getEquipmentOptions,
  searchExercises,
  MUSCLE_GROUP_KEYS,
  MUSCLE_GROUP_LABELS,
  type Exercise,
} from '../lib/productionExerciseLibrary';
import { formatDateKey } from '../lib/productionDateKey';
import { formatWeight } from '../lib/productionUnits';

const props = withDefaults(
  defineProps<{
    scope?: 'all' | 'favorites' | 'logged';
  }>(),
  { scope: 'all' }
);

const emit = defineEmits<{
  selectExercise: [exercise: Exercise];
}>();

const workoutLog = inject(WORKOUT_LOG_KEY)!;
const favorites = inject(LIBRARY_FAVORITES_KEY)!;
const settings = inject(SETTINGS_KEY)!;

const searchQuery = ref('');
const muscleFilter = ref<'all' | 'cardio' | string>('all');
const muscleGroupStripRef = ref<HTMLElement | null>(null);

const equipmentOptions = getEquipmentOptions();
const weightUnit = computed(() => settings.weightUnit.value);

const filteredExercises = computed(() => {
  let list = searchExercises(searchQuery.value, muscleFilter.value);
  const prefs = settings.equipmentFilterPrefs.value;
  if (prefs.length > 0) {
    const allowed = new Set(prefs.map((e) => e.toLowerCase()));
    list = list.filter((ex) => {
      const equipment = (ex.equipment ?? '').trim().toLowerCase();
      return equipment && allowed.has(equipment);
    });
  }
  if (props.scope === 'favorites') {
    list = list.filter((ex) => favorites.isFavorite(ex.id));
  } else if (props.scope === 'logged') {
    list = list.filter((ex) => hasLoggedExercise(workoutLog.log.value, ex));
  }
  return list;
});

const emptyScopeHint = computed(() => {
  if (props.scope === 'favorites') {
    return 'Tap the star on any exercise to save it here.';
  }
  if (props.scope === 'logged') {
    return 'Exercises you add from the library—or log with the same name—show a green check and appear here.';
  }
  return null;
});

function setMuscleFilter(value: 'all' | 'cardio' | string) {
  muscleFilter.value = value;
}

function isEquipmentActive(equipment: string): boolean {
  return settings.equipmentFilterPrefs.value.includes(equipment);
}

function toggleEquipment(equipment: string) {
  settings.toggleEquipmentFilter(equipment);
}

function clearEquipmentFilters() {
  settings.clearEquipmentFilters();
}

function exerciseIsLogged(exercise: Exercise): boolean {
  return hasLoggedExercise(workoutLog.log.value, exercise);
}

function exerciseStats(exercise: Exercise) {
  return getExerciseLogStats(workoutLog.log.value, exercise);
}

function formatMaxWeight(exercise: Exercise): string {
  const maxWeightLbs = exerciseStats(exercise).maxWeightLbs;
  return maxWeightLbs == null ? '—' : formatWeight(maxWeightLbs, weightUnit.value, 1);
}

function formatLastSet(exercise: Exercise): string {
  const last = exerciseStats(exercise).lastInitialSet;
  if (!last) return '—';
  if (exercise.isCardio) {
    return last.repsDisplay === '—' ? '—' : `${last.repsDisplay} min`;
  }
  const weight =
    last.weightLbs == null ? '—' : formatWeight(last.weightLbs, weightUnit.value, 1);
  return `${last.repsDisplay} reps × ${weight}`;
}

function formatTooltipMax(exercise: Exercise): string {
  const stats = exerciseStats(exercise);
  if (exercise.isCardio) {
    return stats.maxDurationMinutes == null ? '—' : `${stats.maxDurationMinutes} min`;
  }
  return formatMaxWeight(exercise);
}

function formatLastDate(exercise: Exercise): string {
  const last = exerciseStats(exercise).lastInitialSet;
  return last ? formatDateKey(last.dateKey) : '';
}

function chartAriaLabel(exercise: Exercise): string {
  if (!exerciseIsLogged(exercise)) {
    return 'No workouts logged for this exercise yet';
  }
  const stats = exerciseStats(exercise);
  const lastDate = stats.lastInitialSet ? formatDateKey(stats.lastInitialSet.dateKey) : '—';
  if (exercise.isCardio) {
    const longest =
      stats.maxDurationMinutes == null ? '—' : `${stats.maxDurationMinutes} min`;
    return `Longest session: ${longest}. Last workout (${lastDate}): ${formatLastSet(exercise)}`;
  }
  return `Max weight (≥1 rep): ${formatMaxWeight(exercise)}. Last workout (${lastDate}) first set: ${formatLastSet(exercise)}`;
}

/** Always-visible tile stat: MAX */
function formatTileMax(exercise: Exercise): string {
  const stats = exerciseStats(exercise);
  if (exercise.isCardio) {
    return stats.maxDurationMinutes == null ? '—' : `${stats.maxDurationMinutes} min`;
  }
  if (!stats.maxSet) return '—';
  return `${formatWeight(stats.maxSet.weightLbs, weightUnit.value, 1)} x ${stats.maxSet.reps}`;
}

/** Always-visible tile stat: AVG */
function formatTileAvg(exercise: Exercise): string {
  const stats = exerciseStats(exercise);
  if (exercise.isCardio) {
    return '—';
  }
  if (!stats.avgSet) return '—';
  return `${formatWeight(stats.avgSet.weightLbs, weightUnit.value, 1)} x ${stats.avgSet.reps}`;
}

function muscleLabel(key: string): string {
  return (MUSCLE_GROUP_LABELS as Record<string, string>)[key] ?? key;
}

function wheelDeltaPixels(element: HTMLElement, event: WheelEvent): number {
  switch (event.deltaMode) {
    case WheelEvent.DOM_DELTA_LINE:
      return event.deltaY * 16;
    case WheelEvent.DOM_DELTA_PAGE:
      return event.deltaY * element.clientWidth;
    default:
      return event.deltaY;
  }
}

function onMuscleStripWheel(event: WheelEvent) {
  if (!window.matchMedia('(pointer: fine)').matches) return;
  const strip = muscleGroupStripRef.value;
  if (!strip || strip.scrollWidth <= strip.clientWidth + 1) return;
  const delta = wheelDeltaPixels(strip, event);
  const maxScroll = strip.scrollWidth - strip.clientWidth;
  const next = Math.min(maxScroll, Math.max(0, strip.scrollLeft + delta));
  if (next !== strip.scrollLeft) {
    event.preventDefault();
    strip.scrollLeft = next;
  }
}

onMounted(() => {
  const strip = muscleGroupStripRef.value;
  if (strip) strip.addEventListener('wheel', onMuscleStripWheel, { passive: false });
});

onUnmounted(() => {
  muscleGroupStripRef.value?.removeEventListener('wheel', onMuscleStripWheel);
});
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
        @click="clearEquipmentFilters"
      >
        All equipment
      </button>
      <button
        v-for="equipment in equipmentOptions"
        :key="equipment"
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          isEquipmentActive(equipment)
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="toggleEquipment(equipment)"
      >
        {{ equipment }}
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
          muscleFilter === 'all'
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setMuscleFilter('all')"
      >
        All
      </button>
      <button
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          muscleFilter === 'cardio'
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setMuscleFilter('cardio')"
      >
        Cardio
      </button>
      <button
        v-for="mg in MUSCLE_GROUP_KEYS"
        :key="mg"
        type="button"
        class="shrink-0 rounded-full border px-3 py-1.5 text-[11px] font-bold tracking-wide"
        :class="
          muscleFilter === mg
            ? 'border-primary bg-primary text-foreground'
            : 'border-border bg-card-inner text-muted'
        "
        @click="setMuscleFilter(mg)"
      >
        {{ muscleLabel(mg) }}
      </button>
    </div>

    <ul class="mt-4 space-y-2 pb-2">
      <li v-for="exercise in filteredExercises" :key="exercise.id">
        <div class="relative rounded-xl border border-border bg-card-inner hover:border-primary">
          <button
            type="button"
            class="flex w-full min-w-0 flex-col items-stretch px-3 py-3 pr-9 text-left"
            @click="emit('selectExercise', exercise)"
          >
            <div class="flex w-full items-start justify-between gap-2">
              <span class="min-w-0 font-bold text-foreground">{{ exercise.name }}</span>
              <div class="flex shrink-0 items-center gap-1">
                <i
                  v-if="exerciseIsLogged(exercise)"
                  class="fa-solid fa-circle-check shrink-0 text-base text-green-500"
                  title="Logged before"
                  aria-label="You have logged this exercise"
                />
                <div class="group relative shrink-0" @click.stop>
                  <button
                    type="button"
                    class="rounded p-1 text-muted transition hover:text-primary focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                    :aria-label="chartAriaLabel(exercise)"
                    @click.stop
                  >
                    <i class="fa-solid fa-chart-line text-sm" aria-hidden="true" />
                  </button>
                  <div
                    role="tooltip"
                    class="pointer-events-none invisible absolute right-0 top-full z-30 mt-1.5 w-[min(17rem,calc(100vw-2.5rem))] rounded-lg border border-border bg-card px-3 py-2 text-[11px] leading-snug text-foreground opacity-0 shadow-lg transition duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100"
                  >
                    <p class="border-b border-border pb-1.5 font-bold text-foreground">Your log</p>
                    <template v-if="exerciseIsLogged(exercise)">
                      <template v-if="exercise.isCardio">
                        <p class="mt-1.5">
                          <span class="text-muted">Longest session:</span>
                          <span class="font-semibold">{{ formatTooltipMax(exercise) }}</span>
                        </p>
                        <p class="mt-1">
                          <span class="text-muted">Last session</span>
                          <span v-if="formatLastDate(exercise)" class="block text-[10px] text-muted">
                            {{ formatLastDate(exercise) }}
                          </span>
                          <span class="mt-0.5 block font-semibold">{{ formatLastSet(exercise) }}</span>
                        </p>
                      </template>
                      <template v-else>
                        <p class="mt-1.5">
                          <span class="text-muted">Max (≥1 rep):</span>
                          <span class="font-semibold">{{ formatMaxWeight(exercise) }}</span>
                        </p>
                        <p class="mt-1">
                          <span class="text-muted">Last session — first set</span>
                          <span v-if="formatLastDate(exercise)" class="block text-[10px] text-muted">
                            {{ formatLastDate(exercise) }}
                          </span>
                          <span class="mt-0.5 block font-semibold">{{ formatLastSet(exercise) }}</span>
                        </p>
                      </template>
                    </template>
                    <p v-else class="mt-1.5 text-muted">
                      {{
                        exercise.isCardio
                          ? 'No sessions logged yet. Log duration to see your history here.'
                          : 'No workouts logged yet. Log this lift to see max weight and your last first set.'
                      }}
                    </p>
                  </div>
                </div>
                <span
                  v-if="exercise.equipment"
                  class="text-[10px] font-bold uppercase text-muted"
                >
                  {{ exercise.equipment }}
                </span>
              </div>
            </div>

            <p
              v-if="exercise.summary"
              class="mt-1.5 line-clamp-2 text-left text-xs leading-snug text-muted"
            >
              {{ exercise.summary }}
            </p>

            <div class="mt-2 flex flex-wrap gap-1">
              <span
                v-if="exercise.isCardio"
                class="rounded border border-emerald-500/40 bg-emerald-500/10 px-1.5 py-0.5 text-[10px] font-bold text-emerald-400"
              >
                Cardio
              </span>
              <span
                v-for="mg in exercise.muscleGroups"
                :key="mg"
                class="rounded bg-background px-1.5 py-0.5 text-[10px] font-semibold text-muted"
              >
                {{ muscleLabel(mg) }}
              </span>
              <span
                v-for="tag in exercise.tags ?? []"
                :key="tag"
                class="rounded border border-primary/35 bg-primary/10 px-1.5 py-0.5 text-[10px] font-bold text-primary"
              >
                {{ tag }}
              </span>
            </div>

            <div
              class="mt-2 flex items-center gap-4 border-t border-border/60 pt-2 pr-6 text-[10px] leading-tight"
            >
              <span>
                <span class="font-bold uppercase tracking-wide text-muted">Max</span>
                <span class="ml-1 font-semibold text-foreground">{{ formatTileMax(exercise) }}</span>
              </span>
              <span>
                <span class="font-bold uppercase tracking-wide text-muted">Avg</span>
                <span class="ml-1 font-semibold text-foreground">{{ formatTileAvg(exercise) }}</span>
              </span>
            </div>
          </button>

          <button
            type="button"
            class="absolute bottom-2 right-2 rounded p-1 text-muted transition hover:text-primary focus:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            :aria-pressed="favorites.isFavorite(exercise.id)"
            :aria-label="
              favorites.isFavorite(exercise.id) ? 'Remove from favorites' : 'Add to favorites'
            "
            @click.stop="favorites.toggle(exercise.id)"
          >
            <i
              class="fa-solid fa-star text-sm"
              :class="favorites.isFavorite(exercise.id) ? 'text-amber-400' : 'text-muted'"
              aria-hidden="true"
            />
          </button>
        </div>
      </li>
    </ul>

    <div v-if="filteredExercises.length === 0" class="py-8 text-center">
      <p class="text-sm text-muted">No exercises match your filters.</p>
      <p v-if="emptyScopeHint" class="mt-2 px-2 text-xs leading-relaxed text-muted">
        {{ emptyScopeHint }}
      </p>
    </div>
  </div>
</template>
