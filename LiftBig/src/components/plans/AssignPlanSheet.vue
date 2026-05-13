<script setup lang="ts">
import { computed, inject, ref, watch } from 'vue'
import ExerciseDetailSheet from '@/components/library/ExerciseDetailSheet.vue'
import { settingsInjectionKey, templatesInjectionKey } from '@/composables/injectionKeys'
import type { WorkoutTemplate } from '@/types/workout'
import { getLibraryExercise, type LibraryExercise } from '@/utils/exerciseLibrary'
import {
  estimatePlanDurationMinutes,
  formatPlanDurationEstimate,
  planDurationAssumptionsFromSeconds,
} from '@/utils/planDuration'
import { formatWeightWithUnit, parseStoredLbs } from '@/utils/units'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  close: []
  pick: [payload: { template: WorkoutTemplate; restDaysPerWeek: number; folderName?: string }]
}>()

const templatesApi = inject(templatesInjectionKey)!
const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)
const searchQuery = ref('')
const openFolderMap = ref<Record<string, boolean>>({})
const restDaysPerWeek = ref(0)

const detailOpen = ref(false)
const detailExercise = ref<LibraryExercise | null>(null)

function openLibraryDetail(libraryId: string | undefined) {
  if (!libraryId) return
  const entry = getLibraryExercise(libraryId)
  if (!entry) return
  detailExercise.value = entry
  detailOpen.value = true
}

function closeLibraryDetail() {
  detailOpen.value = false
  detailExercise.value = null
}

const durationAssumptions = computed(() =>
  planDurationAssumptionsFromSeconds(settings.averageLiftSeconds.value, settings.averageRestSeconds.value),
)

function formatTemplateWeight(s: string | undefined): string {
  if (!s?.trim()) return ''
  const lbs = parseStoredLbs(s)
  if (Number.isNaN(lbs)) return s
  return formatWeightWithUnit(lbs, weightUnit.value, 1)
}

const planList = computed(() => templatesApi.templates.value)
const folders = computed(() => templatesApi.folders.value)

const filteredTemplates = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return planList.value
  return planList.value.filter((template) => {
    if (template.name.toLowerCase().includes(q)) return true
    return template.exercises.some((ex) => ex.name.toLowerCase().includes(q))
  })
})

/** Same grouping as Plans tab: list every folder; plans respect search filter. */
const folderSections = computed(() =>
  folders.value.map((folder) => ({
    folder,
    plans: filteredTemplates.value.filter((t) => t.folderId === folder.id),
  })),
)

/** Every matching plan appears here even when also listed under a folder. */
const allPlansPickerList = computed(() =>
  filteredTemplates.value.slice().sort((a, b) => a.name.localeCompare(b.name)),
)

function folderPlanSortKey(name: string): [number, number, string] {
  const weekMatch = /week\s+(\d+)/i.exec(name)
  const dayMatch = /day\s+(\d+)/i.exec(name)
  const week = weekMatch ? Number.parseInt(weekMatch[1]!, 10) : Number.MAX_SAFE_INTEGER
  const day = dayMatch ? Number.parseInt(dayMatch[1]!, 10) : Number.MAX_SAFE_INTEGER
  return [week, day, name.toLowerCase()]
}

function sortedPlans(plans: WorkoutTemplate[]): WorkoutTemplate[] {
  return plans.slice().sort((a, b) => {
    const [aw, ad, an] = folderPlanSortKey(a.name)
    const [bw, bd, bn] = folderPlanSortKey(b.name)
    if (aw !== bw) return aw - bw
    if (ad !== bd) return ad - bd
    return an.localeCompare(bn)
  })
}

function isFolderOpen(folderId: string): boolean {
  return openFolderMap.value[folderId] === true
}

function toggleFolder(folderId: string) {
  openFolderMap.value = {
    ...openFolderMap.value,
    [folderId]: !isFolderOpen(folderId),
  }
}

function planDurationLabel(t: WorkoutTemplate): string {
  return formatPlanDurationEstimate(estimatePlanDurationMinutes(t, durationAssumptions.value))
}

function choose(t: WorkoutTemplate) {
  const folder = t.folderId ? folders.value.find((f) => f.id === t.folderId) : undefined
  emit('pick', { template: t, restDaysPerWeek: restDaysPerWeek.value, folderName: folder?.name })
}

