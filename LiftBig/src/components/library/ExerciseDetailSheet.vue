<script setup lang="ts">
import { computed, inject, onBeforeUnmount, ref, watch } from 'vue'
import CardioProgressChart from '@/components/progress/CardioProgressChart.vue'
import ProgressChart from '@/components/progress/ProgressChart.vue'
import {
  libraryFavoritesInjectionKey,
  settingsInjectionKey,
  workoutsInjectionKey,
} from '@/composables/injectionKeys'
import type { ExerciseAsset } from '@/utils/exerciseAssets'
import { ensureExerciseAsset } from '@/utils/exerciseAssets'
import type { LibraryExercise } from '@/utils/exerciseLibrary'
import { MUSCLE_GROUP_LABELS, exerciseTagIsPplSplit } from '@/utils/exerciseLibrary'
import { collectLibraryCardioHistory } from '@/utils/cardioProgress'
import {
  collectLibraryExerciseHistory,
  projectFutureStrength,
} from '@/utils/exerciseProgress'
import { hasUserLoggedLibraryExercise } from '@/utils/libraryExerciseTracking'
import { formatWeightWithUnit } from '@/utils/units'
import { youtubeEmbedUrl } from '@/utils/youtube'

const props = defineProps<{
  open: boolean
  exercise: LibraryExercise | null
}>()

const emit = defineEmits<{
  close: []
}>()

const workouts = inject(workoutsInjectionKey)!
const favorites = inject(libraryFavoritesInjectionKey)!
const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)
const distanceUnit = computed(() => settings.distanceUnit.value)

const isLogged = computed(() =>
  props.exercise ? hasUserLoggedLibraryExercise(workouts.log.value, props.exercise) : false,
)

const isCardio = computed(() => props.exercise?.isCardio === true)

const strengthHistory = computed(() =>
  props.exercise && !isCardio.value
    ? collectLibraryExerciseHistory(workouts.log.value, props.exercise)
    : [],
)

const cardioHistory = computed(() =>
  props.exercise && isCardio.value
    ? collectLibraryCardioHistory(workouts.log.value, props.exercise)
    : [],
)

const futureProjection = computed(() =>
  props.exercise && strengthHistory.value.length > 0
    ? projectFutureStrength(strengthHistory.value, props.exercise.name)
    : [],
)

const lastStrengthSession = computed(() =>
  strengthHistory.value.length
    ? strengthHistory.value[strengthHistory.value.length - 1]!
    : null,
)

const lastCardioSession = computed(() =>
  cardioHistory.value.length ? cardioHistory.value[cardioHistory.value.length - 1]! : null,
)

const projectedEnd = computed(() =>
  futureProjection.value.length
    ? futureProjection.value[futureProjection.value.length - 1]!.projectedMaxWeightLbs
    : null,
)

const hasProgressData = computed(() =>
  isCardio.value ? cardioHistory.value.length > 0 : strengthHistory.value.length > 0,
)

const tutorialEmbedUrl = computed(() => {
  const url = props.exercise?.tutorialUrl
  return url ? youtubeEmbedUrl(url) : null
})

const formAsset = ref<ExerciseAsset | null>(null)

const formMediaSrc = computed(() => {
  const asset = formAsset.value
  if (!asset) return null
  return asset.animation || asset.thumbnail || null
})

const showFormTutorial = computed(
  () => Boolean(formMediaSrc.value || (tutorialEmbedUrl.value && props.exercise?.tutorialUrl)),
)

watch(
  () => [props.open, props.exercise?.id] as const,
  async ([open, id]) => {
    formAsset.value = null
    if (!open || !id || props.exercise?.isCardio) return
    formAsset.value = await ensureExerciseAsset(id)
  },
  { immediate: true },
)

function fmtLbs(lbs: number): string {
  return formatWeightWithUnit(lbs, weightUnit.value, 1)
}

