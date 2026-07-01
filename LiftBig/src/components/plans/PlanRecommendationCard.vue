<script setup lang="ts">
import { computed, inject } from 'vue'
import type { PlanCatalogEntry, PlanRecommendation } from '@/types/planCatalog'
import { planFavoritesInjectionKey } from '@/composables/injectionKeys'
import { BADGE_LABELS } from '@/utils/planRecommendation'
import { haptic } from '@/utils/haptics'

const props = defineProps<{
  recommendation: PlanRecommendation
  compareSelected: boolean
  compareDisabled: boolean
}>()

const emit = defineEmits<{
  start: []
  preview: []
  toggleCompare: []
  toggleFavorite: []
}>()

const favorites = inject(planFavoritesInjectionKey)!

const entry = computed(() => props.recommendation.entry)
const isFavorite = computed(() => favorites.isFavorite(entry.value.id))

const daysLabel = computed(() => formatDays(entry.value))
const durationLabel = computed(() => formatDuration(entry.value))

function formatDays(e: PlanCatalogEntry): string {
  const d = Array.isArray(e.days) ? e.days : [e.days]
  if (d.length === 1) return `${d[0]} days/week`
  return `${Math.min(...d)}–${Math.max(...d)} days/week`
}

function formatDuration(e: PlanCatalogEntry): string {
  const d = Array.isArray(e.duration) ? e.duration : [e.duration]
  const labels: Record<string, string> = { quick: 'Quick', standard: 'Standard', long: 'Long' }
  return d.map((x) => labels[x] ?? x).join(' / ')
}

function onStart() {
  haptic('tap')
  emit('start')
}

function onPreview() {
  haptic('tap')
  emit('preview')
}

function onFavorite() {
  haptic('tap')
  favorites.toggle(entry.value.id)
  emit('toggleFavorite')
}

function onCompare() {
  if (props.compareDisabled && !props.compareSelected) return
  haptic('tap')
  emit('toggleCompare')
}
</script>

<template>
  <article class="rounded-xl border border-border bg-card p-4">
    <div class="flex items-start justify-between gap-2">
      <span
        class="rounded-full px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wide"
        :class="
          recommendation.badge === 'bestMatch'
            ? 'bg-primary/20 text-primary'
            : 'bg-card-inner text-muted'
        "
      >
        {{ BADGE_LABELS[recommendation.badge] }}
      </span>
      <button
        type="button"
        class="shrink-0 p-1 text-muted hover:text-primary"
        :aria-label="isFavorite ? 'Remove from favorites' : 'Add to favorites'"
        @click="onFavorite"
      >
        <i class="fa-solid" :class="isFavorite ? 'fa-star text-primary' : 'fa-star'" />
      </button>
    </div>

    <h3 class="mt-2 text-lg font-extrabold text-foreground">{{ entry.title }}</h3>
    <p class="mt-1 text-sm leading-snug text-muted">{{ entry.description }}</p>

    <dl class="mt-3 grid grid-cols-2 gap-x-3 gap-y-1.5 text-xs">
      <div>
        <dt class="font-bold uppercase tracking-wide text-muted">Difficulty</dt>
        <dd class="font-semibold text-foreground">{{ entry.difficulty }}</dd>
      </div>
      <div>
        <dt class="font-bold uppercase tracking-wide text-muted">Duration</dt>
        <dd class="font-semibold text-foreground">~{{ entry.estimatedMinutes }} min</dd>
      </div>
      <div>
        <dt class="font-bold uppercase tracking-wide text-muted">Frequency</dt>
        <dd class="font-semibold text-foreground">{{ daysLabel }}</dd>
      </div>
      <div>
        <dt class="font-bold uppercase tracking-wide text-muted">Session</dt>
        <dd class="font-semibold text-foreground">{{ durationLabel }}</dd>
      </div>
      <div class="col-span-2">
        <dt class="font-bold uppercase tracking-wide text-muted">Progression</dt>
        <dd class="font-semibold text-foreground">{{ entry.progressionStyle }}</dd>
      </div>
    </dl>

    <p v-if="recommendation.matchReasons.length" class="mt-3 text-xs text-muted">
      <span class="font-bold text-foreground">Matched because:</span>
      {{ recommendation.matchReasons.join(' · ') }}
    </p>

    <div class="mt-4 flex flex-wrap gap-2">
      <button
        type="button"
        class="flex-1 rounded-lg bg-primary py-2.5 text-sm font-extrabold text-foreground"
        @click="onStart"
      >
        Start
      </button>
      <button
        type="button"
        class="rounded-lg border border-border px-4 py-2.5 text-sm font-bold text-foreground"
        @click="onPreview"
      >
        Preview
      </button>
      <button
        type="button"
        class="rounded-lg border px-4 py-2.5 text-sm font-bold"
        :class="
          compareSelected
            ? 'border-primary bg-primary/10 text-primary'
            : compareDisabled
              ? 'border-border text-muted opacity-50'
              : 'border-border text-foreground'
        "
        :disabled="compareDisabled && !compareSelected"
        @click="onCompare"
      >
        Compare
      </button>
    </div>
  </article>
</template>
