<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import GuidedPlanScheduleSheet from '@/components/plans/GuidedPlanScheduleSheet.vue'
import PickAPlanStepOptions from '@/components/plans/PickAPlanStepOptions.vue'
import PlanCompareSheet from '@/components/plans/PlanCompareSheet.vue'
import PlanPreviewSheet from '@/components/plans/PlanPreviewSheet.vue'
import PlanRecommendationCard from '@/components/plans/PlanRecommendationCard.vue'
import {
  pickAPlanStateInjectionKey,
  templatesInjectionKey,
  workoutsInjectionKey,
} from '@/composables/injectionKeys'
import {
  DAYS_OPTIONS,
  DURATION_OPTIONS,
  EQUIPMENT_OPTIONS,
  EXPERIENCE_OPTIONS,
  GOAL_OPTIONS,
  STYLE_OPTIONS,
} from '@/composables/usePickAPlanState'
import type { PlanCatalogEntry } from '@/types/planCatalog'
import type { WorkoutTemplate } from '@/types/workout'
import {
  getGeneratedTemplate,
  persistGeneratedTemplate,
} from '@/utils/guidedPlanGenerator'
import { buildMotivationalHeadline, recommendPlans } from '@/utils/planRecommendation'
import { scheduleCatalogEntry } from '@/utils/schedulePlanProgram'

const router = useRouter()
const workouts = inject(workoutsInjectionKey)!
const templates = inject(templatesInjectionKey)!

const state = inject(pickAPlanStateInjectionKey)!

const compareIds = ref<string[]>([])
const previewEntry = ref<PlanCatalogEntry | null>(null)
const compareOpen = ref(false)
const scheduleOpen = ref(false)
const scheduleEntry = ref<PlanCatalogEntry | null>(null)
const scheduleTemplate = ref<WorkoutTemplate | null>(null)

const recommendations = computed(() => {
  if (!state.isResults.value) return []
  return recommendPlans(state.answers.value)
})

const headline = computed(() => buildMotivationalHeadline(state.answers.value))

const compareEntries = computed(() =>
  recommendations.value
    .filter((r) => compareIds.value.includes(r.entry.id))
    .map((r) => r.entry),
)

const maxCompare = 3

const TOTAL_STEPS = 6

watch(
  () => state.stepIndex.value,
  (step, prev) => {
    if (step >= TOTAL_STEPS && prev < TOTAL_STEPS) {
      const first = recommendPlans(state.answers.value)[0]
      if (first) state.finishWithMatch(first.entry.title)
    }
  },
)

function goBackNav() {
  if (state.stepIndex.value > 0 && !state.isResults.value) {
    state.goBack()
  } else {
    router.back()
  }
}

function toggleCompare(id: string) {
  const set = new Set(compareIds.value)
  if (set.has(id)) set.delete(id)
  else if (set.size < maxCompare) set.add(id)
  compareIds.value = [...set]
}

function openCompare() {
  if (compareIds.value.length < 2) {
    window.alert('Select at least 2 plans to compare using the Compare button on each card.')
    return
  }
  compareOpen.value = true
}

function resolveTemplateForEntry(entry: PlanCatalogEntry): WorkoutTemplate | null {
  if (entry.templateId) {
    const fromStore = templates.templates.value.find((t) => t.id === entry.templateId)
    if (fromStore) return fromStore
    return getGeneratedTemplate(entry.id) ?? null
  }
  return null
}

function ensureGeneratedPersisted(entry: PlanCatalogEntry) {
  if (!entry.id.startsWith('generated-')) return
  const generated = getGeneratedTemplate(entry.id)
  if (!generated) return
  persistGeneratedTemplate(generated, templates.templates.value, templates.setAll)
}

function onStart(entry: PlanCatalogEntry) {
  ensureGeneratedPersisted(entry)
  scheduleEntry.value = entry
  scheduleTemplate.value = resolveTemplateForEntry(entry)
  scheduleOpen.value = true
}

