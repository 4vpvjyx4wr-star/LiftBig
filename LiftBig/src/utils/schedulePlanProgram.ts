import type { PlanCatalogEntry } from '@/types/planCatalog'
import type { TemplateFolder, WorkoutTemplate } from '@/types/workout'
import { addDaysToDateKey } from '@/utils/dateKey'
import { sortFolderPlans } from '@/utils/folderPlanSort'

export type ScheduleWorkoutsApi = {
  getDay: (dateKey: string) => unknown[]
  isRestDay: (dateKey: string) => boolean
  markRestDay: (dateKey: string) => void
  assignPlanToDate: (dateKey: string, template: WorkoutTemplate, folderName?: string) => void
  applyPlanWithWeeklyRest: (
    startDateKey: string,
    template: WorkoutTemplate,
    restDaysPerWeek: number,
    folderName?: string,
  ) => void
}

export function scheduledDateForPlanIndex(
  startDateKey: string,
  planIndex: number,
  restEvery: number,
): string {
  if (restEvery <= 0) return addDaysToDateKey(startDateKey, planIndex)
  return addDaysToDateKey(startDateKey, planIndex + Math.floor(planIndex / restEvery))
}

function resolveFolderPlans(
  entry: PlanCatalogEntry,
  templates: WorkoutTemplate[],
): WorkoutTemplate[] {
  if (entry.scheduleTemplateIds?.length) {
    return entry.scheduleTemplateIds
      .map((id) => templates.find((p) => p.id === id))
      .filter((p): p is WorkoutTemplate => p != null)
  }
  if (entry.folderId) {
    return sortFolderPlans(templates.filter((p) => p.folderId === entry.folderId))
  }
  return []
}

export function scheduleCatalogEntry(
  workouts: ScheduleWorkoutsApi,
  entry: PlanCatalogEntry,
  templates: WorkoutTemplate[],
  folders: TemplateFolder[],
  opts: {
    startDateKey: string
    daysPerWeek: number
    restDaysPerWeek?: number
    folderName?: string
    restEveryWorkoutDays?: number
    confirmOverwrite?: (message: string) => boolean
  },
): boolean {
  const folderName =
    opts.folderName ??
    folders.find((f) => f.id === entry.folderId)?.name ??
    entry.title

  if (entry.scheduleMode === 'repeat') {
    const template = templates.find((p) => p.id === entry.templateId)
    if (!template) return false
    const restDays = opts.restDaysPerWeek ?? Math.max(0, 7 - opts.daysPerWeek)
    workouts.applyPlanWithWeeklyRest(opts.startDateKey, template, restDays, folderName)
    return true
  }

  const plans = resolveFolderPlans(entry, templates)
  if (plans.length === 0) return false

  const restEvery = opts.restEveryWorkoutDays ?? 0
  const assignments = plans.map((plan, idx) => ({
    plan,
    dateKey: scheduledDateForPlanIndex(opts.startDateKey, idx, restEvery),
  }))

  const restDateKeys: string[] = []
  for (let i = 0; i < plans.length - 1; i++) {
    if (restEvery > 0 && (i + 1) % restEvery === 0) {
      restDateKeys.push(addDaysToDateKey(assignments[i]!.dateKey, 1))
    }
  }

  const touchedKeys = new Set<string>()
  assignments.forEach((s) => touchedKeys.add(s.dateKey))
  restDateKeys.forEach((k) => touchedKeys.add(k))

  const hasExisting = [...touchedKeys].some((key) => {
    if (workouts.isRestDay(key)) return false
    return workouts.getDay(key).length > 0
  })
  if (hasExisting && opts.confirmOverwrite) {
    const ok = opts.confirmOverwrite(
      'Some of these dates already have workouts. Continue and append these plans?',
    )
    if (!ok) return false
  }

  for (const restKey of restDateKeys) {
    if (workouts.getDay(restKey).length === 0 && !workouts.isRestDay(restKey)) {
      workouts.markRestDay(restKey)
    }
  }

  for (const slot of assignments) {
    workouts.assignPlanToDate(slot.dateKey, slot.plan, folderName)
  }

  return true
}

export function templatesForCatalogEntry(
  entry: PlanCatalogEntry,
  templates: WorkoutTemplate[],
): WorkoutTemplate[] {
  if (entry.scheduleMode === 'repeat' && entry.templateId) {
    const t = templates.find((p) => p.id === entry.templateId)
    return t ? [t] : []
  }
  return resolveFolderPlans(entry, templates)
}
