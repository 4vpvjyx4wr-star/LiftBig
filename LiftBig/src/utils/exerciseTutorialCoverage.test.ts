import { describe, expect, it } from 'vitest'
import { EXERCISE_LIBRARY } from '@/utils/exerciseLibrary'

const FORM_TUTORIALS: Record<string, string> = {
  'machine-shoulder-press': 'https://www.youtube.com/watch?v=oAadscMCGLU',
  'back-extension': 'https://www.youtube.com/watch?v=WnsnESPx4JE',
  'assisted-dip': 'https://www.youtube.com/watch?v=8zFcJWD9Y_E',
  'machine-bicep-curl': 'https://www.youtube.com/watch?v=M_uPvGrMx_o',
  'machine-triceps-extension': 'https://www.youtube.com/watch?v=S_evjJzI4hA',
  'hip-abductor-machine': 'https://www.youtube.com/watch?v=2b97cvyH9sE',
  'sit-up': 'https://www.youtube.com/watch?v=jDwoBqPH0jk',
}

describe('library exercise tutorials', () => {
  it('attaches a YouTube tutorial and coaching text to every gym exercise', () => {
    const gaps = EXERCISE_LIBRARY.filter((exercise) => exercise.isCardio !== true).flatMap(
      (exercise) => {
        const missing: string[] = []
        if (!exercise.tutorialUrl?.includes('youtube.com') && !exercise.tutorialUrl?.includes('youtu.be')) {
          missing.push('tutorial')
        }
        if (!exercise.instructions?.length) missing.push('instructions')
        if (!exercise.cues?.length) missing.push('cues')
        if (!exercise.tips?.length) missing.push('tips')
        return missing.length ? [`${exercise.id}: ${missing.join(', ')}`] : []
      },
    )
    expect(gaps).toEqual([])
  })

  it('keeps the form tutorials for the machine and bodyweight exercises that were missing them', () => {
    for (const [id, url] of Object.entries(FORM_TUTORIALS)) {
      const exercise = EXERCISE_LIBRARY.find((entry) => entry.id === id)
      expect(exercise?.tutorialUrl, id).toBe(url)
      expect(exercise?.instructions?.length, id).toBeGreaterThan(0)
      expect(exercise?.cues?.length, id).toBeGreaterThan(0)
      expect(exercise?.tips?.length, id).toBeGreaterThan(0)
    }
  })

  it('keeps cardio tutorial urls on the library list', () => {
    const walking = EXERCISE_LIBRARY.find((exercise) => exercise.id === 'walking')
    expect(walking?.tutorialUrl).toBe('https://www.youtube.com/watch?v=Lv1JkGshe9w')
  })
})