function onScheduleApply(payload: {
  startDateKey: string
  restDaysPerWeek: number
  restEveryWorkoutDays: number
}) {
  const entry = scheduleEntry.value
  if (!entry) return

  ensureGeneratedPersisted(entry)

  const daysPerWeek = state.answers.value.daysPerWeek ?? 3
  const ok = scheduleCatalogEntry(
    workouts,
    entry,
    templates.templates.value,
    templates.folders.value,
    {
      startDateKey: payload.startDateKey,
      daysPerWeek,
      restDaysPerWeek: payload.restDaysPerWeek,
      folderName: entry.title,
      restEveryWorkoutDays: payload.restEveryWorkoutDays,
      confirmOverwrite: (msg) => window.confirm(msg),
    },
  )

  if (!ok) {
    window.alert('Could not schedule this plan. Make sure the plan templates exist.')
    return
  }

  scheduleOpen.value = false
  scheduleEntry.value = null
  scheduleTemplate.value = null
  window.alert(`${entry.title} added to your calendar!`)
  router.push({ name: 'home' })
}

const stepTitles = [
  'How experienced are you?',
  "What's your main goal?",
  'How many days can you train?',
  'How long are your sessions?',
  'What equipment do you have?',
  'What training style do you prefer?',
]
</script>

<template>
  <div class="flex min-h-dvh flex-col bg-background">
    <header class="shrink-0 border-b border-border px-4 pb-3 pt-4">
      <div class="flex items-center justify-between gap-3">
        <button
          type="button"
          class="text-sm font-bold text-primary"
          @click="goBackNav"
        >
          ← Back
        </button>
        <span class="text-xs font-bold uppercase tracking-wide text-muted">{{ state.progressLabel.value }}</span>
      </div>
      <div class="mt-3 h-1.5 overflow-hidden rounded-full bg-card-inner">
        <div
          class="h-full rounded-full bg-primary transition-all duration-200"
          :style="{ width: `${state.progressPercent.value}%` }"
        />
      </div>
    </header>

    <main class="flex-1 overflow-y-auto px-4 py-6">
      <Transition name="pick-plan-slide" mode="out-in">
        <!-- Step 0: Experience -->
        <div v-if="state.stepIndex.value === 0" key="step-0">
          <h1 class="text-xl font-extrabold text-foreground">{{ stepTitles[0] }}</h1>
          <p class="mt-1 text-sm text-muted">We'll match plans to your experience level.</p>
          <div class="mt-5">
            <PickAPlanStepOptions
              :options="EXPERIENCE_OPTIONS"
              :selected="state.answers.value.experienceLevel"
              @select="state.selectAndAdvance('experienceLevel', $event)"
            />
          </div>
        </div>

        <!-- Step 1: Goal -->
        <div v-else-if="state.stepIndex.value === 1" key="step-1">
          <h1 class="text-xl font-extrabold text-foreground">{{ stepTitles[1] }}</h1>
          <p class="mt-1 text-sm text-muted">Pick the outcome you care about most right now.</p>
          <div class="mt-5">
            <PickAPlanStepOptions
              :options="GOAL_OPTIONS"
              :selected="state.answers.value.goal"
              @select="state.selectAndAdvance('goal', $event)"
            />
          </div>
        </div>

        <!-- Step 2: Days -->
        <div v-else-if="state.stepIndex.value === 2" key="step-2">
          <h1 class="text-xl font-extrabold text-foreground">{{ stepTitles[2] }}</h1>
          <p class="mt-1 text-sm text-muted">Be realistic — consistency beats ambition.</p>
          <div class="mt-5">
            <PickAPlanStepOptions
              :options="DAYS_OPTIONS"
              :selected="state.answers.value.daysPerWeek"
              @select="state.selectAndAdvance('daysPerWeek', $event)"
            />
          </div>
        </div>

        <!-- Step 3: Duration -->
        <div v-else-if="state.stepIndex.value === 3" key="step-3">
          <h1 class="text-xl font-extrabold text-foreground">{{ stepTitles[3] }}</h1>
          <p class="mt-1 text-sm text-muted">Include warm-up time in your estimate.</p>
          <div class="mt-5">
            <PickAPlanStepOptions
              :options="DURATION_OPTIONS"
              :selected="state.answers.value.duration"
              @select="state.selectAndAdvance('duration', $event)"
            />
          </div>
        </div>

        <!-- Step 4: Equipment -->
        <div v-else-if="state.stepIndex.value === 4" key="step-4">
          <h1 class="text-xl font-extrabold text-foreground">{{ stepTitles[4] }}</h1>
          <p class="mt-1 text-sm text-muted">We'll filter exercises to what you can actually do.</p>
          <div class="mt-5">
            <PickAPlanStepOptions
              :options="EQUIPMENT_OPTIONS"
              :selected="state.answers.value.equipment"
              @select="state.selectAndAdvance('equipment', $event)"
            />
          </div>
        </div>

        <!-- Step 5: Style -->
        <div v-else-if="state.stepIndex.value === 5" key="step-5">
          <h1 class="text-xl font-extrabold text-foreground">{{ stepTitles[5] }}</h1>
          <p class="mt-1 text-sm text-muted">How do you like to train?</p>
          <div class="mt-5">
            <PickAPlanStepOptions
              :options="STYLE_OPTIONS"
              :selected="state.answers.value.stylePreference"
              @select="state.selectAndAdvance('stylePreference', $event)"
            />
          </div>
        </div>

        <!-- Results -->
        <div v-else key="results">
          <h1 class="text-xl font-extrabold text-foreground">Your plan matches</h1>
          <p class="mt-2 text-sm leading-relaxed text-muted">{{ headline }}</p>

          <div class="mt-5 flex flex-col gap-4">
            <PlanRecommendationCard
              v-for="rec in recommendations"
              :key="rec.entry.id"
              :recommendation="rec"
              :compare-selected="compareIds.includes(rec.entry.id)"
              :compare-disabled="compareIds.length >= maxCompare"
              @start="onStart(rec.entry)"
              @preview="previewEntry = rec.entry"
              @toggle-compare="toggleCompare(rec.entry.id)"
            />
          </div>

          <div class="mt-6 flex flex-col gap-2">
            <button
              type="button"
              class="w-full rounded-lg border border-border py-3 text-sm font-bold text-foreground"
              @click="openCompare"
            >
              Compare selected ({{ compareIds.length }})
            </button>
            <button
              type="button"
              class="w-full rounded-lg border border-border py-3 text-sm font-bold text-foreground"
              @click="state.restart()"
            >
              Restart questionnaire
            </button>
            <button
              type="button"
              class="w-full rounded-lg bg-primary/15 py-3 text-sm font-bold text-primary"
              @click="router.push({ name: 'plans' })"
            >
              Browse all plans
            </button>
          </div>
        </div>
      </Transition>
    </main>

    <footer
      v-if="!state.isResults.value"
      class="shrink-0 flex items-center justify-between border-t border-border px-4 py-3"
    >
      <button
        type="button"
        class="text-sm font-bold text-muted disabled:opacity-40"
        :disabled="state.stepIndex.value === 0"
        @click="state.goBack()"
      >
        Back
      </button>
      <button
        type="button"
        class="text-sm font-bold text-primary"
        @click="state.skipStep()"
      >
        Skip
      </button>
    </footer>

    <PlanPreviewSheet
      :open="previewEntry != null"
      :entry="previewEntry"
      @close="previewEntry = null"
    />

    <PlanCompareSheet
      :open="compareOpen"
      :entries="compareEntries"
      @close="compareOpen = false"
    />

    <GuidedPlanScheduleSheet
      :open="scheduleOpen"
      :entry="scheduleEntry"
      :template="scheduleTemplate"
      :days-per-week="state.answers.value.daysPerWeek ?? 3"
      @close="scheduleOpen = false"
      @apply="onScheduleApply"
    />
  </div>
</template>
