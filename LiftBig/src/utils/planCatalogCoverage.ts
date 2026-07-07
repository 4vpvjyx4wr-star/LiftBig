import type { ExperienceLevel, PickAPlanAnswers, TrainingGoal, WorkoutDuration } from '@/types/planCatalog'
import {
  recommendPlansRaw,
  scoreCatalogEntry,
  topRecommendationScore as coreTopScore,
} from '@/utils/planRecommendationCore'
import { generateFallbackRecommendations } from '@/utils/guidedPlanGenerator'
import {
  ALL_PLAN_CATALOG,
  CURATED_PLAN_CATALOG,
  RETROFIT_PLAN_CATALOG,
} from '@/utils/guidedPlans/guidedPlanCatalog'
import type { PlanCatalogEntry } from '@/types/planCatalog'

const EXPERIENCE_LEVELS: ExperienceLevel[] = ['beginner', 'intermediate', 'experienced', 'liftaholic']
const GOALS: TrainingGoal[] = ['strength', 'size', 'weightLoss', 'liftBig']
const DAY_BUCKETS = [2, 3, 4, 5, 6]
const DURATIONS: WorkoutDuration[] = ['quick', 'standard', 'long']
const EQUIPMENT = [
  'commercialGym',
  'planetFitness',
  'homeGym',
  'dumbbellsOnly',
  'minimalEquipment',
] as const

export type CoverageSample = {
  answers: PickAPlanAnswers
  resultCount: number
  topScore: number
}

export function sampleAnswerGrid(): PickAPlanAnswers[] {
  const samples: PickAPlanAnswers[] = []
  for (const experienceLevel of EXPERIENCE_LEVELS) {
    for (const goal of GOALS) {
      for (const daysPerWeek of DAY_BUCKETS) {
        for (const duration of DURATIONS) {
          for (const equipment of EQUIPMENT) {
            samples.push({
              experienceLevel,
              goal,
              daysPerWeek,
              duration,
              equipment,
              stylePreference: 'balanced',
            })
          }
        }
      }
    }
  }
  return samples
}

export function evaluateCoverage(
  minResults = 3,
  minScore = 60,
): { pass: boolean; failures: CoverageSample[]; total: number } {
  const failures: CoverageSample[] = []
  const samples = sampleAnswerGrid()

  for (const answers of samples) {
    let recs = recommendPlansRaw(answers, ALL_PLAN_CATALOG)
    if (recs.length < minResults || (recs[0]?.score ?? 0) < 80) {
      const fallbacks = generateFallbackRecommendations(answers, minResults - recs.length)
      if (fallbacks.length > 0) {
        recs = [
          ...recs,
          ...fallbacks.map((entry, i) => ({
            entry,
            score: 70 - i,
            matchReasons: ['Generated for your profile'],
          })),
        ].slice(0, minResults)
      }
    }

    const topScore = recs[0]?.score ?? 0
    if (recs.length < minResults || topScore < minScore) {
      failures.push({ answers, resultCount: recs.length, topScore })
    }
  }

  return { pass: failures.length === 0, failures, total: samples.length }
}

export type CoverageAudit = {
  total: number
  catalogSize: number
  pctAtLeast100: number
  pctAtLeast80: number
  pctAtLeast60: number
  failuresBelow80: CoverageSample[]
  failuresBelow60: CoverageSample[]
  dimensionFailCounts: {
    experienceLevel: Record<string, number>
    goal: Record<string, number>
    daysPerWeek: Record<string, number>
    duration: Record<string, number>
    equipment: Record<string, number>
  }
}

function incCount(map: Record<string, number>, key: string | number) {
  const k = String(key)
  map[k] = (map[k] ?? 0) + 1
}

/** Score grid samples against a catalog slice without generator fallbacks. */
export function auditCatalogCoverage(
  catalog: PlanCatalogEntry[] = [...CURATED_PLAN_CATALOG, ...RETROFIT_PLAN_CATALOG],
): CoverageAudit {
  const samples = sampleAnswerGrid()
  const failuresBelow80: CoverageSample[] = []
  const failuresBelow60: CoverageSample[] = []
  const dimensionFailCounts = {
    experienceLevel: {} as Record<string, number>,
    goal: {} as Record<string, number>,
    daysPerWeek: {} as Record<string, number>,
    duration: {} as Record<string, number>,
    equipment: {} as Record<string, number>,
  }
  let atLeast100 = 0
  let atLeast80 = 0
  let atLeast60 = 0

  for (const answers of samples) {
    const scored = catalog
      .map((entry) => ({ entry, score: scoreCatalogEntry(entry, answers) }))
      .sort((a, b) => b.score - a.score)
    const topScore = scored[0]?.score ?? 0

    if (topScore >= 100) atLeast100++
    if (topScore >= 80) atLeast80++
    if (topScore >= 60) atLeast60++

    if (topScore < 80) {
      failuresBelow80.push({ answers, resultCount: scored.length, topScore })
      incCount(dimensionFailCounts.experienceLevel, answers.experienceLevel!)
      incCount(dimensionFailCounts.goal, answers.goal!)
      incCount(dimensionFailCounts.daysPerWeek, answers.daysPerWeek!)
      incCount(dimensionFailCounts.duration, answers.duration!)
      incCount(dimensionFailCounts.equipment, answers.equipment!)
    }
    if (topScore < 60) {
      failuresBelow60.push({ answers, resultCount: scored.length, topScore })
    }
  }

  const total = samples.length
  return {
    total,
    catalogSize: catalog.length,
    pctAtLeast100: (atLeast100 / total) * 100,
    pctAtLeast80: (atLeast80 / total) * 100,
    pctAtLeast60: (atLeast60 / total) * 100,
    failuresBelow80,
    failuresBelow60,
    dimensionFailCounts,
  }
}

export function getRecommendationsWithFallbacks(answers: PickAPlanAnswers) {
  let recs = recommendPlansRaw(answers)
  if (recs.length < 3 || coreTopScore(answers) < 80) {
    const generated = generateFallbackRecommendations(answers, 3 - recs.length)
    for (const entry of generated) {
      recs.push({
        entry,
        score: 65,
        matchReasons: ['Built from your equipment and goals'],
      })
    }
    recs = recs.slice(0, 3)
  }
  return recs
}
