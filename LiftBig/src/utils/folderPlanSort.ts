import type { WorkoutTemplate } from '@/types/workout'

const WEEKDAY_ORDER: Record<string, number> = {
  monday: 1,
  tuesday: 2,
  wednesday: 3,
  thursday: 4,
  friday: 5,
  saturday: 6,
  sunday: 7,
}

/** Sort key for plans inside a folder: week → day (numeric or weekday) → name. */
export function folderPlanSortKey(name: string): [number, number, string] {
  const weekMatch = /week\s+(\d+)/i.exec(name)
  const dayMatch = /day\s+(\d+)/i.exec(name)
  const weekdayMatch = /^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b/i.exec(name.trim())

  const week = weekMatch ? Number.parseInt(weekMatch[1]!, 10) : Number.MAX_SAFE_INTEGER

  if (dayMatch) {
    return [week, Number.parseInt(dayMatch[1]!, 10), name.toLowerCase()]
  }

  if (weekdayMatch) {
    const day = WEEKDAY_ORDER[weekdayMatch[1]!.toLowerCase()] ?? Number.MAX_SAFE_INTEGER
    return [week, day, name.toLowerCase()]
  }

  return [week, Number.MAX_SAFE_INTEGER, name.toLowerCase()]
}

export function sortFolderPlans(plans: WorkoutTemplate[]): WorkoutTemplate[] {
  return plans.slice().sort((a, b) => {
    const [aw, ad, an] = folderPlanSortKey(a.name)
    const [bw, bd, bn] = folderPlanSortKey(b.name)
    if (aw !== bw) return aw - bw
    if (ad !== bd) return ad - bd
    return an.localeCompare(bn)
  })
}

/** Reorder stored templates so seeded folder plans follow the seed list order. */
export function reorderSeededFolderPlans(
  templates: WorkoutTemplate[],
  folderId: string,
  seedOrder: WorkoutTemplate[],
): WorkoutTemplate[] {
  const seedIds = seedOrder.map((plan) => plan.id)
  const folderIndices: number[] = []
  templates.forEach((template, index) => {
    if (template.folderId === folderId) folderIndices.push(index)
  })
  if (folderIndices.length === 0) return templates

  const ordered: WorkoutTemplate[] = []
  const seen = new Set<string>()
  for (const id of seedIds) {
    const match = templates.find((template) => template.id === id)
    if (match) {
      ordered.push(match)
      seen.add(id)
    }
  }
  for (const index of folderIndices) {
    const template = templates[index]!
    if (!seen.has(template.id)) ordered.push(template)
  }

  const next = [...templates]
  folderIndices.forEach((index, position) => {
    next[index] = ordered[position]!
  })
  return next
}
