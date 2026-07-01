import type { ExperienceLevel, PickAPlanAnswers, TrainingGoal, WorkoutDuration } from '@/types/planCatalog'
import { recommendPlansRaw, topRecommendationScore as coreTopScore } from '@/utils/planRecommendationCore'
import { generateFallbackRecommendations } from '@/utils/guidedPlanGenerator'
import { ALL_PLAN_CATALOG } from '@/utils/guidedPlans/guidedPlanCatalog'

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
