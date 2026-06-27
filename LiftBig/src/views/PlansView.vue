<script setup lang="ts">
import { computed, inject, nextTick, onUnmounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import Sortable from 'sortablejs'
import ExerciseDetailSheet from '@/components/library/ExerciseDetailSheet.vue'
import PlanEditorModal from '@/components/plans/PlanEditorModal.vue'
import PlanShuffleModal from '@/components/plans/PlanShuffleModal.vue'
import SchedulePlanCalendarSheet from '@/components/plans/SchedulePlanCalendarSheet.vue'
import { settingsInjectionKey, templatesInjectionKey, workoutsInjectionKey } from '@/composables/injectionKeys'
import type { TemplateFolder, WorkoutTemplate } from '@/types/workout'
import { addDaysToDateKey, isValidDateKey, todayKey } from '@/utils/dateKey'
import {
  findLibraryExerciseByName,
  getLibraryExercise,
  type LibraryExercise,
} from '@/utils/exerciseLibrary'
import {
  estimatePlanDurationMinutes,
  formatPlanDurationEstimate,
  planDurationAssumptionsFromSeconds,
} from '@/utils/planDuration'
import { sortFolderPlans } from '@/utils/folderPlanSort'
import { supersetBadgeLabel } from '@/utils/supersetUtils'
import { haptic } from '@/utils/haptics'
import { formatWeightWithUnit, parseStoredLbs } from '@/utils/units'

const templates = inject(templatesInjectionKey)!
const workouts = inject(workoutsInjectionKey)!
const settings = inject(settingsInjectionKey)!
const weightUnit = computed(() => settings.weightUnit.value)
const durationAssumptions = computed(() =>
  planDurationAssumptionsFromSeconds(settings.averageLiftSeconds.value, settings.averageRestSeconds.value),
)

function formatTemplateWeight(s: string | undefined): string {
  if (!s?.trim()) return ''
  const lbs = parseStoredLbs(s)
  if (Number.isNaN(lbs)) return s
  return formatWeightWithUnit(lbs, weightUnit.value, 1)
}

const planList = computed(() => templates.templates.value)
const folders = computed(() => templates.folders.value)
const newFolderName = ref('')

const modalOpen = ref(false)
const editing = ref<WorkoutTemplate | null>(null)
const shuffleOpen = ref(false)
const scheduleOpen = ref(false)
const scheduleTemplate = ref<WorkoutTemplate | null>(null)

function openNew() {
  editing.value = null
  modalOpen.value = true
}

function openEdit(t: WorkoutTemplate) {
  editing.value = t
  modalOpen.value = true
}

function closeModal() {
  modalOpen.value = false
}

function openShuffle() {
  shuffleOpen.value = true
}

function closeShuffle() {
  shuffleOpen.value = false
}

function openScheduleToCalendar(t: WorkoutTemplate) {
  scheduleTemplate.value = t
  scheduleOpen.value = true
}

function closeScheduleSheet() {
  scheduleOpen.value = false
  scheduleTemplate.value = null
}

function onScheduleApply(payload: { startDateKey: string; restDaysPerWeek: number }) {
  if (!scheduleTemplate.value) return
  workouts.applyPlanWithWeeklyRest(
    payload.startDateKey,
    scheduleTemplate.value,
    payload.restDaysPerWeek,
  )
  closeScheduleSheet()
}

function onSave(payload: {
  id: string | null
  name: string
  exercises: import('@/types/workout').TemplateExercise[]
  prepend?: boolean
}) {
  const list = planList.value
  let next: WorkoutTemplate[]
  if (payload.id) {
    next = list.map((t) =>
      t.id === payload.id ? { ...t, name: payload.name, exercises: payload.exercises } : t,
    )
  } else {
    const newT: WorkoutTemplate = {
      id: `${Date.now()}`,
      name: payload.name,
      exercises: payload.exercises,
    }
    next = payload.prepend ? [newT, ...list] : [...list, newT]
    if (payload.prepend) {
      allPlansExpanded.value = true
      allPlansSearchQuery.value = ''
    }
  }
  templates.setAll(next)
  closeModal()
  if (payload.prepend) closeShuffle()
}

function deletePlan(id: string) {
  if (!confirm('Delete this plan?')) return
  templates.setAll(planList.value.filter((t) => t.id !== id))
}

const draggedTemplateId = ref<string | null>(null)
const dragOverFolderId = ref<string | null>(null)
const dragOverUncategorized = ref(false)
const openFolderMap = ref<Record<string, boolean>>({})
const folderPurposeDrafts = ref<Record<string, string>>({})
const folderStartDateDrafts = ref<Record<string, string>>({})
const folderRestEveryDrafts = ref<Record<string, number>>({})

/** Full catalog: order matches stored template list (reorder in All Plans or within a folder). */
const allPlansSectionList = computed(() => planList.value.slice())

const allPlansSearchQuery = ref('')
const allPlansExpanded = ref(false)

function toggleAllPlans() {
  allPlansExpanded.value = !allPlansExpanded.value
}

const allPlansSectionFiltered = computed(() => {
  const q = allPlansSearchQuery.value.trim().toLowerCase()
  if (!q) return allPlansSectionList.value
  return allPlansSectionList.value.filter((template) => {
    if (template.name.toLowerCase().includes(q)) return true
    return template.exercises.some((ex) => ex.name.toLowerCase().includes(q))
  })
})
const folderSections = computed(() =>
  folders.value.map((folder) => ({
    folder,
    plans: planList.value.filter((item) => item.folderId === folder.id),
  })),
)

function createFolder() {
  const name = newFolderName.value.trim()
  if (!name) return
  const exists = folders.value.some((folder) => folder.name.toLowerCase() === name.toLowerCase())
  if (exists) {
    window.alert('A folder with that name already exists.')
    return
  }
  const folder: TemplateFolder = {
    id: `folder-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    name,
    purpose: '',
  }
  templates.setFolders([...folders.value, folder])
  newFolderName.value = ''
}

function deleteFolder(folderId: string) {
  if (!window.confirm('Delete this folder? Plans inside will leave the folder (they stay in All Plans).')) return
  templates.setFolders(folders.value.filter((folder) => folder.id !== folderId))
  const nextPlans = planList.value.map((item) => (item.folderId === folderId ? { ...item, folderId: null } : item))
  templates.setAll(nextPlans)
  const nextOpenMap = { ...openFolderMap.value }
  delete nextOpenMap[folderId]
  openFolderMap.value = nextOpenMap
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

function folderPurposeValue(folderId: string, persistedPurpose: string | undefined): string {
  const draft = folderPurposeDrafts.value[folderId]
  if (draft !== undefined) return draft
  return persistedPurpose ?? ''
}

function onFolderPurposeInput(folderId: string, value: string) {
  folderPurposeDrafts.value = {
    ...folderPurposeDrafts.value,
    [folderId]: value,
  }
}

function saveFolderPurpose(folderId: string) {
  const nextPurpose = (folderPurposeDrafts.value[folderId] ?? '').trim()
  templates.setFolders(
    folders.value.map((folder) => (folder.id === folderId ? { ...folder, purpose: nextPurpose } : folder)),
  )
}

function folderStartDateValue(folderId: string): string {
  return folderStartDateDrafts.value[folderId] ?? todayKey()
}

function onFolderStartDateInput(folderId: string, value: string) {
  folderStartDateDrafts.value = {
    ...folderStartDateDrafts.value,
    [folderId]: value,
  }
}

function openDatePicker(inputEl: HTMLInputElement | null) {
  if (!inputEl) return
  const maybe = inputEl as HTMLInputElement & { showPicker?: () => void }
  if (typeof maybe.showPicker === 'function') {
    maybe.showPicker()
    return
  }
  inputEl.focus()
  inputEl.click()
}

function folderRestEveryValue(folderId: string): number {
  const raw = folderRestEveryDrafts.value[folderId]
  if (typeof raw !== 'number' || Number.isNaN(raw)) return 7
  return Math.min(7, Math.max(0, Math.round(raw)))
}

function onFolderRestEveryInput(folderId: string, value: string) {
  const parsed = Number.parseInt(value, 10)
  const next = Number.isNaN(parsed) ? 7 : Math.min(7, Math.max(0, parsed))
  folderRestEveryDrafts.value = {
    ...folderRestEveryDrafts.value,
    [folderId]: next,
  }
}

function onTemplateDragStart(templateId: string) {
  draggedTemplateId.value = templateId
}

function onTemplateDragEnd() {
  draggedTemplateId.value = null
  dragOverFolderId.value = null
  dragOverUncategorized.value = false
}

function onFolderDragOver(folderId: string) {
  dragOverFolderId.value = folderId
  dragOverUncategorized.value = false
}

function onFolderDrop(folderId: string) {
  const templateId = draggedTemplateId.value
  if (!templateId) return
  templates.assignTemplateFolder(templateId, folderId)
  onTemplateDragEnd()
}

function onUncategorizedDrop() {
  const templateId = draggedTemplateId.value
  if (!templateId) return
  templates.assignTemplateFolder(templateId, null)
  onTemplateDragEnd()
}

// --- Mobile tap-and-hold drag for plan names ---
const TOUCH_LONG_PRESS_MS = 450
const TOUCH_MOVE_TOLERANCE_PX = 8

const isTouchDragActive = ref(false)
let touchLongPressTimer: ReturnType<typeof setTimeout> | null = null
let touchLongPressStart: { x: number; y: number } | null = null

function clearTouchLongPressTimer() {
  if (touchLongPressTimer != null) {
    clearTimeout(touchLongPressTimer)
    touchLongPressTimer = null
  }
}

function onPlanNameTouchStart(templateId: string, ev: TouchEvent) {
  if (ev.touches.length !== 1) return
  const t = ev.touches[0]!
  touchLongPressStart = { x: t.clientX, y: t.clientY }
  clearTouchLongPressTimer()
  touchLongPressTimer = setTimeout(() => {
    activateTouchDrag(templateId)
  }, TOUCH_LONG_PRESS_MS)
}

function onPlanNameTouchMove(ev: TouchEvent) {
  if (isTouchDragActive.value) return
  if (!touchLongPressStart || ev.touches.length !== 1) return
  const t = ev.touches[0]!
  const dx = Math.abs(t.clientX - touchLongPressStart.x)
  const dy = Math.abs(t.clientY - touchLongPressStart.y)
  if (dx > TOUCH_MOVE_TOLERANCE_PX || dy > TOUCH_MOVE_TOLERANCE_PX) {
    clearTouchLongPressTimer()
    touchLongPressStart = null
  }
}

function onPlanNameTouchEnd() {
  if (isTouchDragActive.value) return
  clearTouchLongPressTimer()
  touchLongPressStart = null
}

function activateTouchDrag(templateId: string) {
  touchLongPressTimer = null
  haptic('tap')
  draggedTemplateId.value = templateId
  isTouchDragActive.value = true
  document.addEventListener('touchmove', onTouchDragMove, { passive: false })
  document.addEventListener('touchend', onTouchDragEnd)
  document.addEventListener('touchcancel', onTouchDragCancel)
}

function pickDropTargetAt(clientX: number, clientY: number) {
  const el = document.elementFromPoint(clientX, clientY)
  if (!el) return null
  const target = (el as HTMLElement).closest('[data-drop-target]')
  if (!target) return null
  return {
    kind: target.getAttribute('data-drop-target'),
    folderId: target.getAttribute('data-folder-id'),
  }
}

function onTouchDragMove(ev: TouchEvent) {
  if (!isTouchDragActive.value) return
  ev.preventDefault()
  if (ev.touches.length !== 1) return
  const t = ev.touches[0]!
  const target = pickDropTargetAt(t.clientX, t.clientY)
  if (!target) {
    dragOverFolderId.value = null
    dragOverUncategorized.value = false
    return
  }
  if (target.kind === 'folder' && target.folderId) {
    dragOverFolderId.value = target.folderId
    dragOverUncategorized.value = false
  } else if (target.kind === 'uncategorized') {
    dragOverFolderId.value = null
    dragOverUncategorized.value = true
  }
}

function onTouchDragEnd() {
  if (!isTouchDragActive.value) return
  const templateId = draggedTemplateId.value
  if (templateId) {
    if (dragOverFolderId.value) {
      templates.assignTemplateFolder(templateId, dragOverFolderId.value)
    } else if (dragOverUncategorized.value) {
      templates.assignTemplateFolder(templateId, null)
    }
  }
  finishTouchDrag()
}

function onTouchDragCancel() {
  finishTouchDrag()
}

function finishTouchDrag() {
  isTouchDragActive.value = false
  draggedTemplateId.value = null
  dragOverFolderId.value = null
  dragOverUncategorized.value = false
  touchLongPressStart = null
  clearTouchLongPressTimer()
  document.removeEventListener('touchmove', onTouchDragMove)
  document.removeEventListener('touchend', onTouchDragEnd)
  document.removeEventListener('touchcancel', onTouchDragCancel)
}

const PLAN_SORTABLE_DELAY_MS = 450
const PLAN_SORTABLE_TOUCH_THRESHOLD = 4

function reorderTemplatesForFolder(
  full: WorkoutTemplate[],
  folderId: string,
  oldIndex: number,
  newIndex: number,
): WorkoutTemplate[] {
  const indices: number[] = []
  full.forEach((t, i) => {
    if (t.folderId === folderId) indices.push(i)
  })
  if (
    oldIndex < 0 ||
    newIndex < 0 ||
    oldIndex >= indices.length ||
    newIndex >= indices.length ||
    indices.length === 0
  ) {
    return full
  }
  const group = indices.map((i) => full[i]!)
  const [moved] = group.splice(oldIndex, 1)
  group.splice(newIndex, 0, moved!)
  const next = [...full]
  indices.forEach((idx, j) => {
    next[idx] = group[j]!
  })
  return next
}

const allPlansListEl = ref<HTMLElement | null>(null)
const foldersListEl = ref<HTMLElement | null>(null)
const folderPlanListEls = new Map<string, HTMLElement>()

function setFolderPlansUlRef(folderId: string, el: unknown) {
  if (el instanceof HTMLElement) folderPlanListEls.set(folderId, el)
  else folderPlanListEls.delete(folderId)
}

let foldersSortable: Sortable | null = null
let allPlansSortable: Sortable | null = null
const folderPlanSortables = new Map<string, Sortable>()

function destroyFoldersReorderSortable() {
  foldersSortable?.destroy()
  foldersSortable = null
}

function destroyAllPlansSortable() {
  allPlansSortable?.destroy()
  allPlansSortable = null
}

function destroyFolderPlanSortables() {
  folderPlanSortables.forEach((s) => s.destroy())
  folderPlanSortables.clear()
}

function destroyAllPlansViewSortables() {
  destroyFoldersReorderSortable()
  destroyAllPlansSortable()
  destroyFolderPlanSortables()
}

function bindFoldersReorderSortable() {
  destroyFoldersReorderSortable()
  const el = foldersListEl.value
  if (!el || folderSections.value.length < 2) return
  foldersSortable = Sortable.create(el, {
    animation: 180,
    handle: '.folder-section-sort-handle',
    delay: PLAN_SORTABLE_DELAY_MS,
    delayOnTouchOnly: true,
    touchStartThreshold: PLAN_SORTABLE_TOUCH_THRESHOLD,
    ghostClass: 'folder-sortable-ghost',
    chosenClass: 'folder-sortable-chosen',
    draggable: '> section',
    onEnd(evt) {
      const oi = evt.oldIndex
      const ni = evt.newIndex
      if (oi == null || ni == null || oi === ni) return
      const next = [...folders.value]
      const [moved] = next.splice(oi, 1)
      next.splice(ni, 0, moved!)
      templates.setFolders(next)
    },
  })
}

function bindAllPlansSortable() {
  destroyAllPlansSortable()
  if (!allPlansExpanded.value || allPlansSearchQuery.value.trim()) return
  const el = allPlansListEl.value
  if (!el || allPlansSectionFiltered.value.length < 2) return
  allPlansSortable = Sortable.create(el, {
    animation: 180,
    handle: '.plan-name-sort-handle',
    delay: PLAN_SORTABLE_DELAY_MS,
    delayOnTouchOnly: true,
    touchStartThreshold: PLAN_SORTABLE_TOUCH_THRESHOLD,
    ghostClass: 'plan-sortable-ghost',
    chosenClass: 'plan-sortable-chosen',
    onEnd(evt) {
      const oi = evt.oldIndex
      const ni = evt.newIndex
      if (oi == null || ni == null || oi === ni) return
      const next = [...planList.value]
      const [moved] = next.splice(oi, 1)
      next.splice(ni, 0, moved!)
      templates.setAll(next)
    },
  })
}

function bindFolderPlanSortables() {
  destroyFolderPlanSortables()
  for (const entry of folderSections.value) {
    if (!isFolderOpen(entry.folder.id) || entry.plans.length < 2) continue
    const el = folderPlanListEls.get(entry.folder.id)
    if (!el) continue
    const folderId = entry.folder.id
    const s = Sortable.create(el, {
      animation: 180,
      handle: '.plan-name-sort-handle',
      delay: PLAN_SORTABLE_DELAY_MS,
      delayOnTouchOnly: true,
      touchStartThreshold: PLAN_SORTABLE_TOUCH_THRESHOLD,
      ghostClass: 'plan-sortable-ghost',
      chosenClass: 'plan-sortable-chosen',
      onEnd(evt) {
        const oi = evt.oldIndex
        const ni = evt.newIndex
        if (oi == null || ni == null || oi === ni) return
        templates.setAll(reorderTemplatesForFolder(planList.value, folderId, oi, ni))
      },
    })
    folderPlanSortables.set(folderId, s)
  }
}

function rebindPlansViewSortables() {
  destroyAllPlansViewSortables()
  nextTick(() => {
    bindFoldersReorderSortable()
    bindAllPlansSortable()
    bindFolderPlanSortables()
  })
}

watch(
  [
    allPlansExpanded,
    allPlansSearchQuery,
    () => planList.value.length,
    () => planList.value.map((t) => t.id).join(','),
    () => planList.value.map((t) => `${t.id}:${t.folderId ?? ''}`).join('|'),
    () => folders.value.map((f) => f.id).join(','),
    openFolderMap,
  ],
  () => {
    rebindPlansViewSortables()
  },
  { flush: 'post', immediate: true },
)

onUnmounted(() => {
  finishTouchDrag()
  destroyAllPlansViewSortables()
})

function scheduledDateForPlanIndex(startDateKey: string, planIndex: number, restEvery: number): string {
  if (restEvery <= 0) return addDaysToDateKey(startDateKey, planIndex)
  return addDaysToDateKey(startDateKey, planIndex + Math.floor(planIndex / restEvery))
}

function sortedFolderPlans(folderId: string): WorkoutTemplate[] {
  return sortFolderPlans(planList.value.filter((item) => item.folderId === folderId))
}

function isLikelyDuplicatePlanAssignment(dateKey: string, plan: WorkoutTemplate): boolean {
  const existingNames = new Set(workouts.getDay(dateKey).map((ex) => ex.name.trim().toLowerCase()))
  const planNames = plan.exercises.map((ex) => ex.name.trim().toLowerCase()).filter(Boolean)
  if (planNames.length === 0) return false
  return planNames.every((name) => existingNames.has(name))
}

function assignFolderPlansToCalendar(folderId: string) {
  const folderName = folders.value.find((folder) => folder.id === folderId)?.name ?? 'Folder'
  const plans = sortedFolderPlans(folderId)

  if (plans.length === 0) {
    window.alert('This folder has no plans to assign.')
    return
  }

  const startDateKey = folderStartDateValue(folderId)
  if (!isValidDateKey(startDateKey)) {
    window.alert('Please choose a valid start date.')
    return
  }

  const restEvery = folderRestEveryValue(folderId)

  const finalConfirm = window.confirm(
    `Add "${folderName}" to your calendar starting ${startDateKey}? This will schedule ${plans.length} plan${plans.length === 1 ? '' : 's'}.`,
  )
  if (!finalConfirm) return

  const workoutAssignments = plans.map((plan, idx) => ({
    plan,
    dateKey: scheduledDateForPlanIndex(startDateKey, idx, restEvery),
  }))

  const restDateKeys: string[] = []
  for (let i = 0; i < plans.length - 1; i++) {
    if (restEvery > 0 && (i + 1) % restEvery === 0) {
      restDateKeys.push(addDaysToDateKey(workoutAssignments[i]!.dateKey, 1))
    }
  }

  const duplicateHits = workoutAssignments.filter((slot) =>
    isLikelyDuplicatePlanAssignment(slot.dateKey, slot.plan),
  )
  if (duplicateHits.length > 0) {
    window.alert(
      'This folder appears to already be assigned for one or more of those dates. Duplicate assignment was cancelled.',
    )
    return
  }

  const touchedKeys = new Set<string>()
  workoutAssignments.forEach((s) => touchedKeys.add(s.dateKey))
  restDateKeys.forEach((k) => touchedKeys.add(k))

  const hasExistingWorkouts = [...touchedKeys].some((key) => {
    if (workouts.isRestDay(key)) return false
    return workouts.getDay(key).length > 0
  })
  if (hasExistingWorkouts) {
    const proceed = window.confirm(
      'Some of these dates already have workouts logged. Continue and append these plans anyway?',
    )
    if (!proceed) return
  }

  for (const key of touchedKeys) {
    const n = workouts.getDay(key).length
    if (n >= 5) {
      const proceed = window.confirm(
        `It looks like you already have ${n} workouts on this date. Are you sure you want to add more?`,
      )
      if (!proceed) return
    }
  }

  for (const restKey of restDateKeys) {
    if (workouts.getDay(restKey).length === 0 && !workouts.isRestDay(restKey)) {
      workouts.markRestDay(restKey)
    }
  }

  for (const slot of workoutAssignments) {
    workouts.assignPlanToDate(slot.dateKey, slot.plan, folderName)
  }

  window.alert(
    restEvery > 0
      ? `${folderName} successfully added to calendar. Assigned ${plans.length} plan${plans.length === 1 ? '' : 's'} starting ${startDateKey} with 1 rest day every ${restEvery} workout day${restEvery === 1 ? '' : 's'}.`
      : `${folderName} successfully added to calendar. Assigned ${plans.length} plan${plans.length === 1 ? '' : 's'} starting ${startDateKey} with no auto-inserted rest days.`,
  )
}

const detailOpen = ref(false)
const detailExercise = ref<LibraryExercise | null>(null)

function resolveLibraryEntry(ex: {
  libraryId?: string
  name?: string
}): LibraryExercise | null {
  if (ex.libraryId) {
    const byId = getLibraryExercise(ex.libraryId)
    if (byId) return byId
  }
  return findLibraryExerciseByName(ex.name) ?? null
}

function openLibraryDetailFor(ex: { libraryId?: string; name?: string }) {
  const entry = resolveLibraryEntry(ex)
  if (!entry) return
  detailExercise.value = entry
  detailOpen.value = true
}

function closeLibraryDetail() {
  detailOpen.value = false
  detailExercise.value = null
}

function planDurationLabel(t: WorkoutTemplate): string {
  return formatPlanDurationEstimate(estimatePlanDurationMinutes(t, durationAssumptions.value))
}

function onPlansLiftSecondsChange(ev: Event) {
  const raw = Number((ev.target as HTMLInputElement).value)
  settings.setAverageLiftSeconds(Number.isFinite(raw) ? raw : 60)
}

function onPlansRestSecondsChange(ev: Event) {
  const raw = Number((ev.target as HTMLInputElement).value)
  settings.setAverageRestSeconds(Number.isFinite(raw) ? raw : 60)
}
</script>

<template>
  <div>
    <header class="mb-4 border-b border-border pb-3">
      <div class="flex flex-wrap items-center justify-between gap-2 sm:gap-3">
        <p class="min-w-0 text-lg font-bold tracking-[0.2em] text-muted sm:text-xl">
          Workout plans
        </p>
        <div class="flex flex-wrap items-center justify-end gap-2">
          <button
            type="button"
            class="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-bold text-primary hover:border-primary"
            @click="openShuffle"
          >
            <i class="fa-solid fa-shuffle" aria-hidden="true" />
            Shuffle
          </button>
          <RouterLink
            to="/library"
            class="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-bold text-primary hover:border-primary"
          >
            <i class="fa-solid fa-book" aria-hidden="true" />
            Library
          </RouterLink>
        </div>
      </div>
    </header>

    <div class="mb-3 flex flex-wrap items-center justify-between gap-3">
      <button
        type="button"
        class="inline-flex w-fit items-center rounded-full bg-primary px-6 py-3 text-sm font-extrabold tracking-wide text-foreground shadow-lg"
        @click="openNew"
      >
        + New Plan
      </button>
      <div class="flex flex-wrap items-center gap-3 sm:shrink-0">
        <label class="flex items-center gap-1.5 text-[10px] font-semibold text-muted">
          <span class="whitespace-nowrap">Lift / set</span>
          <input
            type="number"
            min="5"
            max="600"
            step="5"
            class="w-[4.25rem] rounded-lg border border-border bg-card-inner px-2 py-1.5 text-xs tabular-nums text-foreground outline-none focus:border-primary"
            :value="settings.averageLiftSeconds.value"
            aria-label="Seconds per set for time estimates"
            @change="onPlansLiftSecondsChange"
          />
          <span class="tabular-nums">s</span>
        </label>
        <label class="flex items-center gap-1.5 text-[10px] font-semibold text-muted">
          <span class="whitespace-nowrap">Rest</span>
          <input
            type="number"
            min="5"
            max="600"
            step="5"
            class="w-[4.25rem] rounded-lg border border-border bg-card-inner px-2 py-1.5 text-xs tabular-nums text-foreground outline-none focus:border-primary"
            :value="settings.averageRestSeconds.value"
            aria-label="Average rest seconds for time estimates"
            @change="onPlansRestSecondsChange"
          />
          <span class="tabular-nums">s</span>
        </label>
      </div>
    </div>

    <div v-if="planList.length === 0" class="mb-3 py-12 text-center">
      <p class="text-lg font-bold text-foreground">No plans yet.</p>
      <p class="mt-2 text-sm text-muted">Create a template to reuse across your calendar.</p>
    </div>

    <div v-else class="mb-3">
      <section
        data-drop-target="uncategorized"
        class="rounded-xl border border-dashed p-3"
        :class="dragOverUncategorized ? 'border-primary bg-card-inner/80' : 'border-border bg-card-inner/30'"
        @dragover.prevent="dragOverUncategorized = true"
        @dragleave="dragOverUncategorized = false"
        @drop.prevent="onUncategorizedDrop"
      >
        <div class="mb-2 flex flex-wrap items-center justify-between gap-2">
          <button
            type="button"
            class="flex min-w-0 flex-1 items-center gap-2 rounded-lg py-1 text-left outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 focus-visible:ring-offset-background"
            :aria-expanded="allPlansExpanded"
            aria-controls="all-plans-panel"
            :aria-label="allPlansExpanded ? 'Collapse all plans list' : 'Expand all plans list'"
            @click="toggleAllPlans"
          >
            <span
              class="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded border border-border text-[10px] text-muted"
              aria-hidden="true"
            >
              <i
                class="fa-solid"
                :class="allPlansExpanded ? 'fa-chevron-up' : 'fa-chevron-down'"
              />
            </span>
            <span class="min-w-0">
              <span class="block text-sm font-extrabold text-foreground">All Plans</span>
            </span>
          </button>
          <span class="text-[10px] font-bold uppercase tracking-wide text-muted">
            <template v-if="allPlansExpanded">
              {{ allPlansSectionFiltered.length
              }}<template v-if="allPlansSearchQuery.trim()"> / {{ allPlansSectionList.length }}</template>
            </template>
            <template v-else>
              {{ allPlansSectionList.length }}
            </template>
          </span>
        </div>
        <p v-if="!allPlansExpanded" class="text-xs text-muted">
          Tap <span class="font-semibold text-foreground">All Plans</span> to search and manage every plan. Drag a plan
          here to remove it from a folder. Use the folder icon on a card to drag a plan into a folder; tap and hold a
          plan name to reorder.
        </p>
        <div id="all-plans-panel">
          <template v-if="allPlansExpanded">
          <label class="sr-only" for="all-plans-search">Search all plans</label>
          <input
            id="all-plans-search"
            v-model="allPlansSearchQuery"
            type="search"
            class="mb-3 w-full rounded-lg border border-border bg-card-inner px-3 py-2 text-xs text-foreground outline-none focus:border-primary"
            placeholder="Search plans by name or exercise…"
            autocomplete="off"
          />
          <p v-if="allPlansSectionFiltered.length === 0" class="py-2 text-xs text-muted">
            No plans match your search.
          </p>
          <ul v-else ref="allPlansListEl" class="flex flex-col gap-3">
            <li
              v-for="item in allPlansSectionFiltered"
              :key="item.id"
              class="rounded-xl border border-border bg-card p-4 transition-opacity"
              :class="
                isTouchDragActive && draggedTemplateId === item.id
                  ? 'opacity-60 ring-2 ring-primary'
                  : ''
              "
            >
              <div class="flex items-start justify-between gap-2">
                <div class="flex min-w-0 flex-1 items-start gap-2">
                  <span
                    class="plan-to-folder-drag mt-0.5 inline-flex shrink-0 cursor-grab touch-manipulation select-none text-muted hover:text-primary"
                    draggable="true"
                    title="Drag into a folder, or tap and hold then move (mobile)"
                    aria-label="Drag plan into a folder"
                    @dragstart="onTemplateDragStart(item.id)"
                    @dragend="onTemplateDragEnd"
                    @touchstart.passive="onPlanNameTouchStart(item.id, $event)"
                    @touchmove="onPlanNameTouchMove($event)"
                    @touchend="onPlanNameTouchEnd"
                    @touchcancel="onPlanNameTouchEnd"
                  >
                    <i class="fa-solid fa-folder-open text-base" aria-hidden="true" />
                  </span>
                  <h3
                    class="plan-name-sort-handle min-w-0 cursor-grab select-none text-lg font-extrabold text-foreground active:cursor-grabbing"
                    title="Tap and hold to reorder plans"
                  >
                    {{ item.name }}
                  </h3>
                </div>
                <div class="flex shrink-0 flex-wrap justify-end gap-2">
                  <button
                    type="button"
                    class="rounded-lg border border-border px-3 py-1 text-xs font-bold text-teal-200 hover:border-teal-700"
                    @click="openScheduleToCalendar(item)"
                  >
                    Calendar
                  </button>
                  <button
                    type="button"
                    class="rounded-lg bg-blue px-3 py-1 text-xs font-bold text-foreground"
                    @click="openEdit(item)"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    class="rounded-lg border border-red-900/50 px-3 py-1 text-xs font-bold text-red-400"
                    @click="deletePlan(item.id)"
                  >
                    Delete
                  </button>
                </div>
              </div>
              <p class="mt-1 text-xs text-muted">
                {{ item.exercises.length }} exercise{{ item.exercises.length !== 1 ? 's' : '' }}
                · {{ planDurationLabel(item) }}
              </p>
              <p
                v-if="item.notes?.trim()"
                class="mt-2 whitespace-pre-line rounded-lg border border-border bg-card-inner/60 px-2.5 py-2 text-xs leading-relaxed text-foreground"
              >
                {{ item.notes }}
              </p>
              <ul class="mt-2 space-y-1 border-t border-border pt-2">
                <li
                  v-for="ex in item.exercises"
                  :key="ex.id"
                  class="flex flex-wrap items-center gap-2 text-sm text-foreground"
                >
                  <span class="text-muted">·</span>
                  <span class="font-semibold">{{ ex.name }}</span>
                  <span
                    v-if="supersetBadgeLabel(ex)"
                    class="rounded bg-primary/15 px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-primary"
                  >
                    {{ supersetBadgeLabel(ex) }}
                  </span>
                  <button
                    v-if="resolveLibraryEntry(ex)"
                    type="button"
                    class="text-primary hover:text-foreground"
                    aria-label="How to perform this exercise"
                    @click="openLibraryDetailFor(ex)"
                  >
                    <i class="fa-solid fa-circle-info text-xs" aria-hidden="true" />
                  </button>
                  <span class="text-muted">
                    {{ ex.sets.length }} × {{ ex.sets[0]?.targetReps || '?' }}
                    <template v-if="ex.sets[0]?.targetWeight">
                      @ {{ formatTemplateWeight(ex.sets[0].targetWeight) }}
                    </template>
                  </span>
                </li>
              </ul>
            </li>
          </ul>
          </template>
        </div>
      </section>
    </div>

    <section class="mb-3 space-y-3">
      <header class="border-t border-b border-border py-3">
        <p class="min-w-0 text-lg font-bold tracking-[0.2em] text-muted sm:text-xl">
          Folders
        </p>
        <p class="mt-2 text-xs text-muted sm:text-sm">
          Drag plans into folders to organize split days. Tap and hold a folder name to reorder folders; tap and hold a
          plan name to reorder plans inside a folder or in All Plans.
        </p>
      </header>
      <div class="flex flex-wrap items-center gap-2">
        <input
          v-model="newFolderName"
          type="text"
          class="w-40 rounded-lg border border-border bg-card-inner px-2.5 py-2 text-xs text-foreground outline-none focus:border-primary"
          placeholder="New folder name"
          @keyup.enter="createFolder"
        />
        <button
          type="button"
          class="inline-flex w-fit items-center rounded-full bg-primary px-6 py-3 text-sm font-extrabold tracking-wide text-foreground shadow-lg"
          @click="createFolder"
        >
          + New Folder
        </button>
      </div>
      <div ref="foldersListEl" class="flex flex-col gap-3">
      <section
        v-for="entry in folderSections"
        :key="entry.folder.id"
        data-drop-target="folder"
        :data-folder-id="entry.folder.id"
        class="rounded-xl border border-dashed p-3"
        :class="dragOverFolderId === entry.folder.id ? 'border-primary bg-card-inner/80' : 'border-border bg-card-inner/30'"
        @dragover.prevent="onFolderDragOver(entry.folder.id)"
        @dragleave="dragOverFolderId = null"
        @drop.prevent="onFolderDrop(entry.folder.id)"
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
            <h2 class="folder-section-sort-handle cursor-grab select-none text-sm font-extrabold text-foreground">
              {{ entry.folder.name }}
            </h2>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold uppercase tracking-wide text-muted">
              {{ entry.plans.length }}
            </span>
            <button
              type="button"
              class="rounded border border-red-900/50 px-2 py-1 text-[10px] font-bold text-red-400"
              @click="deleteFolder(entry.folder.id)"
            >
              Delete Folder
            </button>
          </div>
        </div>
        <p v-if="entry.plans.length === 0" class="text-xs text-muted">
          Drop a plan here.
        </p>
        <p v-else-if="!isFolderOpen(entry.folder.id)" class="text-xs text-muted">
          Click to view plan and explanation.
        </p>
        <div v-else class="flex flex-col gap-3">
          <div class="rounded-lg border border-border bg-card-inner/60 p-3">
            <label class="mb-1 block text-[10px] font-bold uppercase tracking-wide text-muted">
              Folder purpose / explanation
            </label>
            <textarea
              :value="folderPurposeValue(entry.folder.id, entry.folder.purpose)"
              rows="3"
              class="w-full rounded-lg border border-border bg-card px-2.5 py-2 text-xs text-foreground outline-none focus:border-primary"
              placeholder="Explain goals, progression, and how this folder should be used."
              @input="onFolderPurposeInput(entry.folder.id, ($event.target as HTMLTextAreaElement).value)"
              @blur="saveFolderPurpose(entry.folder.id)"
            />
          </div>
          <div class="rounded-lg border border-border bg-card-inner/40 p-2">
            <div class="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-center">
              <label class="text-[10px] font-bold uppercase tracking-wide text-muted">Start day</label>
              <input
                :value="folderStartDateValue(entry.folder.id)"
                type="date"
                class="rounded border border-border bg-card px-2 py-1 text-xs text-foreground outline-none focus:border-primary"
                @focus="openDatePicker($event.target as HTMLInputElement)"
                @input="onFolderStartDateInput(entry.folder.id, ($event.target as HTMLInputElement).value)"
              />
              <div class="min-w-[180px] rounded border border-border bg-card px-2 py-1">
                <label class="block text-[10px] font-bold uppercase tracking-wide text-muted">
                  {{
                    folderRestEveryValue(entry.folder.id) === 0
                      ? 'No auto rest days'
                      : `Rest day every ${folderRestEveryValue(entry.folder.id)} workout day${folderRestEveryValue(entry.folder.id) === 1 ? '' : 's'}`
                  }}
                </label>
                <input
                  :value="folderRestEveryValue(entry.folder.id)"
                  type="range"
                  min="0"
                  max="7"
                  step="1"
                  class="mt-1 w-full accent-primary"
                  @input="onFolderRestEveryInput(entry.folder.id, ($event.target as HTMLInputElement).value)"
                />
              </div>
              <button
                type="button"
                class="rounded border border-primary/50 bg-card px-2.5 py-1 text-xs font-bold text-primary hover:border-primary"
                @click="assignFolderPlansToCalendar(entry.folder.id)"
              >
                Add Folder to Calendar
              </button>
            </div>
          </div>
          <ul
            :ref="(el) => setFolderPlansUlRef(entry.folder.id, el)"
            class="flex flex-col gap-3"
          >
            <li
              v-for="item in sortedFolderPlans(entry.folder.id)"
              :key="item.id"
              class="rounded-xl border border-border bg-card p-4 transition-opacity"
              :class="
                isTouchDragActive && draggedTemplateId === item.id
                  ? 'opacity-60 ring-2 ring-primary'
                  : ''
              "
            >
              <div class="flex items-start justify-between gap-2">
                <div class="flex min-w-0 flex-1 items-start gap-2">
                  <span
                    class="plan-to-folder-drag mt-0.5 inline-flex shrink-0 cursor-grab touch-manipulation select-none text-muted hover:text-primary"
                    draggable="true"
                    title="Drag into a folder, or tap and hold then move (mobile)"
                    aria-label="Drag plan into a folder"
                    @dragstart="onTemplateDragStart(item.id)"
                    @dragend="onTemplateDragEnd"
                    @touchstart.passive="onPlanNameTouchStart(item.id, $event)"
                    @touchmove="onPlanNameTouchMove($event)"
                    @touchend="onPlanNameTouchEnd"
                    @touchcancel="onPlanNameTouchEnd"
                  >
                    <i class="fa-solid fa-folder-open text-base" aria-hidden="true" />
                  </span>
                  <h3
                    class="plan-name-sort-handle min-w-0 cursor-grab select-none text-lg font-extrabold text-foreground active:cursor-grabbing"
                    title="Tap and hold to reorder plans"
                  >
                    {{ item.name }}
                  </h3>
                </div>
                <div class="flex shrink-0 flex-wrap justify-end gap-2">
                  <button
                    type="button"
                    class="rounded-lg border border-border px-3 py-1 text-xs font-bold text-teal-200 hover:border-teal-700"
                    @click="openScheduleToCalendar(item)"
                  >
                    Calendar
                  </button>
                  <button
                    type="button"
                    class="rounded-lg bg-blue px-3 py-1 text-xs font-bold text-foreground"
                    @click="openEdit(item)"
                  >
                    Edit
                  </button>
                  <button
                    type="button"
                    class="rounded-lg border border-red-900/50 px-3 py-1 text-xs font-bold text-red-400"
                    @click="deletePlan(item.id)"
                  >
                    Delete
                  </button>
                </div>
              </div>
              <p class="mt-1 text-xs text-muted">
                {{ item.exercises.length }} exercise{{ item.exercises.length !== 1 ? 's' : '' }}
                · {{ planDurationLabel(item) }}
              </p>
              <p
                v-if="item.notes?.trim()"
                class="mt-2 whitespace-pre-line rounded-lg border border-border bg-card-inner/60 px-2.5 py-2 text-xs leading-relaxed text-foreground"
              >
                {{ item.notes }}
              </p>
              <ul class="mt-2 space-y-1 border-t border-border pt-2">
                <li
                  v-for="ex in item.exercises"
                  :key="ex.id"
                  class="flex flex-wrap items-center gap-2 text-sm text-foreground"
                >
                  <span class="text-muted">·</span>
                  <span class="font-semibold">{{ ex.name }}</span>
                  <span
                    v-if="supersetBadgeLabel(ex)"
                    class="rounded bg-primary/15 px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-primary"
                  >
                    {{ supersetBadgeLabel(ex) }}
                  </span>
                  <button
                    v-if="resolveLibraryEntry(ex)"
                    type="button"
                    class="text-primary hover:text-foreground"
                    aria-label="How to perform this exercise"
                    @click="openLibraryDetailFor(ex)"
                  >
                    <i class="fa-solid fa-circle-info text-xs" aria-hidden="true" />
                  </button>
                  <span class="text-muted">
                    {{ ex.sets.length }} × {{ ex.sets[0]?.targetReps || '?' }}
                    <template v-if="ex.sets[0]?.targetWeight">
                      @ {{ formatTemplateWeight(ex.sets[0].targetWeight) }}
                    </template>
                  </span>
                </li>
              </ul>
            </li>
          </ul>
        </div>
      </section>
      </div>
    </section>

    <PlanEditorModal
      :weight-unit="weightUnit"
      :show="modalOpen"
      :initial="editing"
      @close="closeModal"
      @save="onSave"
    />

    <PlanShuffleModal :show="shuffleOpen" @close="closeShuffle" @save="onSave" />

    <SchedulePlanCalendarSheet
      :open="scheduleOpen"
      :template="scheduleTemplate"
      @close="closeScheduleSheet"
      @apply="onScheduleApply"
    />

    <ExerciseDetailSheet
      :open="detailOpen"
      :exercise="detailExercise"
      @close="closeLibraryDetail"
    />
  </div>
</template>
