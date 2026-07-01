import type { PickAPlanAnswers, PlanCatalogEntry } from '@/types/planCatalog'
import type { WorkoutTemplate } from '@/types/workout'
import { GUIDED_GENERATED_FOLDER } from '@/utils/guidedPlans/guidedPlanFolders'
import {
  buildShuffledPlan,
  filterLibraryForShuffle,
  type ShuffleFocus,
} from '@/utils/planShuffle'
import { DEFAULT_PLAN_DURATION_ASSUMPTIONS } from '@/utils/planDuration'
import type { TrainingEnvironment } from '@/types/planCatalog'

const EQUIPMENT_FILTER_MAP: Record<TrainingEnvironment, string[]> = {
  commercialGym: [],
  planetFitness: [],
  homeGym: ['dumbbell', 'barbell', 'bench'],
  dumbbellsOnly: ['dumbbell'],
  minimalEquipment: ['bodyweight', 'dumbbell'],
}

const generatedTemplates = new Map<string, WorkoutTemplate>()

function targetMinutes(duration: PickAPlanAnswers['duration']): number {
  if (duration === 'quick') return 30
  if (duration === 'long') return 75
  return 55
}

function focusFromAnswers(answers: PickAPlanAnswers): ShuffleFocus[] {
  if (answers.stylePreference === 'compound') return ['push', 'pull', 'legs']
  if (answers.goal === 'strength') return ['push', 'pull', 'legs']
  return []
}

export function buildGeneratedCatalogEntry(
  answers: PickAPlanAnswers,
  template: WorkoutTemplate,
): PlanCatalogEntry {
  const mins = targetMinutes(answers.duration)
  const catalogId = `generated-${template.id}`
  generatedTemplates.set(catalogId, template)
  return {
    id: catalogId,
    title: template.name,
    description: 'Custom plan built from your answers when no preset was a perfect fit.',
    experienceLevels: answers.experienceLevel ? [answers.experienceLevel] : ['beginner', 'intermediate'],
    goals: answers.goal ? [answers.goal] : ['liftBig', 'size', 'strength'],
    days: answers.daysPerWeek ?? [3, 4],
    duration: answers.duration ?? ['quick', 'standard'],
    equipment: answers.equipment ? [answers.equipment] : ['commercialGym', 'homeGym'],
    styles: answers.stylePreference ? [answers.stylePreference] : ['balanced'],
    volumeScore: 5,
    difficulty: 'Intermediate',
    estimatedMinutes: mins,
    primaryMuscles: ['Full body'],
    progressionStyle: 'Auto-generated progression',
    goalTag: 'Custom match',
    scheduleMode: 'repeat',
    templateId: template.id,
    category: answers.experienceLevel ?? 'intermediate',
  }
}

export function getGeneratedTemplate(catalogId: string): WorkoutTemplate | undefined {
  return generatedTemplates.get(catalogId)
}

export function persistGeneratedTemplate(
  template: WorkoutTemplate,
  existing: WorkoutTemplate[],
  setAll: (next: WorkoutTemplate[]) => void,
): void {
  if (existing.some((t) => t.id === template.id)) return
  setAll([template, ...existing])
}

export function generateFallbackPlan(answers: PickAPlanAnswers): WorkoutTemplate | null {
  const equipment = answers.equipment ? EQUIPMENT_FILTER_MAP[answers.equipment] : []
  const pool = filterLibraryForShuffle(equipment, focusFromAnswers(answers), answers.goal === 'weightLoss')
  if (pool.length < 4) return null

  const plan = buildShuffledPlan({
    selectedEquipment: equipment,
    selectedFocus: focusFromAnswers(answers),
    includeCardio: answers.goal === 'weightLoss',
    mode: 'duration',
    targetMinutes: targetMinutes(answers.duration),
    exerciseCount: 6,
    durationAssumptions: DEFAULT_PLAN_DURATION_ASSUMPTIONS,
  })

  const template: WorkoutTemplate = {
    ...plan,
    id: `generated-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
    name: 'Your Custom Plan',
    folderId: GUIDED_GENERATED_FOLDER.id,
    notes: 'Generated from your Pick a Plan answers.',
  }
  return template
}

export function generateFallbackRecommendations(
  answers: PickAPlanAnswers,
  count = 3,
): PlanCatalogEntry[] {
  const entries: PlanCatalogEntry[] = []
  for (let i = 0; i < count; i++) {
    const template = generateFallbackPlan(answers)
    if (!template) break
    template.id = `generated-${Date.now()}-${i}`
    template.name = i === 0 ? 'Your Custom Plan' : `Custom Option ${i + 1}`
    entries.push(buildGeneratedCatalogEntry(answers, template))
  }
  return entries
}
