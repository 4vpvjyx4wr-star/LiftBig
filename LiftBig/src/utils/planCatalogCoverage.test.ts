import { describe, expect, it } from 'vitest'
import {
  auditCatalogCoverage,
  evaluateCoverage,
  sampleAnswerGrid,
} from '@/utils/planCatalogCoverage'
import {
  CURATED_PLAN_CATALOG,
  FALLBACK_PLAN_CATALOG,
  RETROFIT_PLAN_CATALOG,
} from '@/utils/guidedPlans/guidedPlanCatalog'

const CURATED_AND_RETROFIT = [...CURATED_PLAN_CATALOG, ...RETROFIT_PLAN_CATALOG]

describe('planCatalogCoverage', () => {
  it('grid sample returns results for every combination', () => {
    const grid = sampleAnswerGrid()
    expect(grid.length).toBe(4 * 4 * 5 * 3 * 5)
    const result = evaluateCoverage(3, 60)
    expect(result.total).toBe(grid.length)
    expect(result.failures.length).toBe(0)
  })

  it('evaluateCoverage passes for the full matrix', () => {
    const { pass, failures } = evaluateCoverage(3, 60)
    expect(pass).toBe(true)
    expect(failures).toHaveLength(0)
  })

  it('curated catalog covers the matrix without generator fallbacks', () => {
    const audit = auditCatalogCoverage(CURATED_AND_RETROFIT)
    expect(audit.catalogSize).toBeGreaterThanOrEqual(45)
    expect(audit.pctAtLeast100).toBeGreaterThanOrEqual(99)
    expect(audit.pctAtLeast80).toBe(100)
    expect(audit.pctAtLeast60).toBe(100)
    expect(audit.failuresBelow80).toHaveLength(0)
    expect(audit.failuresBelow60).toHaveLength(0)
  })

  it('keeps four experience-tier fallback entries', () => {
    expect(FALLBACK_PLAN_CATALOG).toHaveLength(4)
    const tiers = new Set(FALLBACK_PLAN_CATALOG.map((e) => e.category))
    expect(tiers.size).toBe(4)
  })
})
