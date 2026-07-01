import { describe, expect, it } from 'vitest'
import { evaluateCoverage, sampleAnswerGrid } from '@/utils/planCatalogCoverage'

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
})
