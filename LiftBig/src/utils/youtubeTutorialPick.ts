/**
 * Picks a short YouTube form tutorial for a library exercise.
 * The video must be a how-to for that exercise, under 3 minutes, and from a
 * known coaching, clinical, or equipment source.
 */

export const TUTORIAL_MAX_SECONDS = 180
export const TUTORIAL_MIN_SECONDS = 30

export type TutorialCandidate = {
  id: string
  title: string
  channel: string
  durationSeconds: number
  description?: string
}

export type TutorialExerciseQuery = {
  id: string
  name: string
  equipment?: string
}

export type RankedTutorial = {
  candidate: TutorialCandidate
  score: number
  reject?: string
}

const REPUTABLE_CHANNELS = [
  'scotthermanfitness',
  'scott herman',
  'squat university',
  'athlean-x',
  'athleanx',
  'jeff nippard',
  'renaissance periodization',
  'howcast',
  'nuffield health',
  'detroit medical',
  'cybex',
  'life fitness',
  'hammer strength',
  'fitness 19',
  'puregym',
  'anytime fitness',
  'goodlife fitness',
  'ace fitness',
  'acefitness',
  'nasm',
  'buff dudes',
  'jeremy ethier',
  'built with science',
  'e3 rehab',
  'prehab guys',
  'bob & brad',
  'bob and brad',
  'mayo clinic',
  'cleveland clinic',
  'hospital for special surgery',
  'barbell medicine',
  'alan thrall',
  'exrx',
  'muscle & strength',
  'muscle and strength',
  'bodybuilding.com',
  'mens health',
  'womens health',
  'acsm',
  'nsca',
  'calisthenicmovement',
  'fitnessfaqs',
  'hybrid calisthenics',
  'starting strength',
  'juggernaut training',
  'institute of human anatomy',
  'picturefit',
  'onnit',
  'gmb fitness',
  'hasfit',
  'medical city',
  'baptist health',
  'livestrong',
  'golds gym',
  'precision movement',
  'nhs',
]

const FORM_COACHES = [
  'scotthermanfitness',
  'scott herman',
  'squat university',
  'jeff nippard',
  'athlean-x',
  'athleanx',
  'howcast',
  'renaissance periodization',
]

const MACHINE_BRANDS = [
  'machine',
  'cybex',
  'hammer strength',
  'life fitness',
  'selectorized',
  'technogym',
  'nautilus',
  'precor',
  'matrix',
  'hoist',
]

const HOW_TO = ['how to', 'tutorial', 'instruction', 'instructions', 'demonstration', 'learn how']
const FORM_LANGUAGE = ['proper', 'properly', 'correct', 'correctly', 'form', 'technique']
const NOT_A_TUTORIAL = ['workout routine', 'follow along', 'full workout', 'compilation', 'challenge', 'playlist']

