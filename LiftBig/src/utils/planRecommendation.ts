import type { PickAPlanAnswers, PlanRecommendation, RecommendationBadge } from '@/types/planCatalog'
import { getRecommendationsWithFallbacks } from '@/utils/planCatalogCoverage'

export const BADGE_LABELS: Record<RecommendationBadge, string> = {
  bestMatch: 'Best Match',
  greatAlternative: 'Great Alternative',
  somethingDifferent: 'Something Different',
}

export {
  scoreCatalogEntry,
  buildMatchReasons,
  motivationalIntro as buildMotivationalHeadline,
  matchBecauseCopy,
  topRecommendationScore,
} from '@/utils/planRecommendationCore'

export function recommendPlans(answers: PickAPlanAnswers): PlanRecommendation[] {
  const raw = getRecommendationsWithFallbacks(answers)
  const badges: RecommendationBadge[] = ['bestMatch', 'greatAlternative', 'somethingDifferent']
  return raw.map((rec, idx) => ({
    ...rec,
    badge: badges[idx] ?? 'somethingDifferent',
  }))
}