function toggleFavorite() {
  if (!props.exercise) return
  favorites.toggle(props.exercise.id)
}

let bodyOverflowRestore = ''

function lockBodyScroll() {
  bodyOverflowRestore = document.body.style.overflow
  document.body.style.overflow = 'hidden'
}

function unlockBodyScroll() {
  document.body.style.overflow = bodyOverflowRestore
}

watch(
  () => props.open && props.exercise,
  (shouldLock) => {
    if (shouldLock) lockBodyScroll()
    else unlockBodyScroll()
  },
)

onBeforeUnmount(() => {
  unlockBodyScroll()
})
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open && exercise"
      class="fixed inset-0 z-[70] flex flex-col justify-end"
      role="dialog"
      aria-modal="true"
      aria-labelledby="exercise-detail-title"
      @click.self="emit('close')"
    >
      <div
        class="absolute inset-0 bg-black/65"
        aria-hidden="true"
        @click="emit('close')"
        @wheel.prevent
        @touchmove.prevent
      />
      <div
        class="relative flex max-h-[85vh] min-h-0 w-full flex-col rounded-t-2xl border border-border border-b-0 bg-card"
        @click.stop
      >
        <div class="shrink-0 border-b border-border px-4 pb-2 pt-2">
          <div class="mx-auto mb-3 h-1 w-10 rounded-full bg-border" />
          <button
            type="button"
            class="text-xs font-bold text-muted hover:text-primary"
            @click="emit('close')"
          >
            Close
          </button>
        </div>

        <div
          class="min-h-0 flex-1 overflow-y-auto overscroll-contain px-4 pb-8 pt-3 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
        >
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
            class="rounded-full border px-2.5 py-0.5 text-[11px] font-bold"
            :class="
              exerciseTagIsPplSplit(exercise, tag)
                ? 'border-violet-500/40 bg-violet-500/15 text-violet-300'
                : 'border-primary/40 bg-primary/15 text-primary'
            "
          >
            {{ tag }}
          </span>
        </div>

        <section v-if="isLogged" class="mt-6">
          <h4 class="text-xs font-bold uppercase tracking-wide text-muted">Your progress</h4>

          <template v-if="!isCardio">
            <div
              v-if="hasProgressData"
              class="mt-3 grid grid-cols-2 gap-2 text-center sm:grid-cols-3"
            >
              <div class="rounded-xl border border-border bg-card-inner px-3 py-3">
                <div class="text-[10px] font-bold uppercase text-muted">Sessions</div>
                <div class="mt-1 text-lg font-black text-foreground">
                  {{ strengthHistory.length }}
                </div>
              </div>
              <div class="rounded-xl border border-border bg-card-inner px-3 py-3">
                <div class="text-[10px] font-bold uppercase text-muted">Latest max</div>
                <div class="mt-1 text-lg font-black text-foreground">
                  {{ lastStrengthSession ? fmtLbs(lastStrengthSession.maxWeightLbs) : '—' }}
                </div>
              </div>
              <div
                class="col-span-2 rounded-xl border border-border bg-card-inner px-3 py-3 sm:col-span-1"
              >
                <div class="text-[10px] font-bold uppercase text-muted">Projected (10 sessions)</div>
                <div class="mt-1 text-lg font-black text-primary">
                  {{ projectedEnd != null ? fmtLbs(projectedEnd) : '—' }}
                </div>
              </div>
            </div>

            <div
              v-else
              class="mt-3 rounded-2xl border border-border bg-card-inner px-4 py-6 text-center"
            >
              <p class="text-sm font-semibold text-foreground">No progress data yet</p>
              <p class="mt-2 text-xs text-muted">
                Log sets with weight and reps to see your strength chart here.
              </p>
            </div>

            <div class="mt-3">
              <ProgressChart
                :history="strengthHistory"
                :future="futureProjection"
                :weight-unit="weightUnit"
              />
            </div>
          </template>

          <template v-else>
            <div
              v-if="hasProgressData"
              class="mt-3 grid grid-cols-2 gap-2 text-center sm:grid-cols-3"
            >
              <div class="rounded-xl border border-border bg-card-inner px-3 py-3">
                <div class="text-[10px] font-bold uppercase text-muted">Sessions</div>
                <div class="mt-1 text-lg font-black text-foreground">{{ cardioHistory.length }}</div>
              </div>
              <div class="rounded-xl border border-border bg-card-inner px-3 py-3">
                <div class="text-[10px] font-bold uppercase text-muted">Latest duration</div>
                <div class="mt-1 text-lg font-black text-foreground">
                  {{ lastCardioSession ? `${lastCardioSession.durationMinutes} min` : '—' }}
                </div>
              </div>
              <div
                class="col-span-2 rounded-xl border border-border bg-card-inner px-3 py-3 sm:col-span-1"
              >
                <div class="text-[10px] font-bold uppercase text-muted">Latest pace</div>
                <div class="mt-1 text-lg font-black text-primary">
                  {{
                    lastCardioSession?.paceMinutesPerUnit != null
                      ? `${lastCardioSession.paceMinutesPerUnit} min/unit`
                      : '—'
                  }}
                </div>
              </div>
            </div>

            <div
              v-else
              class="mt-3 rounded-2xl border border-border bg-card-inner px-4 py-6 text-center"
            >
              <p class="text-sm font-semibold text-foreground">No cardio data yet</p>
              <p class="mt-2 text-xs text-muted">
                Log duration (and distance when available) to see your chart here.
              </p>
            </div>

            <div class="mt-3">
              <CardioProgressChart :history="cardioHistory" :distance-unit="distanceUnit" />
            </div>
          </template>
        </section>

        <section v-if="showFormTutorial" class="mt-6">
          <h4 class="text-xs font-bold uppercase tracking-wide text-muted">Form tutorial</h4>

          <div
            v-if="formMediaSrc"
            class="mt-2 mx-auto flex max-w-[320px] justify-center overflow-hidden rounded-xl border border-border bg-[#F8F9FA]"
          >
            <img
              :src="formMediaSrc"
              :alt="`${exercise.name} form illustration`"
              class="h-auto w-full max-w-[320px] object-contain"
              width="320"
              height="320"
              loading="lazy"
            />
          </div>

          <div
            v-if="tutorialEmbedUrl && exercise.tutorialUrl"
            class="mt-3 overflow-hidden rounded-xl border border-border bg-black aspect-video"
          >
            <iframe
              :src="tutorialEmbedUrl"
              :title="`${exercise.name} form tutorial`"
              class="h-full w-full"
              loading="lazy"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
              allowfullscreen
            />
          </div>
          <a
            v-if="exercise.tutorialUrl"
            :href="exercise.tutorialUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="mt-2 inline-flex items-center gap-1.5 text-xs font-bold text-primary hover:text-foreground"
          >
            <i class="fa-brands fa-youtube" aria-hidden="true" />
            Open on YouTube
          </a>
        </section>

        <h4 class="mt-6 text-xs font-bold uppercase tracking-wide text-muted">How to perform</h4>
        <ol class="mt-2 list-decimal space-y-2 pl-5 text-sm text-foreground">
          <li v-for="(step, i) in exercise.instructions" :key="i" class="leading-relaxed">
            {{ step }}
          </li>
        </ol>

        <template v-if="exercise.cues?.length">
          <h4 class="mt-6 text-xs font-bold uppercase tracking-wide text-muted">Form cues</h4>
          <ul class="mt-2 space-y-2 text-sm text-foreground">
            <li v-for="(cue, i) in exercise.cues" :key="i" class="flex gap-2 leading-relaxed">
              <span class="shrink-0 text-primary" aria-hidden="true">→</span>
              <span>{{ cue }}</span>
            </li>
          </ul>
        </template>

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
    </div>
  </Teleport>
</template>