export function normalizeTutorialText(value: string): string {
  return value
    .toLowerCase()
    .replace(/['’]/g, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}

function padded(value: string): string {
  return ` ${normalizeTutorialText(value)} `
}

function hasPhrase(value: string, phrase: string): boolean {
  return padded(value).includes(` ${normalizeTutorialText(phrase)} `)
}

function hasAny(value: string, phrases: readonly string[]): boolean {
  return phrases.some((phrase) => hasPhrase(value, phrase))
}

function channelBlob(channel: string): string {
  return normalizeTutorialText(channel).replace(/ /g, '')
}

function isReputable(channel: string): boolean {
  const spaced = normalizeTutorialText(channel)
  const tight = channelBlob(channel)
  return REPUTABLE_CHANNELS.some((name) => {
    const normalized = normalizeTutorialText(name)
    return spaced.includes(normalized) || tight.includes(normalized.replace(/ /g, ''))
  })
}

function isFormCoach(channel: string): boolean {
  const spaced = normalizeTutorialText(channel)
  const tight = channelBlob(channel)
  return FORM_COACHES.some((name) => {
    const normalized = normalizeTutorialText(name)
    return spaced.includes(normalized) || tight.includes(normalized.replace(/ /g, ''))
  })
}

function isManufacturer(value: string): boolean {
  return hasAny(value, ['cybex', 'life fitness', 'hammer strength'])
}

function identityGroups(exercise: TutorialExerciseQuery): string[][] {
  const name = normalizeTutorialText(exercise.name)
  const machineNamed = hasPhrase(exercise.name, 'machine')

  if (/\bsit ?ups?\b/.test(name) || name.includes('situp')) {
    return [['sit up', 'situp', 'sit ups', 'situps']]
  }
  if (name.includes('abduct')) {
    const groups = [['hip'], ['abduct', 'abduction', 'abductor', 'abductors']]
    if (machineNamed) groups.push(MACHINE_BRANDS)
    return groups
  }
  if (name.includes('back extension') || name.includes('hyperextension')) {
    return [['back extension', 'back extensions', 'hyperextension', 'hyperextensions', 'hyper extension']]
  }
  if (name.includes('assisted') && name.includes('dip')) {
    return [['assist', 'assisted'], ['dip', 'dips']]
  }
  if ((name.includes('bicep') || name.includes('biceps')) && name.includes('curl')) {
    const groups = [['bicep', 'biceps', 'arm curl'], ['curl', 'curls', 'arm curl']]
    if (machineNamed) groups.push(MACHINE_BRANDS)
    return groups
  }
  if ((name.includes('tricep') || name.includes('triceps')) && name.includes('extension')) {
    const groups = [['tricep', 'triceps', 'arm extension'], ['extension', 'extensions', 'arm extension']]
    if (machineNamed) groups.push(MACHINE_BRANDS)
    return groups
  }
  if (name.includes('shoulder') && name.includes('press')) {
    const groups = [['press', 'presses'], ['shoulder', 'shoulders', 'overhead', 'military']]
    if (machineNamed) groups.push(MACHINE_BRANDS)
    return groups
  }

  const stop = new Set(['the', 'a', 'an', 'of', 'with', 'for', 'and', 'to', 'on'])
  const tokens = name.split(' ').filter((token) => token && !stop.has(token))
  const groups = tokens.map((token) => [token])
  if (machineNamed && !tokens.includes('machine')) groups.push(MACHINE_BRANDS)
  return groups
}

function forbiddenPhrases(exercise: TutorialExerciseQuery): string[] {
  const blob = normalizeTutorialText(`${exercise.name} ${exercise.equipment ?? ''}`)
  const bans = [
    'dumbbell',
    'dumbbells',
    'barbell',
    'kettlebell',
    'ez bar',
    'straight bar',
    'cable',
    'smith',
    'superman',
    'pushdown',
    'push down',
    'pressdown',
    'hammer curl',
    'decline',
    'incline',
    'weighted',
    'hanging',
    'side lying',
    'band',
    'bands',
  ]
  const kept = bans.filter((phrase) => !blob.includes(normalizeTutorialText(phrase)))
  if (blob.includes('abduct') && !blob.includes('adduct')) {
    kept.push('adduct', 'adduction', 'adductor', 'adductors')
  }
  if (blob.includes('machine') && !blob.includes('standing')) kept.push('standing')
  if (blob.includes('back extension')) kept.push('reverse hyper', 'good morning')
  return kept
}

function matchesIdentity(exercise: TutorialExerciseQuery, title: string, channel: string): boolean {
  const haystack = `${title} ${channel}`
  return identityGroups(exercise).every((group) => hasAny(haystack, group))
}

export function rankTutorials(
  exercise: TutorialExerciseQuery,
  candidates: readonly TutorialCandidate[],
): RankedTutorial[] {
  const ranked = candidates.map((candidate) => {
    const title = candidate.title ?? ''
    const channel = candidate.channel ?? ''
    const description = candidate.description ?? ''
    const duration = candidate.durationSeconds

    if (!Number.isFinite(duration)) {
      return { candidate, score: -1, reject: 'missing duration' }
    }
    if (duration < TUTORIAL_MIN_SECONDS) {
      return { candidate, score: -1, reject: 'too short to teach the movement' }
    }
    if (duration >= TUTORIAL_MAX_SECONDS) {
      return { candidate, score: -1, reject: '3 minutes or longer' }
    }
    if (!isReputable(channel)) {
      return { candidate, score: -1, reject: 'channel is not a recognized tutorial source' }
    }
    if (hasAny(title, NOT_A_TUTORIAL)) {
      return { candidate, score: -1, reject: 'workout or compilation, not a form tutorial' }
    }
    if (!matchesIdentity(exercise, title, channel)) {
      return { candidate, score: -1, reject: 'title is not this exercise' }
    }
    const banned = forbiddenPhrases(exercise).find((phrase) => hasPhrase(title, phrase))
    if (banned) {
      return { candidate, score: -1, reject: `different variation (${banned})` }
    }
    const tutorialText = `${title} ${description}`
    if (!hasAny(tutorialText, HOW_TO) && !hasAny(tutorialText, FORM_LANGUAGE)) {
      return { candidate, score: -1, reject: 'not a form tutorial' }
    }

    let score = 80
    if (hasAny(title, HOW_TO)) score += 40
    else if (hasAny(description, HOW_TO)) score += 20
    if (hasAny(title, FORM_LANGUAGE)) score += 15
    score += 30
    if (duration >= 60) score += 20
    else if (duration >= 45) score += 10
    if (isFormCoach(channel)) score += 15
    if (isManufacturer(`${title} ${channel}`)) score += 15

    const nameTokens = normalizeTutorialText(exercise.name)
      .split(' ')
      .filter((token) => token && !['the', 'a', 'an', 'of', 'with', 'for', 'and', 'to', 'on'].includes(token))
    for (const token of nameTokens) {
      const aliases =
        token === 'machine'
          ? MACHINE_BRANDS
          : token.startsWith('abduct')
            ? ['abduct', 'abduction', 'abductor', 'abductors']
            : token.startsWith('bicep')
              ? ['bicep', 'biceps', 'arm curl']
              : token.startsWith('tricep')
                ? ['tricep', 'triceps', 'arm extension']
                : token === 'press'
                  ? ['press', 'presses', 'overhead', 'military']
                  : [token, `${token}s`]
      if (hasAny(`${title} ${channel}`, aliases)) score += 10
    }

    return { candidate, score }
  })

  return ranked.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score
    if (b.candidate.durationSeconds !== a.candidate.durationSeconds) {
      return b.candidate.durationSeconds - a.candidate.durationSeconds
    }
    return a.candidate.id.localeCompare(b.candidate.id)
  })
}

export function pickTutorial(
  exercise: TutorialExerciseQuery,
  candidates: readonly TutorialCandidate[],
): TutorialCandidate | null {
  const best = rankTutorials(exercise, candidates).find((row) => row.score > 0)
  return best?.candidate ?? null
}

export function youtubeWatchUrl(videoId: string): string {
  return `https://www.youtube.com/watch?v=${videoId}`
}
