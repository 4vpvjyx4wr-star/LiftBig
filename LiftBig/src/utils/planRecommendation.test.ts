import { describe, expect, it } from 'vitest'
import type { PickAPlanAnswers } from '@/types/planCatalog'
import {
  BADGE_LABELS,
  buildMotivationalHeadline,
  recommendPlans,
  scoreCatalogEntry,
  buildMatchReasons,
} from '@/utils/planRecommendation'
import { recommendPlansRaw } from '@/utils/planRecommendationCore'
import { ALL_PLAN_CATALOG } from '@/utils/guidedPlans/guidedPlanCatalog'

describe('planRecommendation', () => {
  const fullAnswers: PickAPlanAnswers = {
    experienceLevel: 'beginner',
    goal: 'size',
    daysPerWeek: 3,
    duration: 'standard',
    equipment: 'commercialGym',
    stylePreference: 'balanced',
  }

  const beginnerEntry =
    ALL_PLAN_CATALOG.find((e) => e.id === 'catalog-beginner-full-body-3d')!

  it('scores experience match at +50', () => {
    const score = scoreCatalogEntry(beginnerEntry, fullAnswers)
    const reasons = buildMatchReasons(beginnerEntry, fullAnswers)
    expect(score).toBeGreaterThanOrEqual(50)
    expect(reasons).toContain('Beginner')
  })

  it('scores goal match at +40', () => {
    const score = scoreCatalogEntry(beginnerEntry, { ...fullAnswers, experienceLevel: null })
    expect(score).toBeGreaterThanOrEqual(40)
  })

  it('gives partial credit for near-miss days', () => {
    const exact = scoreCatalogEntry(beginnerEntry, { ...fullAnswers, daysPerWeek: 3 })
    const near = scoreCatalogEntry(beginnerEntry, { ...fullAnswers, daysPerWeek: 5 })
    expect(exact).toBeGreaterThan(near)
    expect(near).toBeGreaterThan(0)
  })

  it('returns three diverse recommendations', () => {
    const recs = recommendPlans(fullAnswers)
    expect(recs).toHaveLength(3)
    expect(recs[0]!.badge).toBe('bestMatch')
    expect(recs[1]!.badge).toBe('greatAlternative')
    expect(recs[2]!.badge).toBe('somethingDifferent')
    const ids = new Set(recs.map((r) => r.entry.id))
    expect(ids.size).toBe(3)
  })

  it('includes match reasons on results', () => {
    const recs = recommendPlans(fullAnswers)
    expect(recs[0]!.matchReasons.length).toBeGreaterThan(0)
  })

  it('builds motivational headline from answers', () => {
    const text = buildMotivationalHeadline(fullAnswers)
    expect(text).toContain('build muscle')
    expect(text).toContain('3 days/week')
  })

  it('exposes badge labels', () => {
    expect(BADGE_LABELS.bestMatch).toBe('Best Match')
  })

  it('gives an apartment beginner an apartment plan', () => {
    const recs = recommendPlansRaw({
      experienceLevel: 'beginner',
      goal: 'size',
      daysPerWeek: 3,
      duration: 'standard',
      equipment: 'apartmentGym',
      stylePreference: 'balanced',
    })
    expect(recs.length).toBeGreaterThan(0)
    expect(recs.every((rec) => rec.entry.equipment.includes('apartmentGym'))).toBe(true)
    expect(recs[0]!.entry.experienceLevels).toContain('beginner')
    expect(new Set(recs.map((rec) => rec.entry.id)).size).toBe(recs.length)
  })

  it('gives a commercial beginner a beginner full-gym plan', () => {
    const recs = recommendPlansRaw({
      experienceLevel: 'beginner',
      goal: 'strength',
      daysPerWeek: 3,
      duration: 'standard',
      equipment: 'commercialGym',
      stylePreference: 'balanced',
    })
    const top = recs[0]!.entry
    expect(top.category).toBe('beginner')
    expect(top.experienceLevels).toContain('beginner')
    expect(top.equipment).toContain('commercialGym')
    expect(top.equipment).not.toContain('apartmentGym')
    expect(recs.every((rec) => rec.entry.equipment.includes('commercialGym'))).toBe(true)
  })

  it('does not give a 2-day dumbbell beginner a 6-day barbell split', () => {
    const recs = recommendPlansRaw({
      experienceLevel: 'beginner',
      goal: 'strength',
      daysPerWeek: 2,
      duration: 'quick',
      equipment: 'dumbbellsOnly',
      stylePreference: 'minimalist',
    })
    expect(recs.length).toBeGreaterThan(0)
    for (const rec of recs) {
      expect(rec.entry.equipment).toContain('dumbbellsOnly')
      const days = Array.isArray(rec.entry.days) ? rec.entry.days : [rec.entry.days]
      expect(days.some((day) => day >= 6)).toBe(false)
    }
  })

  it('does not give an experienced strength lifter a beginner starter', () => {
    const recs = recommendPlansRaw({
      experienceLevel: 'experienced',
      goal: 'strength',
      daysPerWeek: 4,
      duration: 'standard',
      equipment: 'commercialGym',
      stylePreference: 'compound',
    })
    expect(recs[0]!.entry.experienceLevels).toContain('experienced')
    expect(recs.some((rec) => rec.entry.id === 'catalog-planet-fitness-starter')).toBe(false)
    expect(
      recs.some(
        (rec) => rec.entry.category === 'beginner' && !rec.entry.experienceLevels.includes('experienced'),
      ),
    ).toBe(false)
  })
})