watch(
  () => props.open,
  (open) => {
    if (open) {
      searchQuery.value = ''
      openFolderMap.value = {}
      restDaysPerWeek.value = 0
    }
    closeLibraryDetail()
  },
)
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      class="fixed inset-0 z-50 flex flex-col justify-end bg-black/65"
      role="dialog"
      aria-modal="true"
      @click.self="emit('close')"
    >
      <div
        class="max-h-[70vh] overflow-y-auto rounded-t-2xl border border-border border-b-0 bg-card px-4 pb-8 pt-2"
        @click.stop
      >
        <div class="mx-auto mb-3 h-1 w-10 rounded-full bg-border" />
        <h3 class="text-center text-lg font-extrabold text-foreground">Choose a Plan</h3>
        <p class="mb-3 text-center text-xs text-muted">
          <template v-if="restDaysPerWeek === 0">
            Exercises will be appended to this day only.
          </template>
          <template v-else>
            Through the end of this month, each 7-day block from this day gets the plan on training days and logged rest
            days on the others (only empty days are filled).
          </template>
          <span class="mt-1 block text-[10px] opacity-90">
            Times shown: ~{{ settings.averageLiftSeconds.value }}s per set + ~{{
              settings.averageRestSeconds.value
            }}s rest.
          </span>
        </p>

        <div class="mb-4 rounded-xl border border-border bg-card-inner px-3 py-3">
          <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">
            Rest days per 7-day block
          </label>
          <div class="mt-2 flex items-center gap-3">
            <input
              v-model.number="restDaysPerWeek"
              type="range"
              min="0"
              max="6"
              step="1"
              class="min-w-0 flex-1 accent-primary"
            />
            <span class="w-6 text-center text-sm font-black text-foreground">{{ restDaysPerWeek }}</span>
          </div>
          <p class="mt-2 text-[10px] leading-snug text-muted">
            0 = this day only. 1–6 = spread across each week: earlier days in the block are training days (plan applied),
            remaining days are rest days for consistency.
          </p>
        </div>

        <input
          v-model="searchQuery"
          type="text"
          class="mb-3 w-full rounded-lg border border-border bg-card-inner px-3 py-2 text-sm text-foreground outline-none focus:border-primary"
          placeholder="Search plans or exercises..."
        />
        <p v-if="filteredTemplates.length === 0" class="mb-3 text-center text-xs text-muted">
          No matching plans.
        </p>

        <div v-else class="space-y-3">
          <section
            v-for="entry in folderSections"
            :key="entry.folder.id"
            class="rounded-xl border border-dashed border-border bg-card-inner/30 p-3"
          >
            <div class="mb-2 flex items-center justify-between gap-2">
              <div class="flex items-center gap-2">
                <button
                  type="button"
                  class="inline-flex h-6 w-6 items-center justify-center rounded border border-border text-[10px] text-muted hover:border-primary hover:text-primary"
                  :aria-label="isFolderOpen(entry.folder.id) ? 'Collapse folder' : 'Expand folder'"
                  @click="toggleFolder(entry.folder.id)"
                >
                  <i
                    class="fa-solid"
                    :class="isFolderOpen(entry.folder.id) ? 'fa-chevron-up' : 'fa-chevron-down'"
                    aria-hidden="true"
                  />
                </button>
                <h2 class="text-sm font-extrabold text-foreground">{{ entry.folder.name }}</h2>
              </div>
              <span class="text-[10px] font-bold uppercase tracking-wide text-muted">
                {{ entry.plans.length }}
              </span>
            </div>
            <p
              v-if="!isFolderOpen(entry.folder.id) && entry.plans.length === 0 && !searchQuery.trim()"
              class="text-xs text-muted"
            >
              No plans in this folder.
            </p>
            <p
              v-else-if="!isFolderOpen(entry.folder.id) && entry.plans.length === 0 && searchQuery.trim()"
              class="text-xs text-muted"
            >
              No matching plans.
            </p>
            <p v-else-if="!isFolderOpen(entry.folder.id)" class="text-xs text-muted">
              Click to view plan and explanation.
            </p>
            <p
              v-else-if="isFolderOpen(entry.folder.id) && entry.plans.length === 0 && searchQuery.trim()"
              class="text-xs text-muted"
            >
              No matching plans in this folder.
            </p>
            <p
              v-else-if="isFolderOpen(entry.folder.id) && entry.plans.length === 0"
              class="text-xs text-muted"
            >
              No plans in this folder.
            </p>
            <ul v-else class="space-y-2">
              <li v-for="t in sortedPlans(entry.plans)" :key="t.id">
                <button
                  type="button"
                  class="w-full rounded-xl border border-border bg-card-inner px-3 py-3 text-left hover:border-primary"
                  @click="choose(t)"
                >
                  <div class="flex items-center justify-between gap-2">
                    <div class="min-w-0 flex-1">
                      <div class="font-bold text-foreground">{{ t.name }}</div>
                      <div class="text-xs text-muted">
                        {{ t.exercises.length }} exercise{{ t.exercises.length !== 1 ? 's' : '' }}
                        · {{ planDurationLabel(t) }}
                      </div>
                    </div>
                    <span class="shrink-0 text-xl text-primary">›</span>
                  </div>
                  <ul class="mt-2 space-y-1 border-t border-border pt-2">
                    <li
                      v-for="ex in t.exercises"
                      :key="ex.id"
                      class="flex flex-wrap items-center gap-2 text-sm text-foreground"
                    >
                      <span class="text-muted">·</span>
                      <span class="font-semibold">{{ ex.name }}</span>
                      <button
                        v-if="ex.libraryId && getLibraryExercise(ex.libraryId)"
                        type="button"
                        class="text-primary hover:text-foreground"
                        aria-label="How to perform this exercise"
                        @click.stop="openLibraryDetail(ex.libraryId)"
                      >
                        <i class="fa-solid fa-circle-info text-xs" aria-hidden="true" />
                      </button>
                      <span class="text-xs text-muted">
                        {{ ex.sets.length }} × {{ ex.sets[0]?.targetReps || '?' }}
                        <template v-if="ex.sets[0]?.targetWeight">
                          @ {{ formatTemplateWeight(ex.sets[0].targetWeight) }}
                        </template>
                      </span>
                    </li>
                  </ul>
                </button>
              </li>
            </ul>
          </section>

          <section class="rounded-xl border border-dashed border-border bg-card-inner/30 p-3">
            <div class="mb-2 flex items-center justify-between gap-2">
              <h2 class="text-sm font-extrabold text-foreground">All Plans</h2>
              <span class="text-[10px] font-bold uppercase tracking-wide text-muted">
                {{ allPlansPickerList.length }}
              </span>
            </div>
            <ul class="space-y-2">
              <li v-for="t in allPlansPickerList" :key="t.id">
                <button
                  type="button"
                  class="w-full rounded-xl border border-border bg-card-inner px-3 py-3 text-left hover:border-primary"
                  @click="choose(t)"
                >
                  <div class="flex items-center justify-between gap-2">
                    <div class="min-w-0 flex-1">
                      <div class="font-bold text-foreground">{{ t.name }}</div>
                      <div class="text-xs text-muted">
                        {{ t.exercises.length }} exercise{{ t.exercises.length !== 1 ? 's' : '' }}
                        · {{ planDurationLabel(t) }}
                      </div>
                    </div>
                    <span class="shrink-0 text-xl text-primary">›</span>
                  </div>
                  <ul class="mt-2 space-y-1 border-t border-border pt-2">
                    <li
                      v-for="ex in t.exercises"
                      :key="ex.id"
                      class="flex flex-wrap items-center gap-2 text-sm text-foreground"
                    >
                      <span class="text-muted">·</span>
                      <span class="font-semibold">{{ ex.name }}</span>
                      <button
                        v-if="ex.libraryId && getLibraryExercise(ex.libraryId)"
                        type="button"
                        class="text-primary hover:text-foreground"
                        aria-label="How to perform this exercise"
                        @click.stop="openLibraryDetail(ex.libraryId)"
                      >
                        <i class="fa-solid fa-circle-info text-xs" aria-hidden="true" />
                      </button>
                      <span class="text-xs text-muted">
                        {{ ex.sets.length }} × {{ ex.sets[0]?.targetReps || '?' }}
                        <template v-if="ex.sets[0]?.targetWeight">
                          @ {{ formatTemplateWeight(ex.sets[0].targetWeight) }}
                        </template>
                      </span>
                    </li>
                  </ul>
                </button>
              </li>
            </ul>
          </section>
        </div>
      </div>
    </div>

    <ExerciseDetailSheet :open="detailOpen" :exercise="detailExercise" @close="closeLibraryDetail" />
  </Teleport>
</template>
